import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foliate/models/models.dart';
import 'package:foliate/services/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OPDS & Atom XML Feed Parsing Tests', () {
    test('Parses Project Gutenberg OPDS XML feed correctly', () {
      const sampleGutenbergXml = '''<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:opds="http://opds-spec.org/2010/catalog">
  <id>https://m.gutenberg.org/ebooks.opds/</id>
  <title>Project Gutenberg Catalog</title>
  <subtitle>Over 70,000 free books</subtitle>
  <link rel="self" href="/ebooks.opds/"/>
  <link rel="next" href="/ebooks.opds/?page=2"/>
  
  <entry>
    <id>https://www.gutenberg.org/ebooks/search.opds/?sort_order=downloads</id>
    <title>Popular</title>
    <content type="text">Our most popular books.</content>
    <link type="application/atom+xml;profile=opds-catalog" rel="subsection" href="/ebooks/search.opds/?sort_order=downloads"/>
  </entry>
  
  <entry>
    <id>urn:gutenberg:345:3</id>
    <title>Dracula</title>
    <author>
      <name>Bram Stoker</name>
    </author>
    <summary>A Gothic horror novel published in 1897.</summary>
    <category term="Horror tales" label="Horror"/>
    <category term="Vampires -- Fiction"/>
    <link type="application/epub+zip" rel="http://opds-spec.org/acquisition" length="602902" href="/ebooks/345.epub3.images"/>
    <link type="image/jpeg" rel="http://opds-spec.org/image" href="/cache/epub/345/pg345.cover.medium.jpg"/>
  </entry>
</feed>''';

      final feed = OpdsService.instance.parseFeedXml(
        sampleGutenbergXml,
        baseUrl: 'https://m.gutenberg.org/ebooks.opds/',
      );

      expect(feed.title, 'Project Gutenberg Catalog');
      expect(feed.subtitle, 'Over 70,000 free books');
      expect(feed.nextPageUrl, 'https://m.gutenberg.org/ebooks.opds/?page=2');
      expect(feed.entries.length, 2);

      // 1. Navigation subsection
      final sub = feed.subsections.first;
      expect(sub.title, 'Popular');
      expect(sub.isNavigation, isTrue);
      expect(sub.navigationUrl, 'https://m.gutenberg.org/ebooks/search.opds/?sort_order=downloads');

      // 2. Book with acquisition link
      final book = feed.books.first;
      expect(book.title, 'Dracula');
      expect(book.author, 'Bram Stoker');
      expect(book.summary, 'A Gothic horror novel published in 1897.');
      expect(book.categories, contains('Horror'));
      expect(book.categories, contains('Vampires -- Fiction'));
      expect(book.hasDownload, isTrue);
      expect(book.downloadUrl, 'https://m.gutenberg.org/ebooks/345.epub3.images');
      expect(book.coverUrl, 'https://m.gutenberg.org/cache/epub/345/pg345.cover.medium.jpg');
      expect(book.downloadSize, 602902);
      expect(book.formattedSize, '589 KB');
    });

    test('Parses Standard Ebooks Atom feed with media:thumbnail and enclosures correctly', () {
      const sampleStandardEbooksXml = '''<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:media="http://search.yahoo.com/mrss/">
  <id>https://standardebooks.org/feeds/atom/new-releases</id>
  <title>Standard Ebooks - Newest Ebooks</title>
  <subtitle>The 15 latest Standard Ebooks</subtitle>
  <entry>
    <id>https://standardebooks.org/ebooks/henry-seton-merriman/suspense</id>
    <title>Suspense</title>
    <author>
      <name>Henry Seton Merriman</name>
      <uri>https://standardebooks.org/ebooks/henry-seton-merriman</uri>
    </author>
    <summary type="text">Two childhood friends discover their character.</summary>
    <category scheme="http://purl.org/dc/terms/LCSH" term="War correspondents--Fiction"/>
    <media:thumbnail height="525" url="https://standardebooks.org/ebooks/henry-seton-merriman/suspense/downloads/cover-thumbnail.jpg" width="350"/>
    <link href="https://standardebooks.org/ebooks/henry-seton-merriman/suspense/downloads/henry-seton-merriman_suspense.epub?source=feed" length="781966" rel="enclosure" title="Recommended compatible epub" type="application/epub+zip"/>
  </entry>
</feed>''';

      final feed = OpdsService.instance.parseFeedXml(
        sampleStandardEbooksXml,
        baseUrl: 'https://standardebooks.org/feeds/atom/new-releases',
      );

      expect(feed.title, 'Standard Ebooks - Newest Ebooks');
      expect(feed.books.length, 1);

      final book = feed.books.first;
      expect(book.title, 'Suspense');
      expect(book.author, 'Henry Seton Merriman');
      expect(book.summary, 'Two childhood friends discover their character.');
      expect(book.coverUrl, 'https://standardebooks.org/ebooks/henry-seton-merriman/suspense/downloads/cover-thumbnail.jpg');
      expect(book.downloadUrl, 'https://standardebooks.org/ebooks/henry-seton-merriman/suspense/downloads/henry-seton-merriman_suspense.epub?source=feed');
      expect(book.downloadSize, 781966);
      expect(book.formattedSize, '764 KB');
      expect(book.isNavigation, isFalse);
    });
  });

  group('Custom Catalogs Storage Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Saves, retrieves, and removes custom catalogs from StorageService', () async {
      final storage = StorageService.instance;

      // 1. Initially empty
      final initial = await storage.getCustomCatalogs();
      expect(initial, isEmpty);

      // 2. Save a custom catalog
      const custom1 = Catalog(
        id: 'calibre_home',
        name: 'Home Calibre Server',
        description: 'Personal e-book library',
        url: 'http://192.168.1.50:8080/opds',
        tag: 'Home Server',
        isCustom: true,
      );
      await storage.saveCustomCatalog(custom1);

      final afterAdd = await storage.getCustomCatalogs();
      expect(afterAdd.length, 1);
      expect(afterAdd.first.id, 'calibre_home');
      expect(afterAdd.first.name, 'Home Calibre Server');
      expect(afterAdd.first.url, 'http://192.168.1.50:8080/opds');
      expect(afterAdd.first.isCustom, isTrue);

      // 3. Remove custom catalog
      await storage.removeCustomCatalog('calibre_home');
      final afterRemove = await storage.getCustomCatalogs();
      expect(afterRemove, isEmpty);
    });
  });

  group('DownloadService Unit Tests', () {
    test('Download progress state management and cancellation', () {
      final downloadService = DownloadService.instance;

      expect(downloadService.isDownloading('test_book_1'), isFalse);
      expect(downloadService.getProgress('test_book_1'), isNull);

      // Cancel non-existent download gracefully
      expect(() => downloadService.cancelDownload('test_book_1'), returnsNormally);
    });

    test('CatalogBook model JSON serialization and size formatting', () {
      const book = CatalogBook(
        id: '123',
        title: 'Moby Dick',
        author: 'Herman Melville',
        summary: 'Call me Ishmael.',
        coverUrl: 'https://example.com/cover.jpg',
        downloadUrl: 'https://example.com/moby.epub',
        downloadSize: 2500000,
        categories: ['Adventure', 'Classics'],
        sourceCatalog: 'Project Gutenberg',
      );

      expect(book.formattedSize, '2.4 MB');
      expect(book.hasDownload, isTrue);

      final jsonMap = book.toJson();
      final reconstructed = CatalogBook.fromJson(jsonMap);

      expect(reconstructed.id, book.id);
      expect(reconstructed.title, book.title);
      expect(reconstructed.author, book.author);
      expect(reconstructed.downloadUrl, book.downloadUrl);
      expect(reconstructed.downloadSize, book.downloadSize);
      expect(reconstructed.categories, book.categories);
      expect(reconstructed, equals(book));
    });
  });
}
