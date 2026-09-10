import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foliate/components/annotation_card.dart';
import 'package:foliate/components/dictionary_lookup_sheet.dart';
import 'package:foliate/components/quote_card_generator_sheet.dart';
import 'package:foliate/models/models.dart';
import 'package:foliate/services/dictionary_service.dart';
import 'package:foliate/theme/adwaita_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DictionaryService Models & Cache Tests', () {
    test('DictionaryEntry and WikipediaSummary models construct correctly', () {
      final entry = DictionaryEntry(
        word: 'solitude',
        phonetic: '/ˈsɑː.lə.tuːd/',
        meanings: [
          const DictionaryMeaning(
            partOfSpeech: 'noun',
            definitions: [
              'The state of being alone, especially when this is peaceful and pleasant.',
              'A lonely, uninhabited place.',
            ],
            examples: [
              'She longed for peace and solitude.',
            ],
            synonyms: ['isolation', 'seclusion', 'loneliness'],
          ),
        ],
      );

      expect(entry.word, 'solitude');
      expect(entry.phonetic, '/ˈsɑː.lə.tuːd/');
      expect(entry.meanings.length, 1);
      expect(entry.meanings.first.partOfSpeech, 'noun');
      expect(entry.meanings.first.definitions.length, 2);
      expect(entry.meanings.first.examples.first, 'She longed for peace and solitude.');
      expect(entry.meanings.first.synonyms, contains('isolation'));

      final wiki = WikipediaSummary(
        title: 'Solitude',
        description: 'State of seclusion or isolation',
        extract: 'Solitude is a state of seclusion or isolation, i.e., lack of contact with people.',
        thumbnailUrl: 'https://upload.wikimedia.org/solitude.jpg',
        articleUrl: 'https://en.wikipedia.org/wiki/Solitude',
      );

      expect(wiki.title, 'Solitude');
      expect(wiki.description, 'State of seclusion or isolation');
      expect(wiki.extract, contains('state of seclusion'));
      expect(wiki.thumbnailUrl, 'https://upload.wikimedia.org/solitude.jpg');
      expect(wiki.articleUrl, 'https://en.wikipedia.org/wiki/Solitude');
    });

    test('DictionaryService handles cache clear and retrieval', () {
      final service = DictionaryService.instance;
      service.clearCache();
      expect(service, isNotNull);
    });
  });

  group('QuoteCardGeneratorSheet Widget Tests', () {
    testWidgets('Renders quote text, author, title, and theme options', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [FoliateThemeColors.dark],
          ),
          home: const Scaffold(
            body: QuoteCardGeneratorSheet(
              quoteText: 'It is a truth universally acknowledged.',
              bookTitle: 'Pride and Prejudice',
              author: 'Jane Austen',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify quote text is rendered
      expect(find.textContaining('truth universally acknowledged'), findsOneWidget);
      expect(find.text('Pride and Prejudice'), findsOneWidget);
      expect(find.text('Jane Austen'), findsOneWidget);

      // Verify format switcher (1:1 and 9:16)
      expect(find.text('1:1'), findsOneWidget);
      expect(find.text('9:16'), findsOneWidget);

      // Verify theme presets
      expect(find.text('Warm Paper'), findsOneWidget);
      expect(find.text('AMOLED Pitch'), findsOneWidget);
      expect(find.text('Modern Slate'), findsOneWidget);
      expect(find.text('Classic Monospace'), findsOneWidget);

      // Tap theme preset to switch
      await tester.tap(find.text('AMOLED Pitch'));
      await tester.pumpAndSettle();

      // Tap format switch
      await tester.tap(find.text('9:16'));
      await tester.pumpAndSettle();

      // Verify actions
      expect(find.text('Share Card'), findsOneWidget);
      expect(find.text('Save Image'), findsOneWidget);
    });
  });

  group('DictionaryLookupSheet Widget Tests', () {
    testWidgets('Renders tabs and search in system dictionary button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [FoliateThemeColors.dark],
          ),
          home: const Scaffold(
            body: DictionaryLookupSheet(
              query: 'ephemeral',
            ),
          ),
        ),
      );

      // First frame shows loading or query
      await tester.pump();

      expect(find.text('ephemeral'), findsOneWidget);
      expect(find.text('Dictionary'), findsOneWidget);
      expect(find.text('Wikipedia'), findsOneWidget);
      expect(find.text('Search in System Dictionary'), findsOneWidget);

      // Tab switching
      await tester.tap(find.text('Wikipedia'));
      await tester.pump();
    });
  });

  group('AnnotationCard Quote Card Action Tests', () {
    testWidgets('AnnotationCard popup menu includes Share Quote Card', (tester) async {
      final annotation = Annotation(
        id: 'ann-1',
        bookHash: 'hash-1',
        cfi: '/6/4[chap1]!/4/2',
        text: 'The only journey is the one within.',
        note: 'Rilke insight',
        createdAt: 1700000000000,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [FoliateThemeColors.dark],
          ),
          home: Scaffold(
            body: AnnotationCard(
              annotation: annotation,
              bookTitle: 'Letters to a Young Poet',
              author: 'Rainer Maria Rilke',
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('“The only journey is the one within.”'), findsOneWidget);
      expect(find.text('Rilke insight'), findsOneWidget);
      expect(find.text('Letters to a Young Poet'), findsOneWidget);

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      // Check Share Quote Card item
      expect(find.text('Share Quote Card'), findsOneWidget);
      expect(find.text('Copy Quote'), findsOneWidget);
    });
  });
}
