import 'dart:convert';

/// Represents a character-accurate text highlight or note in an EPUB.
class Annotation {
  final String id;
  final String bookHash;
  final String cfi;
  final String text;
  final String? note;
  final String color;
  final int createdAt;

  // Predefined Foliate/Adwaita highlight colors
  static const String colorYellow = '#FFE066';
  static const String colorGreen = '#8CE99A';
  static const String colorBlue = '#74C0FC';
  static const String colorPink = '#FF8787';

  static const List<String> defaultColors = [
    colorYellow,
    colorGreen,
    colorBlue,
    colorPink,
  ];

  const Annotation({
    required this.id,
    required this.bookHash,
    required this.cfi,
    required this.text,
    this.note,
    this.color = colorYellow,
    required this.createdAt,
  });

  Annotation copyWith({
    String? id,
    String? bookHash,
    String? cfi,
    String? text,
    String? note,
    String? color,
    int? createdAt,
  }) {
    return Annotation(
      id: id ?? this.id,
      bookHash: bookHash ?? this.bookHash,
      cfi: cfi ?? this.cfi,
      text: text ?? this.text,
      note: note ?? this.note,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookHash': bookHash,
      'cfi': cfi,
      'text': text,
      'note': note,
      'color': color,
      'createdAt': createdAt,
    };
  }

  factory Annotation.fromMap(Map<String, dynamic> map) {
    return Annotation(
      id: map['id'] as String,
      bookHash: map['bookHash'] as String,
      cfi: map['cfi'] as String,
      text: map['text'] as String,
      note: map['note'] as String?,
      color: map['color'] as String? ?? colorYellow,
      createdAt: (map['createdAt'] as num).toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Annotation.fromJson(String source) =>
      Annotation.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Annotation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Annotation(id: $id, bookHash: $bookHash, cfi: $cfi, text: $text)';
}
