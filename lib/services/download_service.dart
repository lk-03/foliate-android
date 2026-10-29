import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';
import '../models/catalog_book.dart';
import '../models/download_task.dart';
import 'epub_service.dart';
import 'storage_service.dart';

/// Manages streaming EPUB file downloads, validation, metadata extraction,
/// content-addressed storage, library catalog insertion, and persistent download tasks.
class DownloadService {
  static DownloadService? _instance;
  static DownloadService get instance => _instance ??= DownloadService._();

  final Dio _dio;
  final Map<String, CancelToken> _cancelTokens = {};
  final ValueNotifier<Map<String, double>> downloadProgressNotifier =
      ValueNotifier<Map<String, double>>({});
  final ValueNotifier<List<DownloadTask>> tasksNotifier =
      ValueNotifier<List<DownloadTask>>([]);
  bool _initialized = false;

  DownloadService._({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 25),
                receiveTimeout: const Duration(minutes: 5),
                headers: {
                  'User-Agent':
                      'Foliate/1.0.0 (Android; +https://github.com/lk-03/foliate-android)',
                },
                followRedirects: true,
                maxRedirects: 6,
              ),
            ) {
    _loadStoredTasks();
  }

  @visibleForTesting
  DownloadService.withDio(Dio dio) : _dio = dio {
    _loadStoredTasks();
  }

  Future<void> _loadStoredTasks() async {
    if (_initialized) return;
    try {
      final stored = await StorageService.instance.getDownloadTasks();
      // Reset any tasks that were marked downloading when the app previously terminated
      final normalized = stored.map((t) {
        if (t.status == DownloadStatus.downloading ||
            t.status == DownloadStatus.queued) {
          return t.copyWith(status: DownloadStatus.paused);
        }
        return t;
      }).toList();
      tasksNotifier.value = normalized;
      _initialized = true;
    } catch (_) {}
  }

  bool isDownloading(String bookId) =>
      downloadProgressNotifier.value.containsKey(bookId);

  double? getProgress(String bookId) =>
      downloadProgressNotifier.value[bookId];

  int get activeDownloadsCount =>
      tasksNotifier.value.where((t) => t.isActive).length;

  double get totalActiveProgress {
    final active = tasksNotifier.value.where((t) => t.isActive).toList();
    if (active.isEmpty) return 0.0;
    final total = active.fold<double>(0.0, (acc, t) => acc + t.progress);
    return (total / active.length).clamp(0.0, 1.0);
  }

  DownloadTask? getTask(String id) =>
      tasksNotifier.value.where((t) => t.id == id).firstOrNull;

  void cancelDownload(String bookId) {
    final token = _cancelTokens.remove(bookId);
    token?.cancel('User cancelled download');
    _updateProgress(bookId, null);
    _updateTaskStatus(bookId, DownloadStatus.cancelled);
  }

  void pauseDownload(String bookId) {
    final token = _cancelTokens.remove(bookId);
    token?.cancel('User paused download');
    _updateProgress(bookId, null);
    _updateTaskStatus(bookId, DownloadStatus.paused);
  }

  Future<void> resumeDownload(String bookId) async {
    final task = getTask(bookId);
    if (task == null) return;
    final catalogBook = CatalogBook(
      id: task.id,
      title: task.title,
      author: task.author,
      summary: '',
      downloadUrl: task.downloadUrl,
      coverUrl: task.coverUrl,
    );
    await downloadAndImportBook(book: catalogBook);
  }

  Future<void> retryDownload(String bookId) async {
    await resumeDownload(bookId);
  }

  Future<void> clearCompletedTasks() async {
    await StorageService.instance.clearFinishedDownloadTasks();
    tasksNotifier.value =
        tasksNotifier.value.where((t) => !t.isTerminal).toList();
  }

  Future<void> removeTask(String bookId) async {
    cancelDownload(bookId);
    await StorageService.instance.removeDownloadTask(bookId);
    tasksNotifier.value =
        tasksNotifier.value.where((t) => t.id != bookId).toList();
  }

  void _updateProgress(String bookId, double? progress) {
    final current = Map<String, double>.from(downloadProgressNotifier.value);
    if (progress == null) {
      current.remove(bookId);
    } else {
      current[bookId] = progress;
    }
    downloadProgressNotifier.value = current;
  }

  void _updateTaskStatus(String bookId, DownloadStatus status, {String? error}) {
    final currentList = List<DownloadTask>.from(tasksNotifier.value);
    final idx = currentList.indexWhere((t) => t.id == bookId);
    if (idx >= 0) {
      final updated = currentList[idx].copyWith(
        status: status,
        speedBytesPerSecond: 0.0,
        error: error,
      );
      currentList[idx] = updated;
      tasksNotifier.value = currentList;
      StorageService.instance.saveDownloadTask(updated);
    }
  }

  void _upsertTask(DownloadTask task) {
    final currentList = List<DownloadTask>.from(tasksNotifier.value);
    final idx = currentList.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      currentList[idx] = task;
    } else {
      currentList.insert(0, task);
    }
    tasksNotifier.value = currentList;
    StorageService.instance.saveDownloadTask(task);
  }

  /// Downloads an EPUB from [book.downloadUrl], validates its ZIP structure,
  /// parses its metadata/cover, writes it to the user's library directory,
  /// and persists it in [StorageService].
  Future<Book> downloadAndImportBook({
    required CatalogBook book,
    void Function(double progress)? onProgress,
  }) async {
    final downloadUrl = book.downloadUrl;
    if (downloadUrl == null || downloadUrl.isEmpty) {
      throw Exception('Book has no download URL');
    }

    final bookId = book.id;
    final cancelToken = CancelToken();
    _cancelTokens[bookId] = cancelToken;
    _updateProgress(bookId, 0.0);

    var existingTask = getTask(bookId);
    var currentTask = existingTask?.copyWith(
          status: DownloadStatus.downloading,
          downloadUrl: downloadUrl,
          startedAt: DateTime.now().millisecondsSinceEpoch,
          error: null,
        ) ??
        DownloadTask(
          id: bookId,
          title: book.title,
          author: book.author,
          coverUrl: book.coverUrl,
          downloadUrl: downloadUrl,
          status: DownloadStatus.downloading,
          startedAt: DateTime.now().millisecondsSinceEpoch,
        );
    _upsertTask(currentTask);

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
      '${tempDir.path}/download_${DateTime.now().millisecondsSinceEpoch}.epub',
    );

    int lastReceived = 0;
    int lastTimestamp = DateTime.now().millisecondsSinceEpoch;

    try {
      await _dio.download(
        downloadUrl,
        tempFile.path,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final fraction = (received / total).clamp(0.0, 1.0);
            final now = DateTime.now().millisecondsSinceEpoch;
            final elapsedMs = now - lastTimestamp;
            double speed = currentTask.speedBytesPerSecond;
            if (elapsedMs > 500) {
              final bytesDelta = received - lastReceived;
              speed = (bytesDelta / (elapsedMs / 1000.0)).clamp(0.0, 50000000.0);
              lastReceived = received;
              lastTimestamp = now;
            }

            currentTask = currentTask.copyWith(
              progress: fraction,
              downloadedBytes: received,
              fileSizeBytes: total,
              speedBytesPerSecond: speed,
              status: DownloadStatus.downloading,
            );
            _upsertTask(currentTask);
            _updateProgress(bookId, fraction);
            onProgress?.call(fraction);
          }
        },
      );

      final bytes = await tempFile.readAsBytes();
      if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
        throw Exception(
          'Downloaded file is not a valid EPUB/ZIP archive (corrupted or error page returned).',
        );
      }

      final storageService = StorageService.instance;
      final coversDir = await storageService.coversDirectory;

      // Parse metadata and extract cover image
      final parsedBook = await EpubService.parseEpubBytes(
        bytes: bytes,
        sourceFilePath: tempFile.path,
        coversDir: coversDir,
      );

      // Save permanently into effective books directory (custom folder or default)
      final booksDir = await storageService.getEffectiveBooksDirectory();
      final permanentFile = File('${booksDir.path}/${parsedBook.hash}.epub');
      await permanentFile.writeAsBytes(bytes);

      // Clean up temporary file
      try {
        if (tempFile.existsSync()) await tempFile.delete();
      } catch (_) {}

      // Preserve fallback title and author if EPUB Dublin Core was missing/generic
      final finalTitle = parsedBook.title.isNotEmpty &&
              parsedBook.title != 'Unknown Title'
          ? parsedBook.title
          : book.title;

      final finalAuthor = parsedBook.author.isNotEmpty &&
              parsedBook.author != 'Unknown Author'
          ? parsedBook.author
          : book.author;

      final persistedBook = parsedBook.copyWith(
        title: finalTitle,
        author: finalAuthor,
        filePath: permanentFile.path,
      );

      await storageService.saveBook(persistedBook);

      // Mark task as completed
      currentTask = currentTask.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
        downloadedBytes: bytes.length,
        fileSizeBytes: bytes.length,
        completedAt: DateTime.now().millisecondsSinceEpoch,
        localFilePath: permanentFile.path,
        speedBytesPerSecond: 0.0,
      );
      _upsertTask(currentTask);

      return persistedBook;
    } catch (e) {
      try {
        if (tempFile.existsSync()) await tempFile.delete();
      } catch (_) {}
      if (cancelToken.isCancelled) {
        _updateTaskStatus(bookId, DownloadStatus.cancelled);
        throw Exception('Download cancelled by user');
      } else {
        String friendlyError = e.toString().replaceFirst('Exception: ', '');
        if (e is DioException) {
          final code = e.response?.statusCode;
          if (code == 401 || code == 403) {
            friendlyError =
                'This title requires borrowing or is not available for public download (HTTP $code).';
          } else if (code == 404) {
            friendlyError =
                'The EPUB file for this edition was not found on the server (HTTP 404).';
          } else if (e.message != null && e.message!.isNotEmpty) {
            friendlyError = e.message!;
          }
        }
        _updateTaskStatus(
          bookId,
          DownloadStatus.failed,
          error: friendlyError,
        );
        throw Exception(friendlyError);
      }
    } finally {
      _cancelTokens.remove(bookId);
      _updateProgress(bookId, null);
    }
  }

  /// Checks if a book with the given title and author already exists in the local library.
  Future<Book?> findExistingBook({
    required String title,
    required String author,
  }) async {
    final books = await StorageService.instance.getBooks();
    final cleanTitle = title.trim().toLowerCase();
    final cleanAuthor = author.trim().toLowerCase();

    for (final b in books) {
      if (b.title.trim().toLowerCase() == cleanTitle) {
        if (cleanAuthor.isEmpty ||
            b.author.trim().toLowerCase() == cleanAuthor ||
            b.author.toLowerCase().contains(cleanAuthor) ||
            cleanAuthor.contains(b.author.toLowerCase())) {
          return b;
        }
      }
    }
    return null;
  }
}
