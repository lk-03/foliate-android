import 'dart:convert';

/// Represents a saved user bookmark in an EPUB.
class Bookmark {
  final String id;
  final String bookHash;
  final String cfi;
  final String? chapterTitle;
  final double percentage;
  final int? pageNumber;
  final int createdAt;

  const Bookmark({
    required this.id,
    required this.bookHash,
    required this.cfi,
    this.chapterTitle,
    this.percentage = 0.0,
    this.pageNumber,
    required this.createdAt,
  });

  Bookmark copyWith({
    String? id,
    String? bookHash,
    String? cfi,
    String? chapterTitle,
    double? percentage,
    int? pageNumber,
    int? createdAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      bookHash: bookHash ?? this.bookHash,
      cfi: cfi ?? this.cfi,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      percentage: percentage ?? this.percentage,
      pageNumber: pageNumber ?? this.pageNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookHash': bookHash,
      'cfi': cfi,
      'chapterTitle': chapterTitle,
      'percentage': percentage,
      'pageNumber': pageNumber,
      'createdAt': createdAt,
    };
  }

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as String,
      bookHash: map['bookHash'] as String,
      cfi: map['cfi'] as String,
      chapterTitle: map['chapterTitle'] as String?,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      pageNumber: (map['pageNumber'] as num?)?.toInt(),
      createdAt: (map['createdAt'] as num).toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Bookmark.fromJson(String source) =>
      Bookmark.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Bookmark && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Bookmark(id: $id, bookHash: $bookHash, cfi: $cfi, chapter: $chapterTitle, pct: $percentage%)';
}
