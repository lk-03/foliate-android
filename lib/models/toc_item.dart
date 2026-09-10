import 'dart:convert';
import 'reader_settings.dart';

/// Represents a node in the EPUB Table of Contents (TOC) hierarchy.
class TOCItem {
  final String label;
  final String? href;
  final List<TOCItem> subitems;
  final int depth;
  final int? pageNumber;
  final int? digitalPageNumber;
  final int? printPageNumber;

  const TOCItem({
    required this.label,
    this.href,
    this.subitems = const [],
    this.depth = 0,
    this.pageNumber,
    this.digitalPageNumber,
    this.printPageNumber,
  });

  /// Resolves the page number based on selected page number source (Digital Book vs Print Edition)
  int? getPageNumber(PageNumberSource source) {
    if (source == PageNumberSource.digitalBook) {
      return digitalPageNumber ?? pageNumber;
    } else {
      return printPageNumber ?? pageNumber;
    }
  }

  TOCItem copyWith({
    String? label,
    String? href,
    List<TOCItem>? subitems,
    int? depth,
    int? pageNumber,
    int? digitalPageNumber,
    int? printPageNumber,
  }) {
    return TOCItem(
      label: label ?? this.label,
      href: href ?? this.href,
      subitems: subitems ?? this.subitems,
      depth: depth ?? this.depth,
      pageNumber: pageNumber ?? this.pageNumber,
      digitalPageNumber: digitalPageNumber ?? this.digitalPageNumber,
      printPageNumber: printPageNumber ?? this.printPageNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'href': href,
      'subitems': subitems.map((x) => x.toMap()).toList(),
      'depth': depth,
      'pageNumber': pageNumber,
      'digitalPageNumber': digitalPageNumber,
      'printPageNumber': printPageNumber,
    };
  }

  factory TOCItem.fromMap(Map<String, dynamic> map, [int currentDepth = 0]) {
    final subitemsList = map['subitems'] as List<dynamic>?;
    final pageNum = (map['pageNumber'] as num?)?.toInt();
    final digitalPage = (map['digitalPageNumber'] as num?)?.toInt() ?? pageNum;
    final printPage = (map['printPageNumber'] as num?)?.toInt();

    return TOCItem(
      label: map['label'] as String? ?? '',
      href: map['href'] as String?,
      depth: (map['depth'] as num?)?.toInt() ?? currentDepth,
      pageNumber: pageNum,
      digitalPageNumber: digitalPage,
      printPageNumber: printPage,
      subitems: subitemsList != null
          ? subitemsList
              .whereType<Map<String, dynamic>>()
              .map((x) => TOCItem.fromMap(x, currentDepth + 1))
              .toList()
          : const [],
    );
  }

  String toJson() => json.encode(toMap());

  factory TOCItem.fromJson(String source) =>
      TOCItem.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'TOCItem(label: $label, href: $href, depth: $depth, pageNumber: $pageNumber, digital: $digitalPageNumber, print: $printPageNumber, subitems: ${subitems.length})';
}
