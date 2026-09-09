import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foliate/main.dart';
import 'package:foliate/models/models.dart';
import 'package:foliate/components/components.dart';
import 'package:foliate/screens/annotations_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('FoliateApp mobile navigation smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'foliate_library_books': [
        jsonEncode(const Book(
          hash: 'test-hash-1',
          title: 'A Little Life',
          author: 'Hanya Yanagihara',
          addedAt: 1725450000000,
        ).toMap()),
      ],
    });

    // Build our app and trigger frames until settled.
    await tester.pumpWidget(const FoliateApp());
    await tester.pumpAndSettle();

    // Verify Home screen loaded
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Continue Reading'), findsOneWidget);
    expect(find.text('Your Library'), findsOneWidget);

    // Verify hamburger menu icon is removed
    expect(find.byIcon(Icons.menu_rounded), findsNothing);

    // Test swipeable PageView navigation: swipe left to go to Library
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // Verify Library screen active with segmented switcher
    expect(find.text('My Books (1)'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);

    // Tap Discover segmented tab
    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    // Verify Open Libraries catalogs visible under Discover tab
    expect(find.text('Project Gutenberg'), findsOneWidget);
    expect(find.text('Standard Ebooks'), findsOneWidget);

    // Tap Settings gear in top bar
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    // Verify SettingsSheet is open
    expect(find.text('Settings & Library'), findsOneWidget);
    expect(find.text('Books in Library'), findsOneWidget);
  });

  testWidgets('AppLogo renders correctly with black gradient tile', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: const Scaffold(
          body: Column(
            children: [
              AppLogo(size: 32),
              AppLogo(size: 48, showTile: false),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(AppLogo), findsNWidgets(2));
  });


  testWidgets('ReaderLayoutSheet controls and stepper test', (WidgetTester tester) async {
    ReaderSettings currentSettings = const ReaderSettings();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: ReaderLayoutSheet(
            settings: currentSettings,
            onSettingsChanged: (newVal) => currentSettings = newVal,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Layout'), findsOneWidget);
    expect(find.text('Side Margins'), findsOneWidget);
    expect(find.text('Hyphenation'), findsOneWidget);
    expect(find.text('Page Animation & Transitions'), findsOneWidget);
    expect(find.text('Slide'), findsOneWidget);
    expect(find.text('Scroll'), findsOneWidget);
    expect(find.text('Fast'), findsOneWidget);
    expect(find.text('Continuous Scrolled Mode'), findsOneWidget);
    expect(find.text('Two Columns (Landscape)'), findsOneWidget);
    expect(find.text('Pages Left'), findsOneWidget);

    // Tap Fast animation chip
    await tester.tap(find.text('Fast'));
    await tester.pumpAndSettle();
    expect(currentSettings.pageAnimationMode, equals(PageAnimationMode.none));

    // Tap Slide animation chip
    await tester.tap(find.text('Slide'));
    await tester.pumpAndSettle();
    expect(currentSettings.pageAnimationMode, equals(PageAnimationMode.slide));
  });

  testWidgets('PageCurlOverlay renders child and triggers tap navigation', (WidgetTester tester) async {
    bool nextCalled = false;
    bool prevCalled = false;
    bool toggleHUDCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: PageCurlOverlay(
            settings: const ReaderSettings(pageAnimationMode: PageAnimationMode.slide),
            backgroundColor: Colors.black,
            textColor: Colors.white,
            onNextPage: () => nextCalled = true,
            onPrevPage: () => prevCalled = true,
            onToggleHUD: () => toggleHUDCalled = true,
            child: const Center(child: Text('Book Content Page')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Book Content Page'), findsOneWidget);

    // Tap right 28% -> Next Page
    await tester.tapAt(const Offset(700, 300));
    await tester.pumpAndSettle();
    expect(nextCalled, isTrue);

    // Tap left 28% -> Prev Page
    await tester.tapAt(const Offset(50, 300));
    await tester.pumpAndSettle();
    expect(prevCalled, isTrue);

    // Tap center 44% -> Toggle HUD
    await tester.tapAt(const Offset(400, 300));
    await tester.pumpAndSettle();
    expect(toggleHUDCalled, isTrue);
  });

  testWidgets('ReaderThemeCustomizeSheet live preview and font controls test', (WidgetTester tester) async {
    ReaderSettings currentSettings = const ReaderSettings();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: ReaderThemeCustomizeSheet(
            settings: currentSettings,
            onSettingsChanged: (newVal) => currentSettings = newVal,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Customize Theme'), findsOneWidget);
    expect(find.text('Aa'), findsWidgets);
    expect(find.text('Font'), findsOneWidget);
    expect(find.text('Override Publisher Font'), findsOneWidget);
    expect(find.text('Bold Text'), findsOneWidget);
    expect(find.text('Line Spacing'), findsOneWidget);
    expect(find.text('Alignment'), findsOneWidget);
    expect(find.text('Reset Typography'), findsOneWidget);
  });

  testWidgets('ReaderSearchSheet displays streaming results and responds to match taps',
      (WidgetTester tester) async {
    final sectionsNotifier = ValueNotifier<List<SearchSection>>([]);
    final isSearchingNotifier = ValueNotifier<bool>(false);
    final totalMatchesNotifier = ValueNotifier<int>(0);

    String lastSearchedQuery = '';
    bool lastMatchCase = false;
    SearchResultItem? selectedMatch;
    int? selectedIndex;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: ReaderSearchSheet(
            sectionsNotifier: sectionsNotifier,
            isSearchingNotifier: isSearchingNotifier,
            totalMatchesNotifier: totalMatchesNotifier,
            onSearch: (query, matchCase) {
              lastSearchedQuery = query;
              lastMatchCase = matchCase;
            },
            onClear: () {
              lastSearchedQuery = '';
            },
            onSelectMatch: (match, index) {
              selectedMatch = match;
              selectedIndex = index;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initial empty state
    expect(find.text('Type to search the book'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Aa'), findsOneWidget);

    // Enter search text
    await tester.enterText(find.byType(TextField), 'Ishmael');
    // Fast forward past debounce (350ms)
    await tester.pump(const Duration(milliseconds: 400));
    expect(lastSearchedQuery, equals('Ishmael'));
    expect(lastMatchCase, isFalse);

    // Simulate streaming search results arriving from bridge
    isSearchingNotifier.value = true;
    totalMatchesNotifier.value = 1;
    sectionsNotifier.value = [
      const SearchSection(
        label: 'Chapter 1: Loomings',
        subitems: [
          SearchResultItem(
            cfi: 'epubcfi(/6/2!/4/2/10:0)',
            excerpt: SearchExcerpt(
              pre: 'Call me ',
              match: 'Ishmael',
              post: '. Some years ago...',
            ),
          ),
        ],
      ),
    ];
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify chapter header and match count badge
    expect(find.text('Chapter 1: Loomings'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.byType(RichText), findsWidgets);
    final matchFinder = find.descendant(
      of: find.byType(ListView),
      matching: find.text('Ishmael'),
    );
    expect(matchFinder, findsOneWidget);

    // Search finishes
    isSearchingNotifier.value = false;
    await tester.pumpAndSettle();

    // Tap the search result excerpt
    await tester.tap(matchFinder);
    await tester.pumpAndSettle();

    expect(selectedMatch, isNotNull);
    expect(selectedMatch!.cfi, equals('epubcfi(/6/2!/4/2/10:0)'));
    expect(selectedIndex, equals(0));

    // Tap the [Aa] case-sensitivity toggle
    await tester.tap(find.text('Aa'));
    await tester.pumpAndSettle();
    expect(lastMatchCase, isTrue);
  });

  testWidgets('DottedFontSizeStepper snaps and steps without numeric text',
      (WidgetTester tester) async {
    double currentSize = 16.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return DottedFontSizeStepper(
                currentFontSize: currentSize,
                onFontSizeChanged: (newSize) {
                  setState(() {
                    currentSize = newSize;
                  });
                },
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify stepper rendered
    expect(find.byType(DottedFontSizeStepper), findsOneWidget);

    // Verify zero numeric font size labels are displayed
    expect(find.textContaining('pt'), findsNothing);
    expect(find.textContaining('16'), findsNothing);

    // Verify small 'A' and large 'A' buttons
    final smallerFinder = find.widgetWithText(IconButton, 'A').first;
    final largerFinder = find.widgetWithText(IconButton, 'A').last;

    // Tap larger 'A' (16.0 -> 18.0)
    await tester.tap(largerFinder);
    await tester.pumpAndSettle();
    expect(currentSize, equals(18.0));

    // Tap larger 'A' again (18.0 -> 21.0 with new 10pt scale)
    await tester.tap(largerFinder);
    await tester.pumpAndSettle();
    expect(currentSize, equals(21.0));

    // Tap smaller 'A' (21.0 -> 18.0)
    await tester.tap(smallerFinder);
    await tester.pumpAndSettle();
    expect(currentSize, equals(18.0));
  });

  testWidgets('SilkRibbonBookmark renders and triggers toggle',
      (WidgetTester tester) async {
    bool isBookmarked = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Stack(
            children: [
              StatefulBuilder(
                builder: (context, setState) {
                  return SilkRibbonBookmark(
                    isBookmarked: isBookmarked,
                    onToggle: () {
                      setState(() {
                        isBookmarked = !isBookmarked;
                      });
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SilkRibbonBookmark), findsOneWidget);

    // Tap the bookmark ribbon trigger area
    await tester.tap(find.byType(SilkRibbonBookmark));
    await tester.pumpAndSettle();

    expect(isBookmarked, isTrue);

    // Tap again to untoggle
    await tester.tap(find.byType(SilkRibbonBookmark));
    await tester.pumpAndSettle();

    expect(isBookmarked, isFalse);
  });

  testWidgets('ReaderCloseButton renders with X mark and fires callback',
      (WidgetTester tester) async {
    bool closed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Stack(
            children: [
              ReaderCloseButton(
                onClose: () => closed = true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ReaderCloseButton), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.byType(ReaderCloseButton));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
  });

  testWidgets('ReaderProgressIndicator renders and cycles through display types on tap',
      (WidgetTester tester) async {
    ProgressDisplayType currentType = ProgressDisplayType.pagesLeftInChapter;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Stack(
            children: [
              StatefulBuilder(
                builder: (context, setState) {
                  return ReaderProgressIndicator(
                    location: const ReadingLocation(
                      cfi: 'cfi-1',
                      fraction: 0.25,
                      percentage: 25.0,
                      currentLocation: 10,
                      totalLocations: 40,
                      chapterCurrentPage: 2,
                      chapterTotalPages: 7,
                      pagesLeftInChapter: 5,
                      timeLeftSectionSeconds: 360,
                    ),
                    percentage: 25.0,
                    displayType: currentType,
                    displayLocation: ProgressDisplayLocation.bottomCenter,
                    onCycleDisplayType: () {
                      setState(() {
                        currentType = currentType.next();
                      });
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initially: pagesLeftInChapter (5 pages left in chapter)
    expect(find.text('5 pages left in chapter'), findsOneWidget);

    // 2. Tap to cycle -> timeLeftInChapter (360s = 6 min left in chapter)
    await tester.tap(find.byType(ReaderProgressIndicator));
    await tester.pumpAndSettle();
    expect(currentType, equals(ProgressDisplayType.timeLeftInChapter));
    expect(find.text('6 min left in chapter'), findsOneWidget);

    // 3. Tap to cycle -> timeLeftInBook
    await tester.tap(find.byType(ReaderProgressIndicator));
    await tester.pumpAndSettle();
    expect(currentType, equals(ProgressDisplayType.timeLeftInBook));
    expect(find.text('4h 48m left'), findsOneWidget);

    // 4. Tap to cycle -> pageNumber
    await tester.tap(find.byType(ReaderProgressIndicator));
    await tester.pumpAndSettle();
    expect(currentType, equals(ProgressDisplayType.pageNumber));
    expect(find.text('Page 10 of 40'), findsOneWidget);

    // 5. Tap to cycle -> percentage
    await tester.tap(find.byType(ReaderProgressIndicator));
    await tester.pumpAndSettle();
    expect(currentType, equals(ProgressDisplayType.percentage));
    expect(find.text('25%'), findsOneWidget);
  });

  testWidgets('FloatingReaderCapsule renders menu icon and triggers tap',
      (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: FloatingReaderCapsule(
            onTap: () => tapped = true,
            accentColor: const Color(0xFFC6782E),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingReaderCapsule), findsOneWidget);
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

    await tester.tap(find.byType(FloatingReaderCapsule));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('FloatingReaderMenu renders at 60% height and fires onClose on close button tap',
      (WidgetTester tester) async {
    bool closed = false;
    bool layoutOpened = false;
    double? newBrightness;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: FloatingReaderMenu(
            currentFontSize: 16.0,
            onFontSizeChanged: (_) {},
            progressPercentage: 42.0,
            progressLabel: 'Page 12 of 240',
            onScrubPercentage: (_) {},
            onPrevPage: () {},
            onNextPage: () {},
            onClose: () => closed = true,
            onOpenTOC: () {},
            onOpenSearch: () {},
            onOpenLayout: () => layoutOpened = true,
            onOpenAppearance: () {},
            brightness: 0.9,
            onBrightnessChanged: (b) => newBrightness = b,
            isOrientationLocked: false,
            onToggleOrientation: () {},
            progressDisplayType: ProgressDisplayType.pagesLeftInChapter,
            onProgressDisplayTypeChanged: (_) {},
            progressDisplayLocation: ProgressDisplayLocation.bottomCenter,
            onProgressDisplayLocationChanged: (_) {},
            showPageSlider: true,
            onShowPageSliderChanged: (_) {},
            quickActionsBar: true,
            onQuickActionsBarChanged: (_) {},
            currentTheme: ReaderThemeMode.sepia,
            isDarkMode: false,
            onThemeChanged: (theme, dark) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingReaderMenu), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.text('Theme Palette'), findsOneWidget);
    expect(find.text('Calm Sepia'), findsWidgets);
    expect(find.text('Warm Cream'), findsOneWidget);
    expect(find.text('Layout'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Customize Font & Typography'), findsOneWidget);

    // Tap Layout button -> fires onOpenLayout without firing closed
    await tester.tap(find.text('Layout'));
    await tester.pumpAndSettle();
    expect(layoutOpened, isTrue);
    expect(closed, isFalse);

    // Drag brightness slider
    await tester.drag(find.byType(Slider), const Offset(-50, 0));
    await tester.pumpAndSettle();
    expect(newBrightness, isNotNull);

    // Verify vertical scrolling reveals lower themes like Quiet Black
    await tester.scrollUntilVisible(
      find.text('Quiet Black'),
      50.0,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Quiet Black'), findsOneWidget);

    // Verify container height is 60% of screen height (600 * 0.60 = 360)
    final renderBox = tester.renderObject<RenderBox>(find.byType(FloatingReaderMenu));
    expect(renderBox.size.height, closeTo(600 * 0.60, 1.0));

    // Tap Close button
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
  });

  testWidgets('ReaderPageSliderBar renders correctly and invokes navigation callbacks',
      (WidgetTester tester) async {
    bool prevPressed = false;
    bool nextPressed = false;
    double? scrubbed;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Stack(
            children: [
              ReaderPageSliderBar(
                progressPercentage: 50.0,
                onScrubPercentage: (val) => scrubbed = val,
                onPrevPage: () => prevPressed = true,
                onNextPage: () => nextPressed = true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ReaderPageSliderBar), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('Page 100 of 200  •  50%'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    expect(prevPressed, isTrue);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    expect(nextPressed, isTrue);

    await tester.drag(find.byType(Slider), const Offset(40, 0));
    expect(scrubbed, isNotNull);
  });

  testWidgets('ReaderTOCSheet renders inside DraggableScrollableSheet and responds to drags',
      (WidgetTester tester) async {
    String? selectedHref;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: ReaderTOCSheet(
            toc: const [
              TOCItem(label: 'Chapter 1: The Arrival', href: 'ch1.html'),
              TOCItem(label: 'Chapter 2: The Secret', href: 'ch2.html'),
            ],
            bookmarks: const [],
            onChapterSelected: (href) => selectedHref = href,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ReaderTOCSheet), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.text('Contents'), findsOneWidget);
    expect(find.text('Bookmarks (0)'), findsOneWidget);
    expect(find.text('Chapter 1: The Arrival'), findsOneWidget);

    // Verify draggable downwards drag gesture
    await tester.drag(find.byType(DraggableScrollableSheet), const Offset(0, 100));
    await tester.pumpAndSettle();

    // Tap a chapter
    await tester.tap(find.text('Chapter 1: The Arrival'));
    await tester.pumpAndSettle();
    expect(selectedHref, equals('ch1.html'));
  });

  testWidgets('AnnotationsScreen renders empty state when no highlights exist',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AnnotationsScreen(
          annotations: [],
          booksMap: {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No Annotations Yet'), findsOneWidget);
    expect(find.text('Select any text while reading to highlight passages, save personal notes, and export your quotes.'), findsOneWidget);
  });

  testWidgets('AnnotationsScreen renders book groups, filters, and triggers export',
      (WidgetTester tester) async {
    const book1 = Book(
      hash: 'hash-1',
      title: 'A Little Life',
      author: 'Hanya Yanagihara',
      addedAt: 1725458000000,
    );
    const book2 = Book(
      hash: 'hash-2',
      title: 'Dune',
      author: 'Frank Herbert',
      addedAt: 1725458000000,
    );

    final annotations = [
      const Annotation(
        id: 'ann-1',
        bookHash: 'hash-1',
        cfi: 'cfi-1',
        text: 'Things get broken, and sometimes repaired.',
        color: '#FFE066',
        createdAt: 1725458000000,
      ),
      const Annotation(
        id: 'ann-2',
        bookHash: 'hash-1',
        cfi: 'cfi-2',
        text: 'You will not always feel this way.',
        note: 'Comforting note',
        color: '#B8E986',
        createdAt: 1725459000000,
      ),
      const Annotation(
        id: 'ann-3',
        bookHash: 'hash-2',
        cfi: 'cfi-3',
        text: 'Fear is the mind-killer.',
        color: '#80D8FF',
        createdAt: 1725460000000,
      ),
    ];

    Annotation? tappedAnnotation;
    Book? tappedBook;

    await tester.pumpWidget(
      MaterialApp(
        home: AnnotationsScreen(
          annotations: annotations,
          booksMap: {
            'hash-1': book1,
            'hash-2': book2,
          },
          onAnnotationTap: (ann, book) {
            tappedAnnotation = ann;
            tappedBook = book;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify screen title & book accordion headers
    expect(find.text('Annotations'), findsOneWidget);
    expect(find.text('A Little Life'), findsNWidgets(3));
    expect(find.text('Dune'), findsNWidgets(2));
    expect(find.text('Hanya Yanagihara'), findsOneWidget);
    expect(find.text('Frank Herbert'), findsOneWidget);

    // Verify quotes
    expect(find.text('“Things get broken, and sometimes repaired.”'), findsOneWidget);
    expect(find.text('“Fear is the mind-killer.”'), findsOneWidget);
    expect(find.text('Comforting note'), findsOneWidget);

    // Tap on an annotation card -> triggers onAnnotationTap
    await tester.tap(find.text('“Things get broken, and sometimes repaired.”'));
    await tester.pumpAndSettle();
    expect(tappedAnnotation?.id, equals('ann-1'));
    expect(tappedBook?.title, equals('A Little Life'));

    // Filter by Green color
    await tester.tap(find.text('Green'));
    await tester.pumpAndSettle();

    // Now only the green annotation should be visible
    expect(find.text('“You will not always feel this way.”'), findsOneWidget);
    expect(find.text('“Fear is the mind-killer.”'), findsNothing);

    // Reset filter
    await tester.tap(find.text('All (3)'));
    await tester.pumpAndSettle();
    expect(find.text('“Fear is the mind-killer.”'), findsOneWidget);

    // Tap Export button in AppBar
    await tester.tap(find.byIcon(Icons.ios_share_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Export as Markdown (.md)'), findsOneWidget);
    await tester.tap(find.text('Export as Markdown (.md)'));
    await tester.pumpAndSettle();

    // Verify Export preview dialog
    expect(find.text('Export Highlights (Markdown)'), findsOneWidget);
    expect(find.text('Copy to Clipboard'), findsOneWidget);

    // Close preview dialog
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Export Highlights (Markdown)'), findsNothing);
  });
}




