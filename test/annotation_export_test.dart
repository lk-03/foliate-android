import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:foliate/models/models.dart';
import 'package:foliate/services/annotation_export_service.dart';

void main() {
  group('AnnotationExportService Tests', () {
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

    final Map<String, Book> booksMap = {
      'hash-1': book1,
      'hash-2': book2,
    };

    final annotations = [
      const Annotation(
        id: 'ann-1',
        bookHash: 'hash-1',
        cfi: 'epubcfi(/6/4!/4/2/10)',
        text: 'Things get broken, and sometimes they get repaired.',
        note: 'Beautiful reflection',
        color: '#FFE066',
        createdAt: 1725458000000,
      ),
      const Annotation(
        id: 'ann-2',
        bookHash: 'hash-1',
        cfi: 'epubcfi(/6/6!/4/2/4)',
        text: 'You won’t always feel this way.',
        color: '#B8E986',
        createdAt: 1725459000000,
      ),
      const Annotation(
        id: 'ann-3',
        bookHash: 'hash-2',
        cfi: 'epubcfi(/6/2!/4/2/2)',
        text: 'Fear is the mind-killer.',
        note: 'Litany against fear',
        color: '#80D8FF',
        createdAt: 1725460000000,
      ),
    ];

    test('Color label conversion maps hex codes to user-friendly names', () {
      expect(AnnotationExportService.colorLabel('#FFE066'), equals('Yellow'));
      expect(AnnotationExportService.colorLabel('#B8E986'), equals('Green'));
      expect(AnnotationExportService.colorLabel('#80D8FF'), equals('Blue'));
      expect(AnnotationExportService.colorLabel('#FFB6C1'), equals('Pink'));
      expect(AnnotationExportService.colorLabel('#999999'), equals('Highlight'));
    });

    test('exportToMarkdown generates formatted Obsidian/Notion markdown', () {
      final md = AnnotationExportService.exportToMarkdown(annotations, booksMap);

      // Verify YAML frontmatter
      expect(md, contains('---'));
      expect(md, contains('title: Foliate Reader Highlights & Notes'));
      expect(md, contains('total_highlights: 3'));

      // Verify book headers
      expect(md, contains('## A Little Life'));
      expect(md, contains('**Author:** Hanya Yanagihara'));
      expect(md, contains('## Dune'));
      expect(md, contains('**Author:** Frank Herbert'));

      // Verify quote blockquotes & metadata
      expect(md, contains('> Things get broken, and sometimes they get repaired.'));
      expect(md, contains('- **Color:** Yellow'));
      expect(md, contains('- **Note:** Beautiful reflection'));
      expect(md, contains('- **Location:** `epubcfi(/6/4!/4/2/10)`'));

      expect(md, contains('> Fear is the mind-killer.'));
      expect(md, contains('- **Color:** Blue'));
      expect(md, contains('- **Note:** Litany against fear'));
    });

    test('exportToJson generates valid JSON structure', () {
      final jsonString = AnnotationExportService.exportToJson(annotations, booksMap);
      final Map<String, dynamic> decoded = json.decode(jsonString);

      expect(decoded['totalAnnotations'], equals(3));
      expect(decoded['totalBooks'], equals(2));

      final books = decoded['books'] as List<dynamic>;
      expect(books.length, equals(2));

      final firstBook = books.firstWhere((b) => b['bookHash'] == 'hash-1');
      expect(firstBook['title'], equals('A Little Life'));
      expect(firstBook['author'], equals('Hanya Yanagihara'));
      expect(firstBook['annotationCount'], equals(2));

      final firstBookAnnotations = firstBook['annotations'] as List<dynamic>;
      expect(firstBookAnnotations.length, equals(2));
      expect(firstBookAnnotations[0]['text'], equals('Things get broken, and sometimes they get repaired.'));
      expect(firstBookAnnotations[0]['colorName'], equals('Yellow'));
      expect(firstBookAnnotations[0]['note'], equals('Beautiful reflection'));
    });
  });
}
