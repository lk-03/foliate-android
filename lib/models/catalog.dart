import 'package:flutter/foundation.dart';

/// Model representing an Open Library or OPDS Catalog source
@immutable
class Catalog {
  final String id;
  final String name;
  final String description;
  final String url;
  final String tag;
  final bool isCustom;

  const Catalog({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.tag,
    this.isCustom = false,
  });

  /// Default predefined catalogs matching Foliate Linux desktop
  static const List<Catalog> defaultCatalogs = [
    Catalog(
      id: 'gutenberg',
      name: 'Project Gutenberg',
      description: 'Over 70,000 free public domain ebooks and classics',
      url: 'https://m.gutenberg.org/ebooks.opds/',
      tag: 'Public Domain',
    ),
    Catalog(
      id: 'standard_ebooks',
      name: 'Standard Ebooks',
      description: 'Free, beautifully typeset editions of public domain books',
      url: 'https://standardebooks.org/opds/all-books',
      tag: 'Typeset Classics',
    ),
    Catalog(
      id: 'internet_archive',
      name: 'Internet Archive',
      description: 'Millions of digitized books, historic texts, and media',
      url: 'https://archive.org/services/opds/',
      tag: 'Digital Archive',
    ),
    Catalog(
      id: 'feedbooks',
      name: 'Feedbooks',
      description: 'High quality public domain and creative commons titles',
      url: 'https://feedbooks.com/publicdomain/catalog.atom',
      tag: 'Curated eBooks',
    ),
  ];

  Catalog copyWith({
    String? id,
    String? name,
    String? description,
    String? url,
    String? tag,
    bool? isCustom,
  }) {
    return Catalog(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      url: url ?? this.url,
      tag: tag ?? this.tag,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'url': url,
        'tag': tag,
        'isCustom': isCustom,
      };

  factory Catalog.fromJson(Map<String, dynamic> json) => Catalog(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        url: json['url'] as String,
        tag: json['tag'] as String? ?? 'Custom OPDS',
        isCustom: json['isCustom'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Catalog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          url == other.url;

  @override
  int get hashCode => id.hashCode ^ url.hashCode;
}
