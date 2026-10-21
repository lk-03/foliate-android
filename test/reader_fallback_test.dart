import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foliate/models/models.dart';
import 'package:foliate/reader/reader.dart';
import 'package:foliate/screens/reader_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
  });

  group('Reader Engine Safety & Fallback Tests', () {
    testWidgets('ReaderWebView safely handles null WebViewPlatform and fires onError', (WidgetTester tester) async {
      String? receivedError;
      final bridge = ReaderBridge();
      bridge.onError = (err) {
        receivedError = err;
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReaderWebView(bridge: bridge),
          ),
        ),
      );
      await tester.pump();

      expect(receivedError, isNotNull);
      expect(receivedError, contains('WebView is not available on this platform'));
      expect(bridge.hasActiveController, isFalse);
    });

    testWidgets('ReaderScreen falls back to pure-Dart chapter reader when WebView unavailable', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final dummyFile = File('assets/dummy.epub');
      expect(dummyFile.existsSync(), isTrue);

      const testBook = Book(
        hash: 'test-dummy-hash',
        title: 'Dummy Book',
        author: 'Test Author',
        filePath: 'assets/dummy.epub',
        addedAt: 1725450000000,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ReaderScreen(
            book: testBook,
          ),
        ),
      );

      // Frame 1: ReaderWebView triggers onError -> schedules post-frame fallback handler
      await tester.pump();
      // Frame 2: post-frame fallback handler runs, extracts chapters, and triggers setState
      await tester.pump();
      // Frame 3: Settle transition
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the reader did not get stuck in indefinite "Opening book..."
      expect(find.text('Opening book...'), findsNothing);

      // Verify fallback mode rendered content with chapter navigation
      expect(find.byType(SelectionArea), findsOneWidget);
      expect(find.text('Next Chapter'), findsOneWidget);
      expect(find.text('Previous Chapter'), findsOneWidget);
    });

    testWidgets('ReaderScreen displays clean error card when book bytes cannot be loaded', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      const missingBook = Book(
        hash: 'missing-hash-999',
        title: 'Missing Book',
        author: 'No Author',
        filePath: 'nonexistent/path/book.epub',
        addedAt: 1725450000000,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ReaderScreen(
            book: missingBook,
          ),
        ),
      );

      // Frame 1: ReaderWebView triggers onError
      await tester.pump();
      // Frame 2: Fallback handler runs, cannot find bytes, sets _engineError
      await tester.pump();
      // Frame 3: Settle transition
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the reader shows the error card with Retry and Close actions
      expect(find.text('Opening book...'), findsNothing);
      expect(find.text('Unable to Open Book'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });
}
