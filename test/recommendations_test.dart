import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foliate/components/components.dart';
import 'package:foliate/models/models.dart';
import 'package:foliate/screens/screens.dart';
import 'package:foliate/services/services.dart';
import 'package:foliate/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('foliate_rec_test_');
    StorageService.instance.setAppDocDirForTesting(tempDir);
  });

  tearDown(() {
    StorageService.instance.setAppDocDirForTesting(null);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('ReadingNiche model tests', () {
    test('Standard niches catalog contains 12 distinct niches', () {
      expect(ReadingNiche.allNiches.length, 12);
      final ids = ReadingNiche.allNiches.map((n) => n.id).toSet();
      expect(ids.length, 12);
    });

    test('findById locates niches case-insensitively', () {
      final philosophy = ReadingNiche.findById('philosophy');
      expect(philosophy, isNotNull);
      expect(philosophy!.shortLabel, 'Philosophy');
      expect(philosophy.openLibrarySubject, 'philosophy');

      final scifi = ReadingNiche.findById('SCIFI');
      expect(scifi, isNotNull);
      expect(scifi!.shortLabel, 'Sci-Fi');

      expect(ReadingNiche.findById('non_existent_id'), isNull);
    });

    test('findByName locates niches by label, short label or keyword', () {
      final gothic = ReadingNiche.findByName('Gothic Mystery');
      expect(gothic, isNotNull);
      expect(gothic!.id, 'gothic');

      final cyber = ReadingNiche.findByName('hacker');
      expect(cyber, isNotNull);
      expect(cyber!.id, 'cyberpunk');

      final poetry = ReadingNiche.findByName('Poetry & Lyrical Verse');
      expect(poetry, isNotNull);
      expect(poetry!.id, 'poetry');
    });

    test('defaultNicheIds contains expected starting niches', () {
      expect(ReadingNiche.defaultNicheIds, contains('philosophy'));
      expect(ReadingNiche.defaultNicheIds, contains('classics'));
      expect(ReadingNiche.defaultNicheIds, contains('scifi'));
      expect(ReadingNiche.defaultNicheIds, contains('gothic'));
    });
  });

  group('StorageService favorite niches persistence', () {
    test('Returns default niches when none saved', () async {
      final niches = await StorageService.instance.getFavoriteNiches();
      expect(niches, equals(ReadingNiche.defaultNicheIds));
    });

    test('Persists and retrieves user-customized favorite niches', () async {
      final custom = ['cyberpunk', 'fantasy', 'adventure'];
      await StorageService.instance.setFavoriteNiches(custom);

      final retrieved = await StorageService.instance.getFavoriteNiches();
      expect(retrieved, equals(custom));
    });
  });

  group('RecommendationService ranking & filtering tests', () {
    test('Prioritizes books matching user favorite niches', () {
      final service = RecommendationService.instance;
      final recommendations = service.getPersonalizedRecommendations(
        favoriteNiches: ['cyberpunk'],
        localBooks: const [],
      );

      expect(recommendations.isNotEmpty, isTrue);
      // Cyberpunk book (1984 or Brave New World) should be ranked at or near the top
      final topBooks = recommendations.take(3).toList();
      final hasCyberpunkInTop = topBooks.any((b) => b.nicheId == 'cyberpunk');
      expect(hasCyberpunkInTop, isTrue);
    });

    test('Boosts score for books by favorite local authors', () {
      final service = RecommendationService.instance;
      final localFavoriteBook = Book(
        hash: 'hash-mary-shelley',
        title: 'The Last Man',
        author: 'Mary Shelley',
        isFavorite: true,
        addedAt: DateTime.now().millisecondsSinceEpoch,
      );

      final recommendations = service.getPersonalizedRecommendations(
        favoriteNiches: const [],
        localBooks: [localFavoriteBook],
      );

      // Frankenstein by Mary Shelley should receive a substantial author bonus
      final topBook = recommendations.first;
      expect(topBook.author, 'Mary Shelley');
      expect(topBook.title, 'Frankenstein');
    });

    test('Filters strictly when a specific niche is selected', () {
      final service = RecommendationService.instance;
      final filtered = service.getPersonalizedRecommendations(
        favoriteNiches: ['philosophy', 'scifi'],
        localBooks: const [],
        selectedFilter: 'Philosophy',
      );

      expect(filtered.isNotEmpty, isTrue);
      for (final book in filtered) {
        expect(
          book.nicheId == 'philosophy' ||
              book.genre.toLowerCase().contains('philosophy'),
          isTrue,
        );
      }
    });

    test('Returns full curated recommendations when filter is All or For You', () {
      final service = RecommendationService.instance;
      final forYou = service.getPersonalizedRecommendations(
        favoriteNiches: ['scifi'],
        localBooks: const [],
        selectedFilter: 'For You',
      );
      final all = service.getPersonalizedRecommendations(
        favoriteNiches: ['scifi'],
        localBooks: const [],
        selectedFilter: 'All',
      );

      expect(forYou.length, equals(all.length));
      expect(forYou.length, greaterThanOrEqualTo(10));
    });
  });

  group('NicheSelectorSheet widget tests', () {
    testWidgets('Renders all niches, allows toggling and resetting', (
      WidgetTester tester,
    ) async {
      List<String>? savedNiches;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [FoliateThemeColors.dark],
          ),
          home: Scaffold(
            body: NicheSelectorSheet(
              initialSelectedNiches: const ['philosophy', 'scifi'],
              onSaved: (n) => savedNiches = n,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reading Tastes & Niches'), findsOneWidget);
      expect(find.text('Select All (12)'), findsOneWidget);
      expect(find.text('Default Niches'), findsOneWidget);
      expect(find.text('Apply Tastes'), findsOneWidget);
      expect(find.text('2 niches selected'), findsOneWidget);

      // Select All
      await tester.tap(find.text('Select All (12)'));
      await tester.pumpAndSettle();
      expect(find.text('12 niches selected'), findsOneWidget);

      // Default Niches
      await tester.tap(find.text('Default Niches'));
      await tester.pumpAndSettle();
      expect(find.text('4 niches selected'), findsOneWidget);

      // Tap Apply Tastes
      await tester.tap(find.text('Apply Tastes'));
      await tester.pumpAndSettle();

      expect(savedNiches, isNotNull);
      expect(savedNiches!.length, 4);
    });
  });

  group('HomeScreen & ProfileScreen personalization integration', () {
    testWidgets('HomeScreen renders Customize action and Edit Niches chip', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [FoliateThemeColors.dark],
          ),
          home: Scaffold(
            body: HomeScreen(
              books: const [],
              onNavigateToLibrary: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Explore Horizons'), findsOneWidget);
      expect(find.text('Customize'), findsOneWidget);
      expect(find.text('Edit Niches'), findsOneWidget);

      // Tapping Customize opens NicheSelectorSheet
      await tester.tap(find.text('Customize'));
      await tester.pumpAndSettle();

      expect(find.text('Reading Tastes & Niches'), findsOneWidget);
    });

    testWidgets('ProfileScreen renders Reading Tastes & Niches preference tile', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [FoliateThemeColors.dark],
          ),
          home: const Scaffold(
            body: ProfileScreen(
              books: [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reading Tastes & Niches'), findsOneWidget);

      // Tapping tile opens NicheSelectorSheet
      await tester.tap(find.text('Reading Tastes & Niches'));
      await tester.pumpAndSettle();

      expect(find.text('Apply Tastes'), findsOneWidget);
    });
  });
}
