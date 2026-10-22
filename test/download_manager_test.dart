import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foliate/components/components.dart';
import 'package:foliate/models/models.dart';
import 'package:foliate/services/services.dart';
import 'package:foliate/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'foliate_first_launch_done': true,
    });
    StorageService.instance.setAppDocDirForTesting(Directory.systemTemp);
    DownloadService.instance.tasksNotifier.value = [];
  });

  group('DownloadTask model tests', () {
    test('JSON serialization roundtrip', () {
      const task = DownloadTask(
        id: 'task-101',
        title: 'Moby Dick',
        author: 'Herman Melville',
        downloadUrl: 'https://example.com/mobydick.epub',
        coverUrl: 'https://example.com/covers/mobydick.jpg',
        fileSizeBytes: 2048000,
        downloadedBytes: 1024000,
        status: DownloadStatus.downloading,
        progress: 0.5,
        speedBytesPerSecond: 256000,
        startedAt: 1729600000000,
      );

      final jsonStr = task.toJson();
      final parsed = DownloadTask.fromJson(jsonStr);

      expect(parsed.id, equals(task.id));
      expect(parsed.title, equals(task.title));
      expect(parsed.author, equals(task.author));
      expect(parsed.downloadUrl, equals(task.downloadUrl));
      expect(parsed.fileSizeBytes, equals(2048000));
      expect(parsed.downloadedBytes, equals(1024000));
      expect(parsed.status, equals(DownloadStatus.downloading));
      expect(parsed.progress, equals(0.5));
      expect(parsed.isActive, isTrue);
      expect(parsed.isCompleted, isFalse);
    });

    test('Formatted progress and size helper methods', () {
      const task = DownloadTask(
        id: 'task-102',
        title: 'Frankenstein',
        author: 'Mary Shelley',
        downloadUrl: 'https://example.com/frankenstein.epub',
        fileSizeBytes: 5242880, // 5 MB
        downloadedBytes: 2621440, // 2.5 MB
        status: DownloadStatus.downloading,
        progress: 0.5,
        speedBytesPerSecond: 1048576, // 1 MB/s
      );

      expect(task.formattedProgress, equals('50%'));
      expect(task.formattedDownloadedSize, equals('2.5 MB'));
      expect(task.formattedTotalSize, equals('5.0 MB'));
      expect(task.formattedSpeed, equals('1.0 MB/s'));
    });

    test('Terminal state flags', () {
      const completed = DownloadTask(
        id: 't1',
        title: 'Book 1',
        author: 'Author 1',
        downloadUrl: 'url',
        status: DownloadStatus.completed,
      );
      expect(completed.isCompleted, isTrue);
      expect(completed.isTerminal, isTrue);
      expect(completed.isActive, isFalse);

      const failed = DownloadTask(
        id: 't2',
        title: 'Book 2',
        author: 'Author 2',
        downloadUrl: 'url',
        status: DownloadStatus.failed,
      );
      expect(failed.isFailed, isTrue);
      expect(failed.isTerminal, isTrue);

      const cancelled = DownloadTask(
        id: 't3',
        title: 'Book 3',
        author: 'Author 3',
        downloadUrl: 'url',
        status: DownloadStatus.cancelled,
      );
      expect(cancelled.isCancelled, isTrue);
      expect(cancelled.isTerminal, isTrue);
    });
  });

  group('StorageService download history tests', () {
    test('Persists and clears download tasks', () async {
      final storage = StorageService.instance;
      expect(await storage.getDownloadTasks(), isEmpty);

      const task1 = DownloadTask(
        id: 'd1',
        title: 'Dracula',
        author: 'Bram Stoker',
        downloadUrl: 'https://example.com/dracula.epub',
        status: DownloadStatus.downloading,
      );

      const task2 = DownloadTask(
        id: 'd2',
        title: 'Ulysses',
        author: 'James Joyce',
        downloadUrl: 'https://example.com/ulysses.epub',
        status: DownloadStatus.completed,
      );

      await storage.saveDownloadTask(task1);
      await storage.saveDownloadTask(task2);

      var tasks = await storage.getDownloadTasks();
      expect(tasks.length, equals(2));

      await storage.removeDownloadTask('d1');
      tasks = await storage.getDownloadTasks();
      expect(tasks.length, equals(1));
      expect(tasks.first.id, equals('d2'));

      await storage.clearFinishedDownloadTasks();
      tasks = await storage.getDownloadTasks();
      expect(tasks, isEmpty);
    });

    test('Custom downloads directory affects effective books directory', () async {
      final storage = StorageService.instance;
      final defaultDir = await storage.getEffectiveBooksDirectory();
      expect(defaultDir.existsSync(), isTrue);

      final tempCustomDir = Directory.systemTemp.createTempSync('foliate_custom_books_');
      try {
        await storage.setDownloadsDirectoryPath(tempCustomDir.path);
        final effectiveDir = await storage.getEffectiveBooksDirectory();
        expect(effectiveDir.path, equals(tempCustomDir.path));

        await storage.setDownloadsDirectoryPath(null);
        final restoredDir = await storage.getEffectiveBooksDirectory();
        expect(restoredDir.path, equals(defaultDir.path));
      } finally {
        tempCustomDir.deleteSync(recursive: true);
      }
    });
  });

  group('DownloadHudButton widget tests', () {
    testWidgets('Renders idle state when no active downloads', (tester) async {
      DownloadService.instance.tasksNotifier.value = [];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [FoliateThemeColors.dark],
          ),
          home: const Scaffold(
            body: DownloadHudButton(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Downloads'), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    });

    testWidgets('Renders badge and active count when downloads are active', (tester) async {
      DownloadService.instance.tasksNotifier.value = [
        const DownloadTask(
          id: 'task-active-1',
          title: 'Active Book',
          author: 'Author',
          downloadUrl: 'url',
          status: DownloadStatus.downloading,
          progress: 0.6,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [FoliateThemeColors.dark],
          ),
          home: const Scaffold(
            body: DownloadHudButton(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 Active'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Tapping DownloadHudButton opens DownloadManagerSheet', (tester) async {
      DownloadService.instance.tasksNotifier.value = [];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [FoliateThemeColors.dark],
          ),
          home: const Scaffold(
            body: DownloadHudButton(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Downloads'));
      await tester.pumpAndSettle();

      expect(find.byType(DownloadManagerSheet), findsOneWidget);
      expect(find.text('Download Manager'), findsOneWidget);
      expect(find.text('No Downloads Yet'), findsOneWidget);
    });
  });

  group('DownloadManagerSheet widget tests', () {
    testWidgets('Displays active transfers with controls and completed history', (tester) async {
      DownloadService.instance.tasksNotifier.value = [
        const DownloadTask(
          id: 'active-1',
          title: 'Don Quixote',
          author: 'Miguel de Cervantes',
          downloadUrl: 'url1',
          status: DownloadStatus.downloading,
          progress: 0.45,
          downloadedBytes: 1500000,
          fileSizeBytes: 3000000,
          speedBytesPerSecond: 500000,
        ),
        const DownloadTask(
          id: 'completed-1',
          title: 'The Odyssey',
          author: 'Homer',
          downloadUrl: 'url2',
          status: DownloadStatus.completed,
          progress: 1.0,
          downloadedBytes: 1200000,
          fileSizeBytes: 1200000,
          completedAt: 1729600000000,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [FoliateThemeColors.dark],
          ),
          home: const Scaffold(
            body: DownloadManagerSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Download Manager'), findsOneWidget);
      expect(find.text('1 active'), findsOneWidget);
      expect(find.textContaining('ACTIVE DOWNLOADS'), findsOneWidget);
      expect(find.text('Don Quixote'), findsOneWidget);
      expect(find.textContaining('DOWNLOAD HISTORY'), findsOneWidget);
      expect(find.text('The Odyssey'), findsOneWidget);

      // Verify controls
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tapping on Don Quixote tile opens DownloadBookDetailsSheet
      await tester.tap(find.text('Don Quixote'));
      await tester.pumpAndSettle();

      expect(find.byType(DownloadBookDetailsSheet), findsOneWidget);
      expect(find.text('Download URL'), findsOneWidget);
      expect(find.text('Storage Location'), findsNothing); // not completed yet
    });
  });

  group('DownloadBookDetailsSheet widget tests', () {
    testWidgets('Displays completed book metadata and Read Now button', (tester) async {
      const task = DownloadTask(
        id: 'comp-1',
        title: 'War and Peace',
        author: 'Leo Tolstoy',
        downloadUrl: 'https://example.com/warandpeace.epub',
        status: DownloadStatus.completed,
        progress: 1.0,
        downloadedBytes: 8000000,
        fileSizeBytes: 8000000,
        localFilePath: '/storage/books/warandpeace.epub',
        completedAt: 1729600000000,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [FoliateThemeColors.dark],
          ),
          home: const Scaffold(
            body: DownloadBookDetailsSheet(task: task),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('War and Peace'), findsOneWidget);
      expect(find.text('Leo Tolstoy'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Read Now'), findsOneWidget);
      expect(find.text('Download URL'), findsOneWidget);
      expect(find.text('Storage Location'), findsOneWidget);
      expect(find.text('/storage/books/warandpeace.epub'), findsOneWidget);
    });
  });
}
