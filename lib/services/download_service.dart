import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';
import '../models/catalog_book.dart';
import 'epub_service.dart';
import 'storage_service.dart';

/// Manages streaming EPUB file downloads, validation, metadata extraction,
/// content-addressed storage, and library catalog insertion.
class DownloadService {
  static DownloadService? _instance;
  static DownloadService get instance => _instance ??= DownloadService._();

  final Dio _dio;
  final Map<String, CancelToken> _cancelTokens = {};
  final ValueNotifier<Map<String, double>> downloadProgressNotifier =
      ValueNotifier<Map<String, double>>({});

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
            );

  @visibleForTesting
  DownloadService.withDio(Dio dio) : _dio = dio;

  bool isDownloading(String bookId) =>
      downloadProgressNotifier.value.containsKey(bookId);

  double? getProgress(String bookId) =>
      downloadProgressNotifier.value[bookId];

  void cancelDownload(String bookId) {
    final token = _cancelTokens.remove(bookId);
    token?.cancel('User cancelled download');
    _updateProgress(bookId, null);
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

  /// Downloads an EPUB from [book.downloadUrl], validates its ZIP structure,
  /// parses its metadata/cover, writes it to the internal library directory,
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

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
      '${tempDir.path}/download_${DateTime.now().millisecondsSinceEpoch}.epub',
    );

    try {
      await _dio.download(
        downloadUrl,
        tempFile.path,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final fraction = (received / total).clamp(0.0, 1.0);
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

      // Save permanently into internal books directory: <hash>.epub
      final booksDir = await storageService.booksDirectory;
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
      return persistedBook;
    } catch (e) {
      try {
        if (tempFile.existsSync()) await tempFile.delete();
      } catch (_) {}
      rethrow;
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
