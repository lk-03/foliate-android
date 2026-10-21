import 'package:flutter/foundation.dart';

/// Represents an e-book or category entry within an OPDS feed or Open Library catalog.
@immutable
class CatalogBook {
  final String id;
  final String title;
  final String author;
  final String summary;
  final String? coverUrl;
  final String? downloadUrl;
  final int? downloadSize;
  final bool isNavigation;
  final String? navigationUrl;
  final List<String> categories;
  final String sourceCatalog;

  const CatalogBook({
    required this.id,
    required this.title,
    required this.author,
    required this.summary,
    this.coverUrl,
    this.downloadUrl,
    this.downloadSize,
    this.isNavigation = false,
    this.navigationUrl,
    this.categories = const [],
    this.sourceCatalog = '',
  });

  bool get hasDownload => downloadUrl != null && downloadUrl!.isNotEmpty;

  String get formattedSize {
    if (downloadSize == null || downloadSize! <= 0) return '';
    if (downloadSize! < 1024 * 1024) {
      final kb = (downloadSize! / 1024).toStringAsFixed(0);
      return '$kb KB';
    }
    final mb = (downloadSize! / (1024 * 1024)).toStringAsFixed(1);
    return '$mb MB';
  }

  CatalogBook copyWith({
    String? id,
    String? title,
    String? author,
    String? summary,
    String? coverUrl,
    String? downloadUrl,
    int? downloadSize,
    bool? isNavigation,
    String? navigationUrl,
    List<String>? categories,
    String? sourceCatalog,
  }) {
    return CatalogBook(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      summary: summary ?? this.summary,
      coverUrl: coverUrl ?? this.coverUrl,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      downloadSize: downloadSize ?? this.downloadSize,
      isNavigation: isNavigation ?? this.isNavigation,
      navigationUrl: navigationUrl ?? this.navigationUrl,
      categories: categories ?? this.categories,
      sourceCatalog: sourceCatalog ?? this.sourceCatalog,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'summary': summary,
        'coverUrl': coverUrl,
        'downloadUrl': downloadUrl,
        'downloadSize': downloadSize,
        'isNavigation': isNavigation,
        'navigationUrl': navigationUrl,
        'categories': categories,
        'sourceCatalog': sourceCatalog,
      };

  factory CatalogBook.fromJson(Map<String, dynamic> json) => CatalogBook(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Untitled',
        author: json['author'] as String? ?? 'Unknown Author',
        summary: json['summary'] as String? ?? '',
        coverUrl: json['coverUrl'] as String?,
        downloadUrl: json['downloadUrl'] as String?,
        downloadSize: json['downloadSize'] as int?,
        isNavigation: json['isNavigation'] as bool? ?? false,
        navigationUrl: json['navigationUrl'] as String?,
        categories: (json['categories'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        sourceCatalog: json['sourceCatalog'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogBook &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title;

  @override
  int get hashCode => id.hashCode ^ title.hashCode;
}
