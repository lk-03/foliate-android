import '../models/models.dart';

/// Service responsible for computing personalized book recommendations.
/// Ranks curated titles against the reader's explicitly selected niches
/// and implicit signals from favorited or frequently read books in their library.
class RecommendationService {
  static RecommendationService? _instance;
  static RecommendationService get instance =>
      _instance ??= RecommendationService._();

  RecommendationService._();

  /// Computes personalized book recommendations.
  ///
  /// - If [selectedFilter] is a specific niche or genre, returns books strictly matching that niche.
  /// - If [selectedFilter] is null, 'For You', or 'All', returns all curated books scored
  ///   and sorted according to [favoriteNiches] and [localBooks] favorites.
  List<CuratedBook> getPersonalizedRecommendations({
    required List<String> favoriteNiches,
    required List<Book> localBooks,
    String? selectedFilter,
  }) {
    final allBooks = CuratedBook.allCuratedBooks;
    final filter = selectedFilter?.trim() ?? 'For You';

    // 1. Specific niche filter active
    if (filter != 'For You' && filter != 'All') {
      final filtered = allBooks.where((book) {
        final niche = ReadingNiche.findByName(filter);
        if (niche != null) {
          if (book.nicheId.toLowerCase() == niche.id.toLowerCase()) return true;
          if (niche.keywords.any(
            (k) =>
                book.genre.toLowerCase().contains(k.toLowerCase()) ||
                book.tag.toLowerCase().contains(k.toLowerCase()),
          )) {
            return true;
          }
        }
        return book.genre.toLowerCase().contains(filter.toLowerCase()) ||
            book.tag.toLowerCase().contains(filter.toLowerCase());
      }).toList();

      if (filtered.isNotEmpty) {
        return filtered;
      }
    }

    // 2. Compute recommendation score for each book
    final favoriteAuthors = <String>{};
    final favoriteKeywords = <String>{};

    for (final b in localBooks.where((b) => b.isFavorite)) {
      if (b.author.isNotEmpty && b.author != 'Unknown Author') {
        favoriteAuthors.add(b.author.toLowerCase());
      }
      for (final part in b.title.toLowerCase().split(RegExp(r'\s+'))) {
        if (part.length > 3) {
          favoriteKeywords.add(part);
        }
      }
    }

    final normalizedNiches =
        favoriteNiches.map((n) => n.trim().toLowerCase()).toSet();

    final scored = allBooks.map((book) {
      double score = book.rating * 2.0;

      // Direct niche match
      if (book.nicheId.isNotEmpty &&
          normalizedNiches.contains(book.nicheId.toLowerCase())) {
        score += 25.0;
      }

      // Check keyword/genre alignment with favorite niches
      for (final nicheId in normalizedNiches) {
        final niche = ReadingNiche.findById(nicheId) ??
            ReadingNiche.findByName(nicheId);
        if (niche != null) {
          if (niche.keywords.any(
            (k) =>
                book.genre.toLowerCase().contains(k.toLowerCase()) ||
                book.tag.toLowerCase().contains(k.toLowerCase()),
          )) {
            score += 10.0;
          }
        }
      }

      // Author match from library favorites
      if (favoriteAuthors.contains(book.author.toLowerCase())) {
        score += 20.0;
      }

      // Keyword match from library favorites
      final bookWords =
          book.title.toLowerCase().split(RegExp(r'\s+')).toSet();
      for (final kw in favoriteKeywords) {
        if (bookWords.contains(kw) ||
            book.synopsis.toLowerCase().contains(kw)) {
          score += 4.0;
        }
      }

      return _ScoredBook(book: book, score: score);
    }).toList();

    // Sort by descending score
    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored.map((s) => s.book).toList();
  }
}

class _ScoredBook {
  final CuratedBook book;
  final double score;

  const _ScoredBook({required this.book, required this.score});
}
