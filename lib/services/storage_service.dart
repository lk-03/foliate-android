import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'epub_service.dart';

/// Manages local book storage, cover image caching, linked folder configuration,
/// and library persistence via SharedPreferences.
class StorageService {
  static const String _booksPrefKey = 'foliate_library_books';
  static const String _linkedFoldersPrefKey = 'foliate_linked_folders';
  static const String _firstLaunchPrefKey = 'foliate_first_launch_done';
  static const String _readingHabitsPrefKey = 'foliate_reading_habits';

  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();

  StorageService._();

  Directory? _appDocDir;
  Directory? _booksDir;
  Directory? _coversDir;

  Future<Directory> get booksDirectory async {
    if (_booksDir != null) return _booksDir!;
    _appDocDir ??= await getApplicationDocumentsDirectory();
    _booksDir = Directory('${_appDocDir!.path}/books');
    if (!_booksDir!.existsSync()) {
      _booksDir!.createSync(recursive: true);
    }
    return _booksDir!;
  }

  Future<Directory> get coversDirectory async {
    if (_coversDir != null) return _coversDir!;
    _appDocDir ??= await getApplicationDocumentsDirectory();
    _coversDir = Directory('${_appDocDir!.path}/covers');
    if (!_coversDir!.existsSync()) {
      _coversDir!.createSync(recursive: true);
    }
    return _coversDir!;
  }

