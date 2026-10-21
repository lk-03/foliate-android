import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foliate/components/reader_sidebar_panel.dart';
import 'package:foliate/models/models.dart';
import 'package:foliate/theme/theme.dart';

void main() {
  group('Adaptive Layout & Desktop Panel Tests', () {
    const testBook = Book(
      hash: 'test-hash-1',
      title: 'Adaptive Layout Book',
      author: 'Author Name',
      addedAt: 1725458000000,
    );

    const testTOC = [
      TOCItem(label: 'Chapter 1: The Beginning', href: 'chap1.xhtml'),
      TOCItem(label: 'Chapter 2: The Journey', href: 'chap2.xhtml'),
    ];

    const testBookmarks = [
      Bookmark(
        id: 'bm-1',
        bookHash: 'test-hash-1',
        cfi: 'epubcfi(/6/4!/4/2)',
        chapterTitle: 'Chapter 1',
        percentage: 12.5,
        createdAt: 1725458000000,
      ),
    ];

    const testAnnotations = [
      Annotation(
        id: 'ann-1',
        bookHash: 'test-hash-1',
        cfi: 'epubcfi(/6/4!/4/2/8)',
        text: 'A profound sentence about adaptive layouts.',
        note: 'Important quote',
        color: '#FFE066',
        createdAt: 1725458000000,
      ),
    ];

    test('Responsive grid column calculation clamps between 3 and 8 columns', () {
      int calculateColumns(double width) => (width / 135).clamp(3, 8).toInt();

      expect(calculateColumns(360), 3); // Small phone
      expect(calculateColumns(400), 3); // Standard phone
      expect(calculateColumns(800), 5); // Tablet / small desktop window
      expect(calculateColumns(1080), 8); // Desktop display
      expect(calculateColumns(1920), 8); // Wide desktop display
    });

    testWidgets('ReaderSidebarPanel renders TOC and Bookmarks panel', (tester) async {
      final searchSectionsNotifier = ValueNotifier<List<SearchSection>>([]);
      final isSearchingNotifier = ValueNotifier<bool>(false);
      final totalMatchesNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [FoliateThemeColors.light],
          ),
          home: Scaffold(
            body: ReaderSidebarPanel(
              panelType: ReaderSidePanelType.toc,
              onClose: () {},
              book: testBook,
              toc: testTOC,
              bookmarks: testBookmarks,
              onChapterSelected: (_) {},
              searchSectionsNotifier: searchSectionsNotifier,
              isSearchingNotifier: isSearchingNotifier,
              totalMatchesNotifier: totalMatchesNotifier,
              onSearch: (_, __) {},
              onClearSearch: () {},
              onSelectSearchMatch: (_, __) {},
              settings: const ReaderSettings(),
              onSettingsChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Contents & Bookmarks'), findsOneWidget);
      expect(find.text('Chapter 1: The Beginning'), findsOneWidget);
      expect(find.text('Bookmarks (1)'), findsOneWidget);
    });

    testWidgets('ReaderSidebarPanel renders Appearance & Layout panel with two-page spread toggle', (tester) async {
      final searchSectionsNotifier = ValueNotifier<List<SearchSection>>([]);
      final isSearchingNotifier = ValueNotifier<bool>(false);
      final totalMatchesNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [FoliateThemeColors.light],
          ),
          home: Scaffold(
            body: ReaderSidebarPanel(
              panelType: ReaderSidePanelType.appearance,
              onClose: () {},
              book: testBook,
              toc: testTOC,
              onChapterSelected: (_) {},
              searchSectionsNotifier: searchSectionsNotifier,
              isSearchingNotifier: isSearchingNotifier,
              totalMatchesNotifier: totalMatchesNotifier,
              onSearch: (_, __) {},
              onClearSearch: () {},
              onSelectSearchMatch: (_, __) {},
              settings: const ReaderSettings(twoPagesLandscape: true),
              onSettingsChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Appearance & Layout'), findsOneWidget);
      expect(find.text('Two-page spread'), findsOneWidget);
      expect(find.text('Font Family'), findsOneWidget);
    });

    testWidgets('ReaderSidebarPanel renders Highlights & Notes panel', (tester) async {
      final searchSectionsNotifier = ValueNotifier<List<SearchSection>>([]);
      final isSearchingNotifier = ValueNotifier<bool>(false);
      final totalMatchesNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [FoliateThemeColors.light],
          ),
          home: Scaffold(
            body: ReaderSidebarPanel(
              panelType: ReaderSidePanelType.annotations,
              onClose: () {},
              book: testBook,
              toc: testTOC,
              annotations: testAnnotations,
              onChapterSelected: (_) {},
              searchSectionsNotifier: searchSectionsNotifier,
              isSearchingNotifier: isSearchingNotifier,
              totalMatchesNotifier: totalMatchesNotifier,
              onSearch: (_, __) {},
              onClearSearch: () {},
              onSelectSearchMatch: (_, __) {},
              settings: const ReaderSettings(),
              onSettingsChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Highlights & Notes'), findsOneWidget);
      expect(find.text('Important quote'), findsOneWidget);
      expect(find.text('A profound sentence about adaptive layouts.'), findsOneWidget);
    });
  });
}
