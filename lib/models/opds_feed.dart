import 'package:flutter/foundation.dart';
import 'catalog_book.dart';

/// Represents a parsed OPDS or Atom catalog feed
@immutable
class OpdsFeed {
  final String title;
  final String subtitle;
  final String? id;
  final String? iconUrl;
  final String? nextPageUrl;
  final String? searchUrl;
  final List<CatalogBook> entries;

  const OpdsFeed({
    required this.title,
    this.subtitle = '',
    this.id,
    this.iconUrl,
    this.nextPageUrl,
    this.searchUrl,
    this.entries = const [],
  });

  bool get hasNextPage => nextPageUrl != null && nextPageUrl!.isNotEmpty;

  List<CatalogBook> get books => entries.where((e) => !e.isNavigation).toList();
  List<CatalogBook> get subsections => entries.where((e) => e.isNavigation).toList();

  OpdsFeed copyWith({
    String? title,
    String? subtitle,
    String? id,
    String? iconUrl,
    String? nextPageUrl,
    String? searchUrl,
    List<CatalogBook>? entries,
  }) {
    return OpdsFeed(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      id: id ?? this.id,
      iconUrl: iconUrl ?? this.iconUrl,
      nextPageUrl: nextPageUrl ?? this.nextPageUrl,
      searchUrl: searchUrl ?? this.searchUrl,
      entries: entries ?? this.entries,
    );
  }
}
