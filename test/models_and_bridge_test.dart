import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:foliate/models/models.dart';
import 'package:foliate/reader/reader.dart';
import 'package:foliate/services/services.dart';
import 'package:foliate/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Domain Models Serialization Tests', () {
    test('Book model serialization round-trip', () {
      const book = Book(
        hash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        title: 'A Little Life',
        author: 'Hanya Yanagihara',
        percentage: 1.0,
        cfi: 'epubcfi(/6/10!/4/2/2)',
        addedAt: 1725450000000,
        isFavorite: true,
        isPinned: true,
      );

      final jsonString = book.toJson();
      final restored = Book.fromJson(jsonString);

      expect(restored.hash, equals(book.hash));
      expect(restored.title, equals(book.title));
      expect(restored.author, equals(book.author));
      expect(restored.percentage, equals(book.percentage));
      expect(restored.cfi, equals(book.cfi));
      expect(restored.isFavorite, isTrue);
      expect(restored.isPinned, isTrue);
    });

    test('Annotation model serialization round-trip', () {
      const annotation = Annotation(
        id: 'ann-123',
        bookHash: 'hash-abc',
        cfi: 'epubcfi(/6/10!/4/2/4)',
        text: 'JB was going through, as he put it, his hair phase.',
        note: 'Memorable character introduction',
        color: Annotation.colorYellow,
        createdAt: 1725451000000,
      );

      final jsonString = annotation.toJson();
      final restored = Annotation.fromJson(jsonString);

      expect(restored.id, equals(annotation.id));
      expect(restored.bookHash, equals(annotation.bookHash));
      expect(restored.cfi, equals(annotation.cfi));
      expect(restored.text, equals(annotation.text));
      expect(restored.note, equals(annotation.note));
      expect(restored.color, equals(Annotation.colorYellow));
    });

    test('ReaderSettings model serialization round-trip', () {
      const settings = ReaderSettings(
        theme: ReaderThemeMode.gruvbox,
        isDarkMode: true,
        fontSize: 18.0,
        minFontSize: 12.0,
        fontFamily: 'serif',
        overridePublisherFont: true,
        lineHeight: 1.6,
        fullJustification: true,
        hyphenation: true,
        margin: 0.08,
        fontWeight: 500,
        pageFlipping: 'vertical',
        textAlign: 'justify',
        pageMargins: true,
        twoPagesLandscape: false,
        reduceAnimation: true,
        invertColors: false,
      );

      final jsonString = settings.toJson();
      final restored = ReaderSettings.fromJson(jsonString);

      expect(restored.theme, equals(ReaderThemeMode.gruvbox));
      expect(restored.isDarkMode, isTrue);
      expect(restored.fontSize, equals(18.0));
      expect(restored.minFontSize, equals(12.0));
      expect(restored.fontFamily, equals('serif'));
      expect(restored.overridePublisherFont, isTrue);
      expect(restored.lineHeight, equals(1.6));
      expect(restored.fullJustification, isTrue);
      expect(restored.hyphenation, isTrue);
      expect(restored.margin, equals(0.08));
      expect(restored.fontWeight, equals(500));
      expect(restored.pageFlipping, equals('vertical'));
      expect(restored.textAlign, equals('justify'));
      expect(restored.reduceAnimation, isTrue);
      expect(restored.invertColors, isFalse);

      // Verify all 9 themes can be deserialized
      for (final mode in [
        'default', 'gray', 'sepia', 'grass', 'cherry', 'sky', 'solarized', 'gruvbox', 'nord'
      ]) {
        expect(ReaderThemeMode.fromString(mode).name, isNotEmpty);
      }
    });

    test('ReadingLocation formatting and calculations', () {
      const loc = ReadingLocation(
        cfi: 'epubcfi(/6/10!/4/2/2)',
        fraction: 0.05,
        percentage: 5.0,
        currentLocation: 11,
        totalLocations: 1206,
        currentSection: 5,
        totalSections: 57,
        timeLeftSectionSeconds: 1260, // 21 mins
        timeLeftBookSeconds: 67320, // 18.7 hrs
      );

      expect(loc.formattedTimeLeftSection, equals('21 mins'));
      expect(loc.formattedTimeLeftBook, equals('18.7 hrs'));
      expect(loc.percentage, equals(5.0));
      expect(loc.currentLocation, equals(11));
      expect(loc.totalLocations, equals(1206));
    });

    test('TOCItem hierarchy serialization round-trip', () {
      const toc = TOCItem(
        label: 'Part I: Lispenard Street',
        href: 'part1.html',
        depth: 0,
        subitems: [
          TOCItem(label: 'Chapter 1', href: 'chap1.html', depth: 1),
          TOCItem(label: 'Chapter 2', href: 'chap2.html', depth: 1),
        ],
      );

      final jsonString = toc.toJson();
      final restored = TOCItem.fromJson(jsonString);

      expect(restored.label, equals(toc.label));
      expect(restored.subitems.length, equals(2));
      expect(restored.subitems[0].label, equals('Chapter 1'));
      expect(restored.subitems[1].label, equals('Chapter 2'));
    });

    test('Catalog model serialization and default catalogs', () {
      expect(Catalog.defaultCatalogs.length, equals(4));
      final catalog = Catalog.defaultCatalogs.first;
      expect(catalog.name, equals('Project Gutenberg'));

      final json = catalog.toJson();
      final restored = Catalog.fromJson(json);

      expect(restored.id, equals(catalog.id));
      expect(restored.name, equals(catalog.name));
      expect(restored.url, equals(catalog.url));
      expect(restored.tag, equals(catalog.tag));
      expect(restored.isCustom, isFalse);
    });
  });

  group('ReaderBridge IPC Dispatcher Tests', () {
    test('Dispatches WEBVIEW_READY event', () {
      final bridge = ReaderBridge();
      bool readyCalled = false;
      bridge.onReady = () => readyCalled = true;

      bridge.handleMessage(json.encode({'type': 'WEBVIEW_READY'}));
      expect(readyCalled, isTrue);
      expect(bridge.isReady, isTrue);
    });

    test('Dispatches RELOCATE event with parsed ReadingLocation', () {
      final bridge = ReaderBridge();
      ReadingLocation? receivedLoc;
      bridge.onRelocate = (loc) => receivedLoc = loc;

      bridge.handleMessage(json.encode({
        'type': 'RELOCATE',
        'payload': {
          'cfi': 'epubcfi(/6/4[chap01]!/4/2/1)',
          'fraction': 0.15,
          'percentage': 15.0,
          'section': 2,
          'totalSections': 20,
          'location': {'current': 45, 'total': 300},
        },
      }));

      expect(receivedLoc, isNotNull);
      expect(receivedLoc!.cfi, equals('epubcfi(/6/4[chap01]!/4/2/1)'));
      expect(receivedLoc!.fraction, equals(0.15));
      expect(receivedLoc!.percentage, equals(15.0));
      expect(receivedLoc!.currentLocation, equals(45));
      expect(receivedLoc!.totalLocations, equals(300));
    });

    test('Dispatches TOC_READY event', () {
      final bridge = ReaderBridge();
      List<TOCItem>? receivedTOC;
      bridge.onTOCReady = (toc) => receivedTOC = toc;

      bridge.handleMessage(json.encode({
        'type': 'TOC_READY',
        'payload': [
          {'label': 'Introduction', 'href': 'intro.xhtml'},
          {
            'label': 'Chapter 1',
            'href': 'c1.xhtml',
            'subitems': [
              {'label': 'Section 1.1', 'href': 'c1_s1.xhtml'}
            ]
          }
        ],
      }));

      expect(receivedTOC, isNotNull);
      expect(receivedTOC!.length, equals(2));
      expect(receivedTOC![0].label, equals('Introduction'));
      expect(receivedTOC![1].subitems.length, equals(1));
      expect(receivedTOC![1].subitems[0].label, equals('Section 1.1'));
    });

    test('Dispatches TEXT_SELECTED event', () {
      final bridge = ReaderBridge();
      String? selectedText;
      String? selectedCfi;
      bridge.onTextSelected = (text, cfi) {
        selectedText = text;
        selectedCfi = cfi;
      };

      bridge.handleMessage(json.encode({
        'type': 'TEXT_SELECTED',
        'payload': {
          'text': 'A quote to highlight',
          'cfi': 'epubcfi(/6/4!/4/2/8)',
        },
      }));

      expect(selectedText, equals('A quote to highlight'));
      expect(selectedCfi, equals('epubcfi(/6/4!/4/2/8)'));
    });

    test('Dispatches TTS_TEXT event', () {
      final bridge = ReaderBridge();
      List<String>? paragraphs;
      bridge.onTTSText = (list) => paragraphs = list;

      bridge.handleMessage(json.encode({
        'type': 'TTS_TEXT',
        'payload': {
          'paragraphs': ['Paragraph one.', 'Paragraph two.'],
        },
      }));

      expect(paragraphs, equals(['Paragraph one.', 'Paragraph two.']));
    });
  });

  group('Adwaita Themes and Color Palette Tests', () {
    test('Dark theme contains FoliateThemeColors extension', () {
      final darkTheme = AdwaitaTheme.dark();
      final extension = darkTheme.extension<FoliateThemeColors>();
      expect(extension, isNotNull);
      expect(extension!.windowBackground, equals(AdwaitaColors.darkWindowBg));
      expect(extension.activePill, equals(AdwaitaColors.darkActivePill));
    });

    test('Reader theme modes produce appropriate colors', () {
      final day = ReaderThemeColors.forMode(ReaderThemeMode.day);
      expect(day.background, equals(AdwaitaColors.readerDayBg));

      final sepia = ReaderThemeColors.forMode(ReaderThemeMode.sepia);
      expect(sepia.background, equals(AdwaitaColors.readerSepiaBg));

      final night = ReaderThemeColors.forMode(ReaderThemeMode.night);
      expect(night.background, equals(AdwaitaColors.readerNightBg));

      final black = ReaderThemeColors.forMode(ReaderThemeMode.black);
      expect(black.background, equals(AdwaitaColors.readerBlackBg));
    });
  });

  group('Per-Book Reader Settings Storage Tests', () {
    test('Stores and restores separate settings for different books', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService.instance;

      const bookAHash = 'hash-book-a-1111';
      const bookBHash = 'hash-book-b-2222';

      const settingsA = ReaderSettings(
        theme: ReaderThemeMode.sepia,
        fontSize: 20.0,
        fontFamily: 'serif',
      );

      const settingsB = ReaderSettings(
        theme: ReaderThemeMode.gruvbox,
        fontSize: 14.0,
        fontFamily: 'monospace',
      );

      await storage.saveBookSettings(bookAHash, settingsA);
      await storage.saveBookSettings(bookBHash, settingsB);

      final loadedA = await storage.getBookSettings(bookAHash);
      final loadedB = await storage.getBookSettings(bookBHash);

      expect(loadedA.theme, equals(ReaderThemeMode.sepia));
      expect(loadedA.fontSize, equals(20.0));
      expect(loadedA.fontFamily, equals('serif'));

      expect(loadedB.theme, equals(ReaderThemeMode.gruvbox));
      expect(loadedB.fontSize, equals(14.0));
      expect(loadedB.fontFamily, equals('monospace'));
    });
  });

  group('In-Book Search Models & Bridge Tests (Phase 3)', () {
    test('SearchSection and SearchResultItem parse from Map correctly', () {
      final data = {
        'label': 'Chapter 1: Loomings',
        'subitems': [
          {
            'cfi': 'epubcfi(/6/2[chap1]!/4/2/10:0)',
            'excerpt': {
              'pre': 'Call me ',
              'match': 'Ishmael',
              'post': '. Some years ago—never mind how long precisely...',
            },
          },
          {
            'cfi': 'epubcfi(/6/2[chap1]!/4/2/24:12)',
            'excerpt': 'legacy string excerpt',
          },
        ],
      };

      final section = SearchSection.fromMap(data);
      expect(section.label, equals('Chapter 1: Loomings'));
      expect(section.matchCount, equals(2));

      final item1 = section.subitems[0];
      expect(item1.cfi, equals('epubcfi(/6/2[chap1]!/4/2/10:0)'));
      expect(item1.excerpt.pre, equals('Call me '));
      expect(item1.excerpt.match, equals('Ishmael'));
      expect(item1.excerpt.post, equals('. Some years ago—never mind how long precisely...'));
      expect(item1.excerpt.fullText, equals('Call me Ishmael. Some years ago—never mind how long precisely...'));

      final item2 = section.subitems[1];
      expect(item2.cfi, equals('epubcfi(/6/2[chap1]!/4/2/24:12)'));
      expect(item2.excerpt.match, equals('legacy string excerpt'));
    });

    test('ReaderBridge dispatches SEARCH_RESULT and SEARCH_DONE to callbacks', () {
      final bridge = ReaderBridge();
      SearchSection? receivedSection;
      bool searchDoneCalled = false;

      bridge.onSearchResult = (section) {
        receivedSection = section;
      };
      bridge.onSearchDone = () {
        searchDoneCalled = true;
      };

      final searchResultMsg = jsonEncode({
        'type': 'SEARCH_RESULT',
        'payload': {
          'label': 'Chapter 4: The Counterpane',
          'subitems': [
            {
              'cfi': 'epubcfi(/6/8!/4/2/1:4)',
              'excerpt': {
                'pre': 'Upon waking next morning about daylight, I found ',
                'match': 'Queequeg',
                'post': '’s arm thrown over me in the most loving manner.',
              },
            },
          ],
        },
      });

      bridge.handleMessage(searchResultMsg);
      expect(receivedSection, isNotNull);
      expect(receivedSection!.label, equals('Chapter 4: The Counterpane'));
      expect(receivedSection!.subitems.length, equals(1));
      expect(receivedSection!.subitems.first.excerpt.match, equals('Queequeg'));

      final searchDoneMsg = jsonEncode({
        'type': 'SEARCH_DONE',
      });

      bridge.handleMessage(searchDoneMsg);
      expect(searchDoneCalled, isTrue);
    });
  });
}

