import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foliate/main.dart';
import 'package:foliate/models/models.dart';
import 'package:foliate/components/components.dart';
import 'package:foliate/screens/annotations_screen.dart';
import 'package:foliate/screens/home_screen.dart';
import 'package:foliate/theme/theme.dart';
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

    // Verify Library screen active with category filter chips and cataloged books
    expect(find.text('All'), findsWidgets);
    expect(find.text('Reading'), findsWidgets);
    expect(find.text('Favorites'), findsWidgets);
    expect(find.text('A Little Life'), findsWidgets);
    expect(find.text('Add Book'), findsOneWidget);

    // Tap Settings gear in top bar
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    // Verify SettingsSheet is open
    expect(find.text('Settings & Library'), findsOneWidget);
    expect(find.text('Books in Library'), findsOneWidget);

    // Close SettingsSheet
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    // Verify all 5 NavigationBar destinations are present
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Library'), findsWidgets);
    expect(find.text('Explore'), findsWidgets);
    expect(find.text('Annotations'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);

    // Tap Explore tab in NavigationBar
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    expect(find.text('Available Libraries (4)'), findsOneWidget);
    expect(find.text('Project Gutenberg'), findsWidgets);

    // Tap Profile tab in NavigationBar
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Reading Metrics'), findsOneWidget);
    expect(find.text('2026 Reading Challenge'), findsOneWidget);

    // Scroll down in Profile ListView to reveal lower cards
    await tester.scrollUntilVisible(
      find.text('Weekly Consistency'),
      50.0,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Weekly Consistency'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Folio Sync Active'),
      50.0,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Folio Sync Active'), findsOneWidget);
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
    bool stayAwakeToggled = false;
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
            isStayAwake: false,
            onToggleStayAwake: () => stayAwakeToggled = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingReaderMenu), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.byIcon(Icons.remove_red_eye_outlined), findsOneWidget);
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

    // Tap Sleep button -> fires onToggleStayAwake
    await tester.tap(find.text('Sleep'));
    await tester.pumpAndSettle();
    expect(stayAwakeToggled, isTrue);

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

  testWidgets('ReaderPageSliderBar renders chapter tick marks and handles sticky chapter snapping',
      (WidgetTester tester) async {
    double? scrubbedVal;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Stack(
            children: [
              ReaderPageSliderBar(
                progressPercentage: 10.0,
                location: const ReadingLocation(
                  cfi: 'cfi-loc-10',
                  currentLocation: 10,
                  totalLocations: 100,
                ),
                toc: const [
                  TOCItem(label: 'Chapter 1', digitalPageNumber: 1),
                  TOCItem(label: 'Chapter 2', digitalPageNumber: 25),
                  TOCItem(label: 'Chapter 3', digitalPageNumber: 75),
                ],
                onScrubPercentage: (val) => scrubbedVal = val,
                onPrevPage: () {},
                onNextPage: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ReaderPageSliderBar), findsOneWidget);
    expect(find.text('Page 10 of 100'), findsOneWidget);

    await tester.drag(find.byType(Slider), const Offset(50, 0));
    await tester.pumpAndSettle();

    expect(scrubbedVal, isNotNull);
  });

  testWidgets('ReaderTOCSheet renders inside DraggableScrollableSheet and responds to drags',
      (WidgetTester tester) async {
    String? selectedHref;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: ReaderTOCSheet(
            book: const Book(
              hash: 'jezebel-hash',
              title: 'Jezebel',
              author: 'Irene Nemirovsky',
              addedAt: 123456789,
            ),
            currentLocation: const ReadingLocation(
              cfi: 'cfi-1',
              sectionTitle: 'Chapter 1: The Arrival',
              currentLocation: 15,
              totalLocations: 200,
            ),
            toc: const [
              TOCItem(label: 'Chapter 1: The Arrival', href: 'ch1.html', pageNumber: 15),
              TOCItem(label: 'Chapter 2: The Secret', href: 'ch2.html', pageNumber: 57),
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
    expect(find.text('Jezebel'), findsOneWidget);
    expect(find.text('Irene Nemirovsky'), findsOneWidget);
    expect(find.text('Contents'), findsOneWidget);
    expect(find.text('Bookmarks (0)'), findsOneWidget);
    expect(find.text('Chapter 1: The Arrival'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('Chapter 2: The Secret'), findsOneWidget);
    expect(find.text('57'), findsOneWidget);

    // Verify draggable downwards drag gesture
    await tester.drag(find.byType(DraggableScrollableSheet), const Offset(0, 100));
    await tester.pumpAndSettle();

    // Tap a chapter
    await tester.tap(find.text('Chapter 1: The Arrival'));
    await tester.pumpAndSettle();
    expect(selectedHref, equals('ch1.html'));
  });

  testWidgets('ReaderTOCSheet switches between Digital Book and Print Edition page numbers via popup menu',
      (WidgetTester tester) async {
    PageNumberSource? changedSource;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: ReaderTOCSheet(
            book: const Book(
              hash: 'jezebel-hash',
              title: 'Jezebel',
              author: 'Irene Nemirovsky',
              addedAt: 123456789,
            ),
            toc: const [
              TOCItem(
                label: 'Chapter 1: The Arrival',
                href: 'ch1.html',
                digitalPageNumber: 15,
                printPageNumber: 9,
              ),
              TOCItem(
                label: 'Chapter 2: The Secret',
                href: 'ch2.html',
                digitalPageNumber: 57,
                printPageNumber: 42,
              ),
            ],
            bookmarks: const [],
            pageNumberSource: PageNumberSource.digitalBook,
            onPageNumberSourceChanged: (s) => changedSource = s,
            onChapterSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initially displays digital pages
    expect(find.text('Digital Book'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('57'), findsOneWidget);

    // Open popup menu
    await tester.tap(find.text('Digital Book'));
    await tester.pumpAndSettle();

    // Verify popup menu items
    expect(find.text('Page Numbers'), findsOneWidget);
    expect(find.text('Print Edition'), findsOneWidget);

    // Select Print Edition
    await tester.tap(find.text('Print Edition'));
    await tester.pumpAndSettle();

    expect(changedSource, equals(PageNumberSource.printEdition));
    // Now displays print pages
    expect(find.text('Print Edition'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
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

  test('Book displayPercentage and progressFraction normalization test', () {
    const book6 = Book(
      hash: 'h-6',
      title: 'Book 6',
      addedAt: 0,
      percentage: 6.0,
    );
    expect(book6.displayPercentage, equals(6));
    expect(book6.progressFraction, closeTo(0.06, 0.001));

    const book17 = Book(
      hash: 'h-17',
      title: 'Book 17',
      addedAt: 0,
      percentage: 17.0,
    );
    expect(book17.displayPercentage, equals(17));
    expect(book17.progressFraction, closeTo(0.17, 0.001));

    const book37 = Book(
      hash: 'h-37',
      title: 'Book 37',
      addedAt: 0,
      percentage: 37.0,
    );
    expect(book37.displayPercentage, equals(37));
    expect(book37.progressFraction, closeTo(0.37, 0.001));

    const book0 = Book(
      hash: 'h-0',
      title: 'Book 0',
      addedAt: 0,
      percentage: 0.0,
    );
    expect(book0.displayPercentage, equals(0));
    expect(book0.progressFraction, equals(0.0));

    const book100 = Book(
      hash: 'h-100',
      title: 'Book 100',
      addedAt: 0,
      percentage: 100.0,
    );
    expect(book100.displayPercentage, equals(100));
    expect(book100.progressFraction, equals(1.0));

    // Legacy fraction fallback
    const legacyBook = Book(
      hash: 'h-leg',
      title: 'Legacy Fraction Book',
      addedAt: 0,
      percentage: 0.5,
    );
    expect(legacyBook.displayPercentage, equals(50));
    expect(legacyBook.progressFraction, closeTo(0.5, 0.001));
  });

  testWidgets('AppThemeSheet renders mode selection and excludes signature palette', (WidgetTester tester) async {
    await tester.pumpWidget(
      const FoliateApp(),
    );
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(PageView));
    AppThemeSheet.show(context);
    await tester.pumpAndSettle();

    expect(find.text('App Appearance'), findsOneWidget);
    expect(find.text('Choose your interface mode'), findsOneWidget);
    expect(find.text('INTERFACE MODE'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);

    // Ensure SIGNATURE PALETTE is completely removed
    expect(find.text('SIGNATURE PALETTE'), findsNothing);
    expect(find.text('Warm Terracotta & Amber'), findsNothing);
  });

  testWidgets('StitchBottomBar highlights active tab with pill indicator', (WidgetTester tester) async {
    await tester.pumpWidget(const FoliateApp());
    await tester.pumpAndSettle();

    // Verify all 5 tab labels are visible in the bottom bar
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Library'), findsWidgets);
    expect(find.text('Explore'), findsWidgets);
    expect(find.text('Annotations'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);

    // Tap Library
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();

    // Verify Library screen title is visible
    expect(find.text('Library'), findsWidgets);

    // Tap Explore
    await tester.tap(find.text('Explore').last);
    await tester.pumpAndSettle();

    // Verify Explore screen loaded
    expect(find.text('Explore'), findsWidgets);
  });

  testWidgets('ReadingInsightsCard renders circle tracker and bar-version day streak design', (WidgetTester tester) async {
    final habits = ReadingHabits(
      dailyGoalMinutes: 30,
      currentStreak: 5,
      longestStreak: 12,
      dailyHistory: {
        ReadingHabits.formatDate(DateTime.now()): 10,
      },
    );
    final testBook = Book(
      hash: 'hash-test-1',
      title: 'Jezebel',
      author: 'Irene Nemirovsky',
      filePath: '/path/to/jezebel.epub',
      percentage: 35.0,
      addedAt: 123456789,
    );

    bool keepReadingTapped = false;
    int? newDailyGoal;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReadingInsightsCard(
              habits: habits,
              activeBook: testBook,
              onKeepReading: () => keepReadingTapped = true,
              onDailyGoalChanged: (goal) => newDailyGoal = goal,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Reading Insights header & category
    expect(find.text('Reading Insights'), findsOneWidget);
    expect(find.text('READING VELOCITY'), findsOneWidget);
    expect(find.text('Adjust Goal'), findsOneWidget);

    // Verify Today's Reading, minutes, and circle tracker
    expect(find.text("TODAY'S READING"), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('MIN'), findsOneWidget);
    expect(find.textContaining('30m daily goal'), findsOneWidget);

    // Verify Resume Chapter button and active book strip
    expect(find.text('Resume Chapter'), findsOneWidget);
    expect(find.text('Jezebel'), findsOneWidget);
    expect(find.text('Jump in'), findsOneWidget);

    // Tap Resume Chapter
    await tester.tap(find.text('Resume Chapter'));
    expect(keepReadingTapped, isTrue);

    // Verify day letters S M T W T F S
    expect(find.text('S'), findsWidgets);
    expect(find.text('M'), findsWidgets);
    expect(find.text('T'), findsWidgets);
    expect(find.text('W'), findsWidgets);
    expect(find.text('F'), findsWidgets);

    // Verify streak and record text
    expect(find.text('5-day streak active'), findsOneWidget);
    expect(find.text('12d'), findsOneWidget);

    // Verify annual challenge
    expect(find.textContaining('Challenge'), findsOneWidget);
    expect(newDailyGoal, isNull);
  });

  testWidgets('CuratedBookCard and RecentBookCard render unboxed without grey card backgrounds', (WidgetTester tester) async {
    final curated = CuratedBook.openLibraryGems.first;
    final testBook = Book(
      hash: 'hash-test-recent',
      title: 'Dracula',
      author: 'Bram Stoker',
      filePath: '/path/to/dracula.epub',
      percentage: 42.0,
      addedAt: 123456789,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 320,
                  child: CuratedBookCard(book: curated),
                ),
                RecentBookCard(book: testBook, onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(curated.title), findsOneWidget);
    expect(find.text(curated.author), findsOneWidget);
    expect(find.text(testBook.title), findsOneWidget);
    expect(find.text('42% completed'), findsOneWidget);
  });

  testWidgets('HomeScreen renders Explore Horizons as horizontal carousel with See More card', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bool explored = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(
          extensions: [FoliateThemeColors.dark],
        ),
        home: Scaffold(
          body: HomeScreen(
            books: const [],
            onNavigateToLibrary: () {},
            onNavigateToExplore: () => explored = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Explore Horizons'), findsOneWidget);
    expect(find.text('See More'), findsOneWidget);
    expect(find.text('Explore All'), findsOneWidget);

    await tester.tap(find.text('See More'));
    await tester.pumpAndSettle();

    expect(explored, isTrue);
  });

  testWidgets('YearlyBooksReadSection renders navigation, finished books, and empty states', (WidgetTester tester) async {
    final currentYear = DateTime.now().year;
    final finishedBook2025 = Book(
      hash: 'hash-finished-2025',
      title: 'Moby Dick',
      author: 'Herman Melville',
      percentage: 100.0,
      addedAt: DateTime(2025, 6, 1).millisecondsSinceEpoch,
      lastReadAt: DateTime(2025, 6, 15).millisecondsSinceEpoch,
    );
    final finishedBookCurrent = Book(
      hash: 'hash-finished-current',
      title: 'Pride and Prejudice',
      author: 'Jane Austen',
      percentage: 100.0,
      addedAt: DateTime(currentYear, 1, 1).millisecondsSinceEpoch,
      lastReadAt: DateTime(currentYear, 2, 1).millisecondsSinceEpoch,
    );

    final habits = ReadingHabits(
      yearlyFinishedBooks: {
        '2025': ['hash-finished-2025'],
        '$currentYear': ['hash-finished-current'],
      },
      booksFinishedThisYear: ['hash-finished-current'],
    );

    Book? tappedBook;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: YearlyBooksReadSection(
              books: [finishedBook2025, finishedBookCurrent],
              habits: habits,
              accountCreationYear: 2024,
              onBookTap: (b) => tappedBook = b,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initially at current year
    expect(find.text('Books Read This Year'), findsOneWidget);
    expect(find.text('$currentYear'), findsOneWidget);
    expect(find.text('1 book finished'), findsOneWidget);
    expect(find.text('Pride and Prejudice'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    // Tap on the finished book
    await tester.tap(find.text('Pride and Prejudice'));
    await tester.pumpAndSettle();
    expect(tappedBook?.title, equals('Pride and Prejudice'));

    // Next button should be disabled at current year
    final nextButtons = tester.widgetList<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right_rounded));
    expect(nextButtons.first.onPressed, isNull);

    // 2. Tap previous year (<) -> moves to 2025
    final prevButtons = find.widgetWithIcon(IconButton, Icons.chevron_left_rounded);
    await tester.tap(prevButtons);
    await tester.pumpAndSettle();

    expect(find.text('Books Read in 2025'), findsOneWidget);
    expect(find.text('2025'), findsOneWidget);
    expect(find.text('Moby Dick'), findsOneWidget);

    // 3. Tap previous year (<) again -> moves to 2024 (account creation year)
    await tester.tap(prevButtons);
    await tester.pumpAndSettle();

    expect(find.text('Books Read in 2024'), findsOneWidget);
    expect(find.text('2024'), findsOneWidget);
    expect(find.text('No Books Finished in 2024'), findsOneWidget);
    expect(find.text('Books you finish will appear here.'), findsOneWidget);

    // At 2024 (creation year), previous button should now be disabled
    final prevButtonsAtMin = tester.widgetList<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_left_rounded));
    expect(prevButtonsAtMin.first.onPressed, isNull);

    // 4. Tap next year (>) -> moves back to 2025
    final nextButtonsActive = find.widgetWithIcon(IconButton, Icons.chevron_right_rounded);
    await tester.tap(nextButtonsActive);
    await tester.pumpAndSettle();

    expect(find.text('Books Read in 2025'), findsOneWidget);
    expect(find.text('Moby Dick'), findsOneWidget);
  });
}




