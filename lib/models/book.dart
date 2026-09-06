import 'dart:convert';

/// Represents a content-addressed book in the Foliate library.
/// The canonical identifier is the SHA-256 hash of the EPUB file's bytes.
class Book {
  final String hash;
  final String title;
  final String author;
  final String? coverUri;
  final String? filePath;
  final String? cfi;
  final double percentage;
  final int addedAt;
  final int? lastReadAt;
  final int totalReadingTimeMs;
  final bool isFavorite;
  final bool isPinned;
  final int? fileSize;

  const Book({
    required this.hash,
    required this.title,
    this.author = 'Unknown Author',
    this.coverUri,
    this.filePath,
    this.cfi,
    this.percentage = 0.0,
    required this.addedAt,
    this.lastReadAt,
    this.totalReadingTimeMs = 0,
    this.isFavorite = false,
    this.isPinned = false,
    this.fileSize,
  });

  Book copyWith({
    String? hash,
    String? title,
    String? author,
    String? coverUri,
    String? filePath,
    String? cfi,
    double? percentage,
    int? addedAt,
    int? lastReadAt,
    int? totalReadingTimeMs,
    bool? isFavorite,
    bool? isPinned,
    int? fileSize,
  }) {
    return Book(
      hash: hash ?? this.hash,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUri: coverUri ?? this.coverUri,
      filePath: filePath ?? this.filePath,
      cfi: cfi ?? this.cfi,
      percentage: percentage ?? this.percentage,
      addedAt: addedAt ?? this.addedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      totalReadingTimeMs: totalReadingTimeMs ?? this.totalReadingTimeMs,
      isFavorite: isFavorite ?? this.isFavorite,
      isPinned: isPinned ?? this.isPinned,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hash': hash,
      'title': title,
      'author': author,
      'coverUri': coverUri,
      'filePath': filePath,
      'cfi': cfi,
      'percentage': percentage,
      'addedAt': addedAt,
      'lastReadAt': lastReadAt,
      'totalReadingTimeMs': totalReadingTimeMs,
      'isFavorite': isFavorite,
      'isPinned': isPinned,
      'fileSize': fileSize,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      hash: map['hash'] as String? ?? '',
      title: map['title'] as String? ?? 'Untitled',
      author: map['author'] as String? ?? 'Unknown Author',
      coverUri: map['coverUri'] as String?,
      filePath: map['filePath'] as String?,
      cfi: map['cfi'] as String?,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      addedAt: (map['addedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      lastReadAt: (map['lastReadAt'] as num?)?.toInt(),
      totalReadingTimeMs: (map['totalReadingTimeMs'] as num?)?.toInt() ?? 0,
      isFavorite: map['isFavorite'] as bool? ?? false,
      isPinned: map['isPinned'] as bool? ?? false,
      fileSize: (map['fileSize'] as num?)?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Book.fromJson(String source) => Book.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Book && other.hash == hash;
  }

  @override
  int get hashCode => hash.hashCode;

  @override
  String toString() => 'Book(hash: $hash, title: $title, author: $author, percentage: $percentage%)';
}
