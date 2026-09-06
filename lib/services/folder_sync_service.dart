import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/book.dart';
import 'epub_service.dart';
import 'storage_service.dart';

class ImportProgress {
  final int current;
  final int total;
  final String currentTitle;
  final int importedCount;
  final int skippedCount;
  final bool isDone;

  const ImportProgress({
    required this.current,
    required this.total,
    required this.currentTitle,
    this.importedCount = 0,
    this.skippedCount = 0,
    this.isDone = false,
  });
}

/// Service handling single file selection, folder linking, batch import,
/// and auto-sync of watched folders on startup/pull-to-refresh.
class FolderSyncService {
  static FolderSyncService? _instance;
  static FolderSyncService get instance => _instance ??= FolderSyncService._();

  FolderSyncService._();

  final StorageService _storage = StorageService.instance;

  /// Lets the user pick one or more EPUB files from their device.
  Future<List<Book>> pickAndImportFiles({
    void Function(ImportProgress)? onProgress,
  }) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );

    if (result.isEmpty) return [];

    final files = result
        .map((p) => p.path)
        .whereType<String>()
        .map((p) => File(p))
        .where((f) => f.existsSync())
        .toList();

    return _processEpubFiles(files, onProgress: onProgress, copyToInternalStorage: true);
  }

  /// Prompts user to pick a directory, saves it as a linked folder, and imports its books.
  Future<List<Book>> pickAndLinkFolder({
    void Function(ImportProgress)? onProgress,
  }) async {
    final directoryPath = await FilePicker.getDirectoryPath();
    if (directoryPath == null || directoryPath.isEmpty) return [];

    await _storage.addLinkedFolder(directoryPath);
    return scanLinkedFolder(directoryPath, onProgress: onProgress);
  }

  /// Scans a single linked folder for all EPUB files and imports any not yet in library.
  Future<List<Book>> scanLinkedFolder(
    String folderPath, {
    void Function(ImportProgress)? onProgress,
  }) async {
    final dir = Directory(folderPath);
    if (!dir.existsSync()) {
      debugPrint('[FolderSync] Directory does not exist or inaccessible: $folderPath');
      return [];
    }

    final epubFiles = <File>[];
    try {
      final entities = dir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is File && entity.path.toLowerCase().endsWith('.epub')) {
          epubFiles.add(entity);
        }
      }
      debugPrint('[FolderSync] Found ${epubFiles.length} EPUB file(s) in $folderPath');
    } catch (e) {
      debugPrint('[FolderSync] Failed to list $folderPath: $e');
      return [];
    }

    return _processEpubFiles(epubFiles, onProgress: onProgress, copyToInternalStorage: false);
  }

  /// Scans all registered linked folders (used on startup & pull-to-refresh).
  Future<List<Book>> scanAllLinkedFolders({
    void Function(ImportProgress)? onProgress,
  }) async {
    final folders = await _storage.getLinkedFolders();
    final newlyImported = <Book>[];

    for (final folder in folders) {
      final imported = await scanLinkedFolder(folder, onProgress: onProgress);
      newlyImported.addAll(imported);
    }

    return newlyImported;
  }

  /// Common pipeline to process a list of EPUB files, deduplicate by SHA-256,
  /// extract metadata/covers, and save to storage.
  Future<List<Book>> _processEpubFiles(
    List<File> files, {
    void Function(ImportProgress)? onProgress,
    required bool copyToInternalStorage,
  }) async {
    if (files.isEmpty) return [];

    final existingBooks = await _storage.getBooks();
    final existingHashes = existingBooks.map((b) => b.hash).toSet();

    final booksDir = await _storage.booksDirectory;
    final coversDir = await _storage.coversDirectory;

    final newlyAdded = <Book>[];
    int importedCount = 0;
    int skippedCount = 0;

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName = file.path.split(Platform.pathSeparator).last;

      onProgress?.call(ImportProgress(
        current: i + 1,
        total: files.length,
        currentTitle: fileName,
        importedCount: importedCount,
        skippedCount: skippedCount,
        isDone: false,
      ));

      try {
        final bytes = await file.readAsBytes();
        final hash = EpubService.computeHash(bytes);

        // Deduplication check
        if (existingHashes.contains(hash)) {
          skippedCount++;
          continue;
        }

        String targetPath = file.path;
        if (copyToInternalStorage) {
          final internalFile = File('${booksDir.path}/$hash.epub');
          if (!internalFile.existsSync()) {
            await internalFile.writeAsBytes(bytes);
          }
          targetPath = internalFile.path;
        }

        final book = await EpubService.parseEpubBytes(
          bytes: bytes,
          sourceFilePath: targetPath,
          coversDir: coversDir,
        );

        await _storage.saveBook(book);
        existingHashes.add(hash);
        newlyAdded.add(book);
        importedCount++;
      } catch (e) {
        debugPrint('[FolderSync] Failed to process ${file.path}: $e');
        skippedCount++;
      }
    }

    onProgress?.call(ImportProgress(
      current: files.length,
      total: files.length,
      currentTitle: 'Done',
      importedCount: importedCount,
      skippedCount: skippedCount,
      isDone: true,
    ));

    return newlyAdded;
  }
}
