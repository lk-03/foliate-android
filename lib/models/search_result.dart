import 'package:flutter/foundation.dart';

/// Context excerpt surrounding a search query occurrence
@immutable
class SearchExcerpt {
  final String pre;
  final String match;
  final String post;

  const SearchExcerpt({
    required this.pre,
    required this.match,
    required this.post,
  });

  factory SearchExcerpt.fromData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return SearchExcerpt(
        pre: data['pre']?.toString() ?? '',
        match: data['match']?.toString() ?? '',
        post: data['post']?.toString() ?? '',
      );
    } else if (data is Map) {
      return SearchExcerpt(
        pre: data['pre']?.toString() ?? '',
        match: data['match']?.toString() ?? '',
        post: data['post']?.toString() ?? '',
      );
    } else if (data is String) {
      return SearchExcerpt(
        pre: '',
        match: data,
        post: '',
      );
    }
    return const SearchExcerpt(pre: '', match: '', post: '');
  }

  String get fullText => '$pre$match$post';

  @override
  String toString() => 'SearchExcerpt(pre: "$pre", match: "$match", post: "$post")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchExcerpt &&
          runtimeType == other.runtimeType &&
          pre == other.pre &&
          match == other.match &&
          post == other.post;

  @override
  int get hashCode => Object.hash(pre, match, post);
}

/// An individual match within a book chapter
@immutable
class SearchResultItem {
  final String cfi;
  final SearchExcerpt excerpt;

  const SearchResultItem({
    required this.cfi,
    required this.excerpt,
  });

  factory SearchResultItem.fromMap(Map<String, dynamic> map) {
    return SearchResultItem(
      cfi: map['cfi']?.toString() ?? '',
      excerpt: SearchExcerpt.fromData(map['excerpt']),
    );
  }

  @override
  String toString() => 'SearchResultItem(cfi: "$cfi", excerpt: $excerpt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResultItem &&
          runtimeType == other.runtimeType &&
          cfi == other.cfi &&
          excerpt == other.excerpt;

  @override
  int get hashCode => Object.hash(cfi, excerpt);
}

/// A chapter or spine section containing search matches
@immutable
class SearchSection {
  final String label;
  final List<SearchResultItem> subitems;

  const SearchSection({
    required this.label,
    required this.subitems,
  });

  factory SearchSection.fromMap(Map<String, dynamic> map) {
    final rawSubitems = map['subitems'] as List<dynamic>? ?? const [];
    final items = <SearchResultItem>[];
    for (final raw in rawSubitems) {
      if (raw is Map<String, dynamic>) {
        items.add(SearchResultItem.fromMap(raw));
      } else if (raw is Map) {
        items.add(SearchResultItem.fromMap(Map<String, dynamic>.from(raw)));
      }
    }
    return SearchSection(
      label: map['label']?.toString() ?? 'Section',
      subitems: items,
    );
  }

  int get matchCount => subitems.length;

  @override
  String toString() => 'SearchSection(label: "$label", count: ${subitems.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchSection &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          listEquals(subitems, other.subitems);

  @override
  int get hashCode => Object.hash(label, Object.hashAll(subitems));
}
