import 'package:flutter/foundation.dart';

/// Represents a curated editorial book recommendation for Open Library Gems
/// and Explore Horizons sections on the Home dashboard.
@immutable
class CuratedBook {
  final String id;
  final String title;
  final String author;
  final String genre;
  final String tag;
  final String? coverUrl;
  final double rating;
  final int reviewCount;
  final String quoteSnippet;
  final int pageCount;
  final String readTimeEstimate;
  final String synopsis;
  final String catalogSource;

  const CuratedBook({
    required this.id,
    required this.title,
    required this.author,
    required this.genre,
    required this.tag,
    this.coverUrl,
    this.rating = 4.5,
    this.reviewCount = 1000,
    required this.quoteSnippet,
    this.pageCount = 250,
    required this.readTimeEstimate,
    required this.synopsis,
    this.catalogSource = 'Project Gutenberg',
  });

  /// Curated classic public domain titles for the "Open Library Gems" carousel
  static const List<CuratedBook> openLibraryGems = [
    CuratedBook(
      id: 'gem-frankenstein',
      title: 'Frankenstein',
      author: 'Mary Shelley',
      genre: 'Gothic Mystery',
      tag: 'Public Domain',
      rating: 4.6,
      reviewCount: 48200,
      quoteSnippet: 'A sublime examination of ambition, loneliness, and human fragility.',
      pageCount: 280,
      readTimeEstimate: '5h read',
      synopsis:
          'Mary Shelley’s foundational gothic masterpiece explores Victor Frankenstein’s fateful obsession with reanimating life and the tragic consequences of abandonment.',
      catalogSource: 'Standard Ebooks',
    ),
    CuratedBook(
      id: 'gem-pride-prejudice',
      title: 'Pride and Prejudice',
      author: 'Jane Austen',
      genre: 'Classic Fiction',
      tag: 'Public Domain',
      rating: 4.9,
      reviewCount: 112400,
      quoteSnippet: 'Sharp wit and romantic tension that remains utterly timeless.',
      pageCount: 432,
      readTimeEstimate: '8h read',
      synopsis:
          'Jane Austen’s sparkling comedy of manners follows Elizabeth Bennet as she navigates societal pressures, family eccentricities, and Mr. Darcy.',
      catalogSource: 'Project Gutenberg',
    ),
    CuratedBook(
      id: 'gem-dorian-gray',
      title: 'The Picture of Dorian Gray',
      author: 'Oscar Wilde',
      genre: 'Philosophical',
      tag: 'Public Domain',
      rating: 4.3,
      reviewCount: 31500,
      quoteSnippet: 'An intoxicating philosophical parable on beauty, youth, and sin.',
      pageCount: 256,
      readTimeEstimate: '4.5h read',
      synopsis:
          'Oscar Wilde’s haunting moral allegory explores aestheticism, vanity, and moral corruption in Victorian London.',
      catalogSource: 'Standard Ebooks',
    ),
    CuratedBook(
      id: 'gem-metamorphosis',
      title: 'The Metamorphosis',
      author: 'Franz Kafka',
      genre: 'Absurdist Fiction',
      tag: 'Public Domain',
      rating: 4.5,
      reviewCount: 62100,
      quoteSnippet: 'An unforgettable existential awakening framed in chilling realism.',
      pageCount: 96,
      readTimeEstimate: '2h read',
      synopsis:
          'Franz Kafka’s seminal novella recounting the sudden transformation of traveling salesman Gregor Samsa into an insect.',
      catalogSource: 'Project Gutenberg',
    ),
    CuratedBook(
      id: 'gem-moby-dick',
      title: 'Moby Dick',
      author: 'Herman Melville',
      genre: 'Adventure',
      tag: 'Public Domain',
      rating: 4.2,
      reviewCount: 54000,
      quoteSnippet: 'An epic exploration of obsession, destiny, and the boundless sea.',
      pageCount: 624,
      readTimeEstimate: '14h read',
      synopsis:
          'Captain Ahab’s monomaniacal quest for the white whale through treacherous global waters and philosophical depths.',
      catalogSource: 'Standard Ebooks',
    ),
  ];

  /// Curated titles for the "Explore Horizons" genres recommendation row
  static const List<CuratedBook> exploreHorizons = [
    CuratedBook(
      id: 'hor-solarpunk',
      title: 'A Psalm for the Wild-Built',
      author: 'Becky Chambers',
      genre: 'Cozy Solarpunk',
      tag: 'Staff Pick',
      rating: 4.7,
      reviewCount: 24000,
      quoteSnippet: 'A gentle, hopeful balm for tired souls pondering life’s purpose.',
      pageCount: 160,
      readTimeEstimate: '3h read',
      synopsis:
          'Centuries after humanity’s robots gained consciousness and peacefully retired to the wilderness, a tea monk meets a curious wild-built robot.',
      catalogSource: 'Foliate Editorial',
    ),
    CuratedBook(
      id: 'hor-philosophy',
      title: 'The Dispossessed',
      author: 'Ursula K. Le Guin',
      genre: 'Mid-Century Philosophy',
      tag: 'Critics\' Choice',
      rating: 4.8,
      reviewCount: 38000,
      quoteSnippet: 'A luminous exploration of freedom, exile, and utopian society.',
      pageCount: 384,
      readTimeEstimate: '8h read',
      synopsis:
          'Physicist Shevek voyages between an anarchic moon collective and a capitalist mother planet seeking to unite divided worlds.',
      catalogSource: 'Foliate Editorial',
    ),
    CuratedBook(
      id: 'hor-nonfiction',
      title: 'Meditations',
      author: 'Marcus Aurelius',
      genre: 'Philosophy',
      tag: 'Essential',
      rating: 4.7,
      reviewCount: 95000,
      quoteSnippet: 'Timeless Stoic wisdom on resilience, duty, and inner tranquility.',
      pageCount: 208,
      readTimeEstimate: '4h read',
      synopsis:
          'Private reflections and practical philosophy written by Roman Emperor Marcus Aurelius during military campaigns.',
      catalogSource: 'Standard Ebooks',
    ),
    CuratedBook(
      id: 'hor-magical-realism',
      title: 'Ficciones',
      author: 'Jorge Luis Borges',
      genre: 'Magical Realism',
      tag: 'Masterpiece',
      rating: 4.6,
      reviewCount: 42000,
      quoteSnippet: 'Labyrinths, infinite libraries, and philosophical riddles.',
      pageCount: 176,
      readTimeEstimate: '3.5h read',
      synopsis:
          'A landmark collection of labyrinthine short stories examining infinity, reality, mirrors, and dreams.',
      catalogSource: 'Foliate Editorial',
    ),
    CuratedBook(
      id: 'hor-classic-scifi',
      title: 'The Left Hand of Darkness',
      author: 'Ursula K. Le Guin',
      genre: 'Classic Sci-Fi',
      tag: 'Groundbreaking',
      rating: 4.6,
      reviewCount: 51000,
      quoteSnippet: 'A profound journey across glaciers exploring identity and solidarity.',
      pageCount: 304,
      readTimeEstimate: '7h read',
      synopsis:
          'Envoy Genly Ai is dispatched to the glacial planet Gethen to facilitate its integration into the galactic ecumen.',
      catalogSource: 'Foliate Editorial',
    ),
  ];
}
