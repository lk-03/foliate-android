import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foliate/main.dart';
import 'package:foliate/models/models.dart';
import 'package:foliate/components/components.dart';
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


  testWidgets('ReaderAppearanceSheet tabs and controls test', (WidgetTester tester) async {
    ReaderSettings currentSettings = const ReaderSettings();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: ReaderAppearanceSheet(
            settings: currentSettings,
            onSettingsChanged: (newVal) => currentSettings = newVal,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Font Tab (default)
    expect(find.text('Font'), findsOneWidget);
    expect(find.text('Layout'), findsOneWidget);
    expect(find.text('Color'), findsOneWidget);
    expect(find.text('Behavior'), findsOneWidget);
    expect(find.byType(DottedFontSizeStepper), findsOneWidget);
    expect(find.text('Serif (Noto)'), findsOneWidget);
    expect(find.text('Override Publisher Font'), findsOneWidget);

    // 2. Switch to Layout Tab
    await tester.tap(find.text('Layout'));
    await tester.pumpAndSettle();
    expect(find.text('Line Height'), findsOneWidget);
    expect(find.text('Full Justification'), findsOneWidget);
    expect(find.text('Hyphenation'), findsOneWidget);
    expect(find.text('Continuous Scrolled Mode'), findsOneWidget);

    // 3. Switch to Color Tab
    await tester.tap(find.text('Color'));
    await tester.pumpAndSettle();
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('Light Mode'), findsOneWidget);
    expect(find.text('Gruvbox'), findsOneWidget);
    expect(find.text('Nord'), findsOneWidget);
    expect(find.text('Sepia'), findsOneWidget);
    expect(find.text('Grass'), findsOneWidget);
    expect(find.text('Cherry'), findsOneWidget);
    expect(find.text('Solarized'), findsOneWidget);

    // 4. Switch to Behavior Tab
    await tester.tap(find.text('Behavior'));
    await tester.pumpAndSettle();
    expect(find.text('Reduce Animation'), findsOneWidget);
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

    // 1. Initially: pagesLeftInChapter (40 - 10 = 30)
    expect(find.text('30 pages left in chapter'), findsOneWidget);

    // 2. Tap to cycle -> timeLeftInChapter
    await tester.tap(find.byType(ReaderProgressIndicator));
    await tester.pumpAndSettle();
    expect(currentType, equals(ProgressDisplayType.timeLeftInChapter));
    expect(find.text('36 min left in chapter'), findsOneWidget);

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

  testWidgets('FloatingReaderCapsule renders three-dot icon and triggers tap',
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
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);

    await tester.tap(find.byType(FloatingReaderCapsule));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('FloatingReaderMenu renders at 60% height and fires onClose on close button tap',
      (WidgetTester tester) async {
    bool closed = false;

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
            onOpenAppearance: () {},
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
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingReaderMenu), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

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

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    expect(prevPressed, isTrue);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    expect(nextPressed, isTrue);

    await tester.drag(find.byType(Slider), const Offset(40, 0));
    expect(scrubbed, isNotNull);
  });
}