  /// Loads all stored books from SharedPreferences.
  Future<List<Book>> getBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_booksPrefKey) ?? [];
    return rawList
        .map((str) {
          try {
            return Book.fromMap(jsonDecode(str) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<Book>()
        .toList();
  }

  /// Persists the complete list of books to SharedPreferences.
  Future<void> saveBooks(List<Book> books) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = books.map((b) => jsonEncode(b.toMap())).toList();
    await prefs.setStringList(_booksPrefKey, rawList);
  }

  /// Adds or updates a single book.
  Future<void> saveBook(Book book) async {
    final current = await getBooks();
    final index = current.indexWhere((b) => b.hash == book.hash);
    if (index >= 0) {
      current[index] = book;
    } else {
      current.add(book);
    }
    await saveBooks(current);
  }

  /// Removes a book from the library and cleans up cached storage.
  Future<void> removeBook(String hash) async {
    final current = await getBooks();
    final index = current.indexWhere((b) => b.hash == hash);
    if (index >= 0) {
      final book = current[index];
      current.removeAt(index);
      await saveBooks(current);

      // Clean up internal files if in internal books dir
      if (book.filePath != null) {
        final f = File(book.filePath!);
        if (f.existsSync() && f.path.contains('/books/')) {
          try {
            f.deleteSync();
          } catch (_) {}
        }
      }
      if (book.coverUri != null) {
        final c = File(book.coverUri!);
        if (c.existsSync()) {
          try {
            c.deleteSync();
          } catch (_) {}
        }
      }
    }
  }

  /// Updates reading progress for a book by its SHA-256 hash.
  Future<Book?> updateBookProgress(
    String hash, {
    required double percentage,
    required String cfi,
  }) async {
    final current = await getBooks();
    final index = current.indexWhere((b) => b.hash == hash);
    if (index >= 0) {
      final updated = current[index].copyWith(
        percentage: percentage,
        cfi: cfi,
        lastReadAt: DateTime.now().millisecondsSinceEpoch,
      );
      current[index] = updated;
      await saveBooks(current);
      return updated;
    }
    return null;
  }

  /// Toggles favorite status for a book.
  Future<Book?> toggleFavorite(String hash) async {
    final current = await getBooks();
    final index = current.indexWhere((b) => b.hash == hash);
    if (index >= 0) {
      final updated = current[index].copyWith(
        isFavorite: !current[index].isFavorite,
      );
      current[index] = updated;
      await saveBooks(current);
      return updated;
    }
    return null;
  }

  /// Toggles pinned status for a book.
  Future<Book?> togglePinned(String hash) async {
    final current = await getBooks();
    final index = current.indexWhere((b) => b.hash == hash);
    if (index >= 0) {
      final updated = current[index].copyWith(
        isPinned: !current[index].isPinned,
      );
      current[index] = updated;
      await saveBooks(current);
      return updated;
    }
    return null;
  }

  /// Gets all registered linked/watched folder paths.
  Future<List<String>> getLinkedFolders() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_linkedFoldersPrefKey) ?? [];
  }

  /// Adds a new linked/watched folder path.
  Future<void> addLinkedFolder(String folderPath) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_linkedFoldersPrefKey) ?? [];
    if (!list.contains(folderPath)) {
      list.add(folderPath);
      await prefs.setStringList(_linkedFoldersPrefKey, list);
    }
  }

  /// Removes a linked folder from the watched list.
  Future<void> removeLinkedFolder(String folderPath) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_linkedFoldersPrefKey) ?? [];
    list.remove(folderPath);
    await prefs.setStringList(_linkedFoldersPrefKey, list);
  }

  /// Loads the raw bytes of an EPUB to pass to the WebView reader engine.
  Future<Uint8List?> getBookBytes(Book book) async {
    // 1. Try existing file path
    if (book.filePath != null) {
      final file = File(book.filePath!);
      if (file.existsSync()) {
        return await file.readAsBytes();
      }
    }

    // 2. Try internal books directory
    final bDir = await booksDirectory;
    final fallbackFile = File('${bDir.path}/${book.hash}.epub');
    if (fallbackFile.existsSync()) {
      return await fallbackFile.readAsBytes();
    }

    return null;
  }

  /// Pre-seeds assets/dummy.epub on initial launch so the user has an immediate book.
  Future<Book?> preseedSampleBookIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final books = await getBooks();

    // Check if sample book is already seeded
    final existingSample = books.firstOrNull;
    if (existingSample != null) return existingSample;

    try {
      final byteData = await rootBundle.load('assets/dummy.epub');
      final bytes = byteData.buffer.asUint8List();

      final bDir = await booksDirectory;
      final cDir = await coversDirectory;

      final book = await EpubService.parseEpubBytes(
        bytes: bytes,
        sourceFilePath: 'assets/dummy.epub',
        coversDir: cDir,
      );

      final targetFile = File('${bDir.path}/${book.hash}.epub');
      await targetFile.writeAsBytes(bytes);

      final persistedBook = book.copyWith(
        filePath: targetFile.path,
        isPinned: true,
      );

      await saveBook(persistedBook);
      await prefs.setBool(_firstLaunchPrefKey, true);
      return persistedBook;
    } catch (e) {
      return null;
    }
  }

  static const String _bookSettingsPrefKeyPrefix = 'foliate_book_settings_';
  static const String _globalReaderSettingsPrefKey = 'foliate_global_reader_settings';

  /// Loads appearance and typography settings for a specific book by hash.
  /// Falls back to global user preferences, or default settings if not set.
  Future<ReaderSettings> getBookSettings(String bookHash) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_bookSettingsPrefKeyPrefix$bookHash');
    if (raw != null) {
      try {
        return ReaderSettings.fromJson(raw);
      } catch (_) {}
    }
    // Fall back to the most recently saved global settings
    final globalRaw = prefs.getString(_globalReaderSettingsPrefKey);
    if (globalRaw != null) {
      try {
        return ReaderSettings.fromJson(globalRaw);
      } catch (_) {}
    }
    return const ReaderSettings();
  }

  /// Persists appearance and typography settings specifically for a book by hash.
  /// Also sets them as the active global defaults for subsequent books.
  Future<void> saveBookSettings(String bookHash, ReaderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = settings.toJson();
    await prefs.setString('$_bookSettingsPrefKeyPrefix$bookHash', jsonStr);
    await prefs.setString(_globalReaderSettingsPrefKey, jsonStr);
  }

  static const String _annotationsPrefKeyPrefix = 'foliate_annotations_';

  /// Retrieves all annotations for a specific book by hash.
  Future<List<Annotation>> getAnnotations(String bookHash) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('$_annotationsPrefKeyPrefix$bookHash') ?? [];
    return list
        .map((s) {
          try {
            return Annotation.fromJson(s);
          } catch (_) {
            return null;
          }
        })
        .whereType<Annotation>()
        .toList();
  }

  /// Saves or updates an annotation for a book.
  Future<void> saveAnnotation(Annotation annotation) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_annotationsPrefKeyPrefix${annotation.bookHash}';
    final list = prefs.getStringList(key) ?? [];
    final current = list
        .map((s) {
          try {
            return Annotation.fromJson(s);
          } catch (_) {
            return null;
          }
        })
        .whereType<Annotation>()
        .toList();

    final idx = current.indexWhere((a) => a.id == annotation.id || a.cfi == annotation.cfi);
    if (idx >= 0) {
      current[idx] = annotation;
    } else {
      current.add(annotation);
    }

    await prefs.setStringList(key, current.map((a) => a.toJson()).toList());
  }

  /// Deletes an annotation by CFI for a given book hash.
  Future<void> deleteAnnotation(String bookHash, String cfi) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_annotationsPrefKeyPrefix$bookHash';
    final list = prefs.getStringList(key) ?? [];
    final current = list
        .map((s) {
          try {
            return Annotation.fromJson(s);
          } catch (_) {
            return null;
          }
        })
        .whereType<Annotation>()
        .toList();

    current.removeWhere((a) => a.cfi == cfi);
    await prefs.setStringList(key, current.map((a) => a.toJson()).toList());
  }

  /// Retrieves all annotations across all books sorted by creation timestamp.
  Future<List<Annotation>> getAllAnnotations() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final annotationKeys = allKeys.where((k) => k.startsWith(_annotationsPrefKeyPrefix));
    final result = <Annotation>[];

    for (final k in annotationKeys) {
      final list = prefs.getStringList(k) ?? [];
      for (final s in list) {
        try {
          result.add(Annotation.fromJson(s));
        } catch (_) {}
      }
    }

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  static const String _bookmarksPrefKeyPrefix = 'foliate_bookmarks_';

  /// Retrieves all bookmarks for a specific book by hash.
  Future<List<Bookmark>> getBookmarks(String bookHash) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('$_bookmarksPrefKeyPrefix$bookHash') ?? [];
    return list
        .map((s) {
          try {
            return Bookmark.fromJson(s);
          } catch (_) {
            return null;
          }
        })
        .whereType<Bookmark>()
        .toList();
  }

  /// Saves or updates a bookmark for a book.
  Future<void> saveBookmark(Bookmark bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_bookmarksPrefKeyPrefix${bookmark.bookHash}';
    final list = prefs.getStringList(key) ?? [];
    final current = list
        .map((s) {
          try {
            return Bookmark.fromJson(s);
          } catch (_) {
            return null;
          }
        })
        .whereType<Bookmark>()
        .toList();

    final idx = current.indexWhere((b) => b.id == bookmark.id || b.cfi == bookmark.cfi);
    if (idx >= 0) {
      current[idx] = bookmark;
    } else {
      current.add(bookmark);
    }

    await prefs.setStringList(key, current.map((b) => b.toJson()).toList());
  }

  /// Deletes a bookmark by CFI for a given book hash.
  Future<void> deleteBookmark(String bookHash, String cfi) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_bookmarksPrefKeyPrefix$bookHash';
    final list = prefs.getStringList(key) ?? [];
    final current = list
        .map((s) {
          try {
            return Bookmark.fromJson(s);
          } catch (_) {
            return null;
          }
        })
        .whereType<Bookmark>()
        .toList();

    current.removeWhere((b) => b.cfi == cfi);
    await prefs.setStringList(key, current.map((b) => b.toJson()).toList());
  }

  /// Checks if a CFI is bookmarked in a book.
  Future<bool> isBookmarked(String bookHash, String cfi) async {
    final bookmarks = await getBookmarks(bookHash);
    return bookmarks.any((b) => b.cfi == cfi);
  }

  /// Retrieves user reading habits, streaks, and challenge progress.
  Future<ReadingHabits> getReadingHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_readingHabitsPrefKey);
    if (raw == null || raw.isEmpty) {
      // Return fresh default habits
      return const ReadingHabits();
    }
    try {
      return ReadingHabits.fromJson(raw);
    } catch (_) {
      return const ReadingHabits();
    }
  }

  /// Saves updated reading habits.
  Future<void> saveReadingHabits(ReadingHabits habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_readingHabitsPrefKey, habits.toJson());
  }

  /// Records an active reading session in seconds, updating daily history, streaks, and total time.
  Future<ReadingHabits> recordReadingTime(int durationSeconds, {String? bookHash}) async {
    if (durationSeconds <= 0) return await getReadingHabits();
    final current = await getReadingHabits();
    final updated = current.recordSession(durationSeconds);
    await saveReadingHabits(updated);

    // If bookHash is provided, update book's totalReadingTimeMs and lastReadAt
    if (bookHash != null) {
      final books = await getBooks();
      final idx = books.indexWhere((b) => b.hash == bookHash);
      if (idx >= 0) {
        final b = books[idx];
        final newBook = b.copyWith(
          lastReadAt: DateTime.now().millisecondsSinceEpoch,
          totalReadingTimeMs: b.totalReadingTimeMs + (durationSeconds * 1000),
        );
        books[idx] = newBook;
        await saveBooks(books);
      }
    }

    return updated;
  }

  /// Marks a book as finished in the annual challenge.
  Future<ReadingHabits> markBookFinished(String bookHash) async {
    final current = await getReadingHabits();
    final updated = current.markBookFinished(bookHash);
    await saveReadingHabits(updated);
    return updated;
  }

  /// Updates daily reading goal target in minutes.
  Future<ReadingHabits> updateDailyReadingGoal(int minutes) async {
    final current = await getReadingHabits();
    final updated = current.copyWith(dailyGoalMinutes: minutes);
    await saveReadingHabits(updated);
    return updated;
  }

  /// Updates annual reading challenge goal in target books count.
  Future<ReadingHabits> updateYearlyReadingGoal(int targetBooks) async {
    final current = await getReadingHabits();
    final updated = current.copyWith(yearlyGoalBooks: targetBooks);
    await saveReadingHabits(updated);
    return updated;
  }
}

