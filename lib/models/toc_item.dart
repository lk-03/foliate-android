import 'dart:convert';

/// Represents a node in the EPUB Table of Contents (TOC) hierarchy.
class TOCItem {
  final String label;
  final String? href;
  final List<TOCItem> subitems;
  final int depth;
  final int? pageNumber;

  const TOCItem({
    required this.label,
    this.href,
    this.subitems = const [],
    this.depth = 0,
    this.pageNumber,
  });

  TOCItem copyWith({
    String? label,
    String? href,
    List<TOCItem>? subitems,
    int? depth,
    int? pageNumber,
  }) {
    return TOCItem(
      label: label ?? this.label,
      href: href ?? this.href,
      subitems: subitems ?? this.subitems,
      depth: depth ?? this.depth,
      pageNumber: pageNumber ?? this.pageNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'href': href,
      'subitems': subitems.map((x) => x.toMap()).toList(),
      'depth': depth,
      'pageNumber': pageNumber,
    };
  }

  factory TOCItem.fromMap(Map<String, dynamic> map, [int currentDepth = 0]) {
    final subitemsList = map['subitems'] as List<dynamic>?;
    return TOCItem(
      label: map['label'] as String? ?? '',
      href: map['href'] as String?,
      depth: (map['depth'] as num?)?.toInt() ?? currentDepth,
      pageNumber: (map['pageNumber'] as num?)?.toInt(),
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
  String toString() => 'TOCItem(label: $label, href: $href, depth: $depth, pageNumber: $pageNumber, subitems: ${subitems.length})';
}
