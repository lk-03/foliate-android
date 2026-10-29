import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foliate/components/components.dart';
import 'package:foliate/models/models.dart';
import 'package:foliate/screens/reader_screen.dart';
import 'package:foliate/services/services.dart';
import 'package:foliate/theme/theme.dart';
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

  group('DesktopReadingScrubber Tests', () {
    const testLocation = ReadingLocation(
      cfi: 'epubcfi(/6/14[chapter_07]!/4/2/10/1:0)',
      percentage: 98.2,
      currentLocation: 1178,
      totalLocations: 1206,
      currentSection: 55,
      totalSections: 57,
      sectionTitle: 'Lispenard Street',
    );

    final testToc = [
      const TOCItem(href: 'ch1.xhtml', label: 'Chapter 1'),
      const TOCItem(href: 'ch2.xhtml', label: 'Lispenard Street'),
    ];

    testWidgets('renders hover scrubber bar with Foliate controls', (tester) async {
      bool prevClicked = false;
      bool nextClicked = false;
      bool undoClicked = false;
      bool redoClicked = false;
      bool ttsClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [FoliateThemeColors.dark],
          ),
          home: Scaffold(
            body: Stack(
              children: [
                DesktopReadingScrubber(
                  location: testLocation,
                  percentage: 98.2,
                  toc: testToc,
                  accentColor: AdwaitaColors.foliateGreen,
                  readerFg: Colors.white,
                  readerBg: const Color(0xFF1E1E1E),
                  onPrevPage: () => prevClicked = true,
                  onNextPage: () => nextClicked = true,
                  onUndo: () => undoClicked = true,
                  onRedo: () => redoClicked = true,
                  onToggleTts: () => ttsClicked = true,
                ),
              ],
            ),
          ),
        ),
      );

      // Verify progress percentage pill
      expect(find.text('98%'), findsOneWidget);

      // Verify action buttons
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
      expect(find.byIcon(Icons.redo_rounded), findsOneWidget);
      expect(find.byIcon(Icons.headphones_outlined), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      // Tap buttons and verify callbacks
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      expect(prevClicked, isTrue);

      await tester.tap(find.byIcon(Icons.undo_rounded));
      expect(undoClicked, isTrue);

      await tester.tap(find.byIcon(Icons.redo_rounded));
      expect(redoClicked, isTrue);

      await tester.tap(find.byIcon(Icons.headphones_outlined));
      expect(ttsClicked, isTrue);

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      expect(nextClicked, isTrue);
    });

    testWidgets('clicking progress pill opens Foliate location & time popover', (tester) async {
      int? submittedLoc;
      bool popoverVisibility = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [FoliateThemeColors.dark],
          ),
          home: Scaffold(
            body: Stack(
              children: [
                DesktopReadingScrubber(
                  location: testLocation,
                  percentage: 98.2,
                  toc: testToc,
                  accentColor: AdwaitaColors.foliateGreen,
                  readerFg: Colors.white,
                  readerBg: const Color(0xFF1E1E1E),
                  onLocationSubmitted: (loc) => submittedLoc = loc,
                  onPopoverVisibilityChanged: (v) => popoverVisibility = v,
                ),
              ],
            ),
          ),
        ),
      );

      // Initially popover is closed
      expect(find.text('Time Left in Section'), findsNothing);
      expect(find.text('Time Left in Book'), findsNothing);
      expect(find.text('Identifier'), findsNothing);

      // Click on 98% progress pill
      await tester.tap(find.text('98%'));
      await tester.pumpAndSettle();

      expect(popoverVisibility, isTrue);

      // Verify Foliate popover contents matching Image 3
      expect(find.text('Time Left in Section'), findsOneWidget);
      expect(find.text('Time Left in Book'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Identifier'), findsOneWidget);
      expect(find.text('Section'), findsOneWidget);
      expect(find.text('55'), findsOneWidget);
      expect(find.text('of 57'), findsOneWidget);
      expect(find.text('of 1206'), findsOneWidget);

      // Verify CFI string is visible
      expect(find.text(testLocation.cfi), findsOneWidget);

      // Verify steppers
      expect(find.byIcon(Icons.first_page_rounded), findsOneWidget);
      expect(find.byIcon(Icons.last_page_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);

      // Submit location
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      await tester.enterText(textFieldFinder, '500');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(submittedLoc, equals(500));
    });
  });

  group('ReaderSidebarPanel Tests', () {
    const testBook = Book(
      hash: 'test-book-hash',
      title: 'A Little Life',
      author: 'Hanya Yanagihara',
      addedAt: 1725450000000,
    );

    final testToc = [
      const TOCItem(href: 'ch1.xhtml', label: 'Lispenard Street'),
      const TOCItem(href: 'ch2.xhtml', label: 'The Postman'),
    ];

    testWidgets('renders left-docked header, book cover, and bottom tabs', (tester) async {
      ReaderSidePanelType currentPanel = ReaderSidePanelType.toc;
      bool libraryBackClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [FoliateThemeColors.dark],
          ),
          home: Scaffold(
            body: ReaderSidebarPanel(
              panelType: currentPanel,
              book: testBook,
              toc: testToc,
              currentLocation: const ReadingLocation(
                cfi: 'ch1.xhtml',
                sectionTitle: 'Lispenard Street',
                currentSection: 0,
              ),
              onChapterSelected: (_) {},
              settings: const ReaderSettings(),
              onSettingsChanged: (_) {},
              bookmarks: const [],
              onSelectBookmark: (_) {},
              onDeleteBookmark: (_) {},
              annotations: const [],
              onSelectAnnotation: (_) {},
              onDeleteAnnotation: (_) {},
              onClose: () {},
              onBackToLibrary: () => libraryBackClicked = true,
              onPanelTypeChanged: (type) => currentPanel = type,
              searchSectionsNotifier: ValueNotifier([]),
              isSearchingNotifier: ValueNotifier(false),
              totalMatchesNotifier: ValueNotifier(0),
              onSearch: (q, matchCase) {},
              onClearSearch: () {},
              onSelectSearchMatch: (item, idx) {},
            ),
          ),
        ),
      );

      // Verify Library back button in top action bar
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      expect(libraryBackClicked, isTrue);

      // Verify book title and author header
      expect(find.text('A Little Life'), findsOneWidget);
      expect(find.text('Hanya Yanagihara'), findsOneWidget);

      // Verify chapter labels
      expect(find.text('Lispenard Street'), findsOneWidget);
      expect(find.text('The Postman'), findsOneWidget);

      // Verify 3-tab segmented icons with tooltips at bottom
      expect(find.byTooltip('Table of Contents'), findsOneWidget);
      expect(find.byTooltip('Annotations'), findsOneWidget);
      expect(find.byTooltip('Bookmarks'), findsOneWidget);

      // Tap Annotations tab
      await tester.tap(find.byTooltip('Annotations'));
      expect(currentPanel, equals(ReaderSidePanelType.annotations));

      // Tap Bookmarks tab
      await tester.tap(find.byTooltip('Bookmarks'));
      expect(currentPanel, equals(ReaderSidePanelType.bookmarks));
    });
  });

  group('Desktop Reader Fallback & Clean Minimal View Tests', () {
    testWidgets('ReaderScreen desktop does not render Desktop Native Reader tag', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final dummyFile = File('assets/dummy.epub');
      expect(dummyFile.existsSync(), isTrue);

      const testBook = Book(
        hash: 'dummy-book-hash',
        title: 'Dummy Book',
        author: 'Test Author',
        filePath: 'assets/dummy.epub',
        addedAt: 1725450000000,
      );

      // Use a wide screen size (1200x800) for desktop
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [FoliateThemeColors.dark],
          ),
          home: const ReaderScreen(
            book: testBook,
          ),
        ),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify "Desktop Native Reader" tag is completely removed
      expect(find.text('Desktop Native Reader'), findsNothing);

      // 2. Verify mobile overlays are omitted on wide screens
      expect(find.byType(FloatingReaderCapsule), findsNothing);
      expect(find.byType(ReaderPageSliderBar), findsNothing);

      // 3. Verify left sidebar is docked on desktop
      expect(find.byType(ReaderSidebarPanel), findsOneWidget);

      // 4. Verify selection area and chapter content rendered
      expect(find.byType(SelectionArea), findsOneWidget);

      // 5. Verify horizontal PageView is rendered for spreads
      expect(find.byType(PageView), findsOneWidget);
    });

    test('DesktopSpreadPaginator correctly paginates chapters into two-page spreads', () {
      final chapters = [
        const EpubChapter(
          id: 'ch1',
          title: '[I] First Chapter',
          href: 'ch1.xhtml',
          paragraphs: [
            'Paragraph one with some nice text for reading.',
            'Paragraph two continuing the story in the first chapter.',
            'Paragraph three adding more narrative detail.',
          ],
        ),
        const EpubChapter(
          id: 'ch2',
          title: '[II] Second Chapter',
          href: 'ch2.xhtml',
          paragraphs: [
            'Second chapter starting paragraph.',
            'Another paragraph in the second chapter.',
          ],
        ),
      ];

      final spreads = DesktopSpreadPaginator.paginate(chapters: chapters, wordsPerColumn: 10);
      expect(spreads.isNotEmpty, isTrue);

      // Verify locations are sequential and properly bounded
      for (final s in spreads) {
        expect(s.leftLoc, lessThanOrEqualTo(s.rightLoc));
        expect(s.rightLoc, lessThanOrEqualTo(s.totalLocs));
        expect(s.totalLocs, equals(spreads.length * 2));
      }

      // Verify locating by href, loc, and chapter
      final loc1Idx = DesktopSpreadPaginator.findSpreadIndexForLoc(spreads, 1);
      expect(loc1Idx, equals(0));

      final ch2Idx = DesktopSpreadPaginator.findSpreadIndexForChapter(spreads, 1);
      expect(spreads[ch2Idx].chapterIndex, equals(1));

      final hrefIdx = DesktopSpreadPaginator.findSpreadIndexForHref(spreads, 'ch2.xhtml');
      expect(spreads[hrefIdx].chapterIndex, equals(1));
    });

    test('MobilePagePaginator correctly paginates chapters into single pages', () {
      final chapters = [
        const EpubChapter(
          id: 'ch1',
          title: '[I] First Chapter',
          href: 'ch1.xhtml',
          paragraphs: [
            'Paragraph one with some nice text for reading on mobile.',
            'Paragraph two continuing the story on mobile screen.',
          ],
        ),
        const EpubChapter(
          id: 'ch2',
          title: '[II] Second Chapter',
          href: 'ch2.xhtml',
          paragraphs: [
            'Second chapter starting paragraph.',
          ],
        ),
      ];

      final pages = MobilePagePaginator.paginate(chapters: chapters, wordsPerPage: 10);
      expect(pages.isNotEmpty, isTrue);

      for (int i = 0; i < pages.length; i++) {
        final p = pages[i];
        expect(p.pageIndex, equals(i));
        expect(p.loc, equals(i + 1));
        expect(p.totalLocs, equals(pages.length));
      }

      final loc1Idx = MobilePagePaginator.findPageIndexForLoc(pages, 1);
      expect(loc1Idx, equals(0));

      final ch2Idx = MobilePagePaginator.findPageIndexForChapter(pages, 1);
      expect(pages[ch2Idx].chapterIndex, equals(1));

      final hrefIdx = MobilePagePaginator.findPageIndexForHref(pages, 'ch2.xhtml');
      expect(pages[hrefIdx].chapterIndex, equals(1));
    });
  });
}

