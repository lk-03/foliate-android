import 'dart:convert';
import '../models/models.dart';

/// Formatter and exporter for book highlights and user notes.
class AnnotationExportService {
  AnnotationExportService._();

  static String colorLabel(String hex) {
    switch (hex.toUpperCase().replaceAll('#', '')) {
      case 'FFE066':
      case 'FFF59D':
        return 'Yellow';
      case 'B8E986':
      case 'C8E6C9':
        return 'Green';
      case '80D8FF':
      case 'BBDEFB':
        return 'Blue';
      case 'FFB6C1':
      case 'F8BBD0':
        return 'Pink';
      case 'E1BEE7':
        return 'Purple';
      default:
        return 'Highlight';
    }
  }

  static String _formatDate(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  /// Exports a list of annotations into Obsidian/Notion-compatible Markdown.
  static String exportToMarkdown(
    List<Annotation> annotations,
    Map<String, Book> booksMap,
  ) {
    final buffer = StringBuffer();
    final now = DateTime.now().toIso8601String();

    buffer.writeln('---');
    buffer.writeln('title: Foliate Reader Highlights & Notes');
    buffer.writeln('date_exported: "$now"');
    buffer.writeln('total_highlights: ${annotations.length}');
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('# Foliate Reader Highlights & Notes');
    buffer.writeln();

    // Group annotations by bookHash
    final grouped = <String, List<Annotation>>{};
    for (final a in annotations) {
      grouped.putIfAbsent(a.bookHash, () => []).add(a);
    }

    for (final entry in grouped.entries) {
      final bookHash = entry.key;
      final bookAnnotations = entry.value;
      final book = booksMap[bookHash];
      final title = book?.title ?? 'Untitled Book';
      final author = book?.author ?? 'Unknown Author';

      buffer.writeln('## $title');
      buffer.writeln('**Author:** $author  ');
      buffer.writeln('**Highlights:** ${bookAnnotations.length}  ');
      buffer.writeln();

      for (int i = 0; i < bookAnnotations.length; i++) {
        final ann = bookAnnotations[i];
        final colorName = colorLabel(ann.color);
        final date = _formatDate(ann.createdAt);

        buffer.writeln('> ${ann.text.replaceAll('\n', ' ')}');
        buffer.writeln();
        buffer.writeln('- **Color:** $colorName');
        buffer.writeln('- **Date:** $date');
        if (ann.note != null && ann.note!.trim().isNotEmpty) {
          buffer.writeln('- **Note:** ${ann.note!.trim()}');
        }
        buffer.writeln('- **Location:** `${ann.cfi}`');
        buffer.writeln();
      }

      buffer.writeln('---');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Exports a list of annotations into structured, pretty-printed JSON.
  static String exportToJson(
    List<Annotation> annotations,
    Map<String, Book> booksMap,
  ) {
    final grouped = <String, List<Annotation>>{};
    for (final a in annotations) {
      grouped.putIfAbsent(a.bookHash, () => []).add(a);
    }

    final booksList = <Map<String, dynamic>>[];
    for (final entry in grouped.entries) {
      final bookHash = entry.key;
      final bookAnnotations = entry.value;
      final book = booksMap[bookHash];

      booksList.add({
        'bookHash': bookHash,
        'title': book?.title ?? 'Untitled Book',
        'author': book?.author ?? 'Unknown Author',
        'annotationCount': bookAnnotations.length,
        'annotations': bookAnnotations.map((a) {
          return {
            'id': a.id,
            'text': a.text,
            'note': a.note,
            'color': a.color,
            'colorName': colorLabel(a.color),
            'cfi': a.cfi,
            'createdAt': a.createdAt,
            'createdAtFormatted': _formatDate(a.createdAt),
          };
        }).toList(),
      });
    }

    final root = {
      'exportedAt': DateTime.now().toIso8601String(),
      'totalAnnotations': annotations.length,
      'totalBooks': grouped.length,
      'books': booksList,
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(root);
  }
}
