import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foliate/screens/catalog_browser_screen.dart';
import 'package:foliate/screens/open_libraries_screen.dart';
import 'package:foliate/theme/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: AdwaitaTheme.dark(),
      home: child,
    );
  }

  group('CatalogBrowserScreen Widget Tests', () {
    testWidgets('Renders error state gracefully when empty or invalid URL', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const CatalogBrowserScreen(
            title: 'Empty Feed',
            initialFeedUrl: '',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Empty Feed'), findsOneWidget);
      expect(find.text('Unable to Load Feed'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });
  });

  group('OpenLibrariesScreen Widget Tests', () {
    testWidgets('Renders available libraries and Open Library search banner', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const Scaffold(
            body: OpenLibrariesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and library list
      expect(find.textContaining('Available Libraries'), findsOneWidget);
      expect(find.text('Project Gutenberg'), findsOneWidget);
      expect(find.text('Standard Ebooks'), findsOneWidget);
      expect(find.text('Add OPDS'), findsOneWidget);

      // Enter search query
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'frankenstein');
      await tester.pumpAndSettle();

      // Verify Open Library prompt banner appears
      expect(find.text('Search Open Library for "frankenstein"'), findsOneWidget);
      expect(find.text('Search millions of public domain books & classics'), findsOneWidget);
    });

    testWidgets('Opens catalog details sheet and displays Browse Catalog action', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const Scaffold(
            body: OpenLibrariesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Standard Ebooks catalog card
      await tester.tap(find.text('Standard Ebooks'));
      await tester.pumpAndSettle();

      // Verify details modal sheet opens
      expect(find.text('Browse Catalog'), findsOneWidget);
      expect(find.byIcon(Icons.auto_stories_rounded), findsWidgets);
    });
  });
}
