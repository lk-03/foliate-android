import 'package:flutter/foundation.dart';

/// Represents a curated editorial book recommendation for Open Library Gems
/// and Explore Horizons sections on the Home dashboard.
@immutable
class CuratedBook {
  final String id;
  final String title;
  final String author;
  final String genre;
  final String nicheId;
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
    this.nicheId = '',
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
      nicheId: 'gothic',
      tag: 'Public Domain',
      coverUrl: 'https://covers.openlibrary.org/b/id/12356249-M.jpg',
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
      nicheId: 'classics',
      tag: 'Public Domain',
      coverUrl: 'https://covers.openlibrary.org/b/id/14348537-M.jpg',
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
      nicheId: 'philosophy',
      tag: 'Public Domain',
      coverUrl: 'https://covers.openlibrary.org/b/id/14314858-M.jpg',
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
      nicheId: 'psychological',
      tag: 'Public Domain',
      coverUrl: 'https://covers.openlibrary.org/b/id/6889547-M.jpg',
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
      nicheId: 'adventure',
      tag: 'Public Domain',
      coverUrl: 'https://covers.openlibrary.org/b/id/10544254-M.jpg',
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
    // Solarpunk
    CuratedBook(
      id: 'hor-solarpunk',
      title: 'A Psalm for the Wild-Built',
      author: 'Becky Chambers',
      genre: 'Cozy Solarpunk',
      nicheId: 'solarpunk',
      tag: 'Staff Pick',
      coverUrl: 'https://covers.openlibrary.org/b/id/10476616-M.jpg',
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
      id: 'hor-dispossessed',
      title: 'The Dispossessed',
      author: 'Ursula K. Le Guin',
      genre: 'Mid-Century Philosophy',
      nicheId: 'solarpunk',
      tag: 'Critics\' Choice',
      coverUrl: 'https://covers.openlibrary.org/b/id/6979680-M.jpg',
      rating: 4.8,
      reviewCount: 38000,
      quoteSnippet: 'A luminous exploration of freedom, exile, and utopian society.',
      pageCount: 384,
      readTimeEstimate: '8h read',
      synopsis:
          'Physicist Shevek voyages between an anarchic moon collective and a capitalist mother planet seeking to unite divided worlds.',
      catalogSource: 'Foliate Editorial',
    ),

    // Philosophy
    CuratedBook(
      id: 'hor-meditations',
      title: 'Meditations',
      author: 'Marcus Aurelius',
      genre: 'Philosophy',
      nicheId: 'philosophy',
      tag: 'Essential',
      coverUrl: 'https://covers.openlibrary.org/b/id/13202688-M.jpg',
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
      id: 'hor-republic',
      title: 'The Republic',
      author: 'Plato',
      genre: 'Philosophy',
      nicheId: 'philosophy',
      tag: 'Classic Canon',
      coverUrl: 'https://covers.openlibrary.org/b/id/8231856-M.jpg',
      rating: 4.4,
      reviewCount: 65000,
      quoteSnippet: 'Foundational Socratic dialogue examining justice, virtue, and the ideal state.',
      pageCount: 416,
      readTimeEstimate: '9h read',
      synopsis:
          'Socrates and Athenian intellectuals debate justice, the soul, and political harmony through the allegory of the cave.',
      catalogSource: 'Project Gutenberg',
    ),

    // Science Fiction
    CuratedBook(
      id: 'hor-classic-scifi',
      title: 'The Left Hand of Darkness',
      author: 'Ursula K. Le Guin',
      genre: 'Classic Sci-Fi',
      nicheId: 'scifi',
      tag: 'Groundbreaking',
      coverUrl: 'https://covers.openlibrary.org/b/id/10618463-M.jpg',
      rating: 4.6,
      reviewCount: 51000,
      quoteSnippet: 'A profound journey across glaciers exploring identity and solidarity.',
      pageCount: 304,
      readTimeEstimate: '7h read',
      synopsis:
          'Envoy Genly Ai is dispatched to the glacial planet Gethen to facilitate its integration into the galactic ecumen.',
      catalogSource: 'Foliate Editorial',
    ),
    CuratedBook(
      id: 'hor-war-worlds',
      title: 'The War of the Worlds',
      author: 'H. G. Wells',
      genre: 'Science Fiction',
      nicheId: 'scifi',
      tag: 'Pioneer',
      coverUrl: 'https://covers.openlibrary.org/b/id/12411132-M.jpg',
      rating: 4.3,
      reviewCount: 44000,
      quoteSnippet: 'The iconic Martian invasion that inaugurated modern science fiction.',
      pageCount: 192,
      readTimeEstimate: '4h read',
      synopsis:
          'A cataclysmic conflict in Victorian England when technologically advanced invaders arrive from the Red Planet.',
      catalogSource: 'Standard Ebooks',
    ),

    // Cyberpunk & Dystopia
    CuratedBook(
      id: 'hor-1984',
      title: '1984',
      author: 'George Orwell',
      genre: 'Cyberpunk & Dystopia',
      nicheId: 'cyberpunk',
      tag: 'Masterpiece',
      coverUrl: 'https://covers.openlibrary.org/b/id/7222246-M.jpg',
      rating: 4.8,
      reviewCount: 185000,
      quoteSnippet: 'A terrifying prophecy of totalitarian control and manufactured truth.',
      pageCount: 328,
      readTimeEstimate: '7h read',
      synopsis:
          'Winston Smith navigates the all-seeing surveillance of Big Brother while attempting quiet personal resistance.',
      catalogSource: 'Project Gutenberg',
    ),
    CuratedBook(
      id: 'hor-brave-new-world',
      title: 'Brave New World',
      author: 'Aldous Huxley',
      genre: 'Dystopian',
      nicheId: 'cyberpunk',
      tag: 'Visionary',
      coverUrl: 'https://covers.openlibrary.org/b/id/8775432-M.jpg',
      rating: 4.5,
      reviewCount: 92000,
      quoteSnippet: 'An engineered society of painless pleasure and synthetic conformity.',
      pageCount: 288,
      readTimeEstimate: '6h read',
      synopsis:
          'A futuristic World State where citizens are genetically conditioned and socially stratified from birth.',
      catalogSource: 'Project Gutenberg',
    ),

    // Fantasy & Mythic Lore
    CuratedBook(
      id: 'hor-magical-realism',
      title: 'Ficciones',
      author: 'Jorge Luis Borges',
      genre: 'Magical Realism',
      nicheId: 'fantasy',
      tag: 'Masterpiece',
      coverUrl: 'https://covers.openlibrary.org/b/id/10832290-M.jpg',
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
      id: 'hor-odyssey',
      title: 'The Odyssey',
      author: 'Homer',
      genre: 'Epic Fantasy & Myth',
      nicheId: 'fantasy',
      tag: 'Ancient Epic',
      coverUrl: 'https://covers.openlibrary.org/b/id/8314112-M.jpg',
      rating: 4.5,
      reviewCount: 78000,
      quoteSnippet: 'The ten-year homeward voyage across monster-haunted Mediterranean seas.',
      pageCount: 384,
      readTimeEstimate: '8h read',
      synopsis:
          'Odysseus overcomes wrathful gods, sirens, cyclopes, and sorceresses to return home to Ithaca.',
      catalogSource: 'Standard Ebooks',
    ),

    // Gothic & Dark Mystery
    CuratedBook(
      id: 'hor-dracula',
      title: 'Dracula',
      author: 'Bram Stoker',
      genre: 'Gothic Horror',
      nicheId: 'gothic',
      tag: 'Classic Horror',
      coverUrl: 'https://covers.openlibrary.org/b/id/11153218-M.jpg',
      rating: 4.5,
      reviewCount: 89000,
      quoteSnippet: 'Epistolary dread spanning Transylvanian castles and fog-choked Victorian harbors.',
      pageCount: 418,
      readTimeEstimate: '9h read',
      synopsis:
          'Count Dracula journeys to England to spread his vampiric curse, opposed by Professor Van Helsing and companions.',
      catalogSource: 'Standard Ebooks',
    ),

    // Classic Literature
    CuratedBook(
      id: 'hor-great-expectations',
      title: 'Great Expectations',
      author: 'Charles Dickens',
      genre: 'Classic Literature',
      nicheId: 'classics',
      tag: 'Victorian Canon',
      coverUrl: 'https://covers.openlibrary.org/b/id/8235118-M.jpg',
      rating: 4.4,
      reviewCount: 67000,
      quoteSnippet: 'Fortune, class elevation, and the search for authentic honor in Victorian London.',
      pageCount: 544,
      readTimeEstimate: '11h read',
      synopsis:
          'Orphan Pip rises into high society aided by an anonymous benefactor, uncovering startling family secrets.',
      catalogSource: 'Project Gutenberg',
    ),

    // Psychological Fiction & Noir
    CuratedBook(
      id: 'hor-crime-punishment',
      title: 'Crime and Punishment',
      author: 'Fyodor Dostoevsky',
      genre: 'Psychological Fiction',
      nicheId: 'psychological',
      tag: 'Psychological Peak',
      coverUrl: 'https://covers.openlibrary.org/b/id/12818862-M.jpg',
      rating: 4.7,
      reviewCount: 114000,
      quoteSnippet: 'An agonizing psychological breakdown driven by guilt, fever, and moral reckoning.',
      pageCount: 576,
      readTimeEstimate: '13h read',
      synopsis:
          'Impoverished student Raskolnikov rationalizes a murder only to be pursued by detective Porfiry and his own conscience.',
      catalogSource: 'Standard Ebooks',
    ),

    // Adventure & Maritime
    CuratedBook(
      id: 'hor-treasure-island',
      title: 'Treasure Island',
      author: 'Robert Louis Stevenson',
      genre: 'Adventure',
      nicheId: 'adventure',
      tag: 'Classic Adventure',
      coverUrl: 'https://covers.openlibrary.org/b/id/10321455-M.jpg',
      rating: 4.4,
      reviewCount: 58000,
      quoteSnippet: 'Sailing ships, buried pirate gold, and the treacherous charm of Long John Silver.',
      pageCount: 224,
      readTimeEstimate: '5h read',
      synopsis:
          'Young Jim Hawkins discovers a pirate treasure map and embarks aboard the Hispaniola into mutiny and peril.',
      catalogSource: 'Project Gutenberg',
    ),

    // Poetry & Verse
    CuratedBook(
      id: 'hor-leaves-grass',
      title: 'Leaves of Grass',
      author: 'Walt Whitman',
      genre: 'Poetry & Lyrical Verse',
      nicheId: 'poetry',
      tag: 'Lyrical Epic',
      coverUrl: 'https://covers.openlibrary.org/b/id/8312014-M.jpg',
      rating: 4.3,
      reviewCount: 26000,
      quoteSnippet: 'Free-verse hymns to nature, democracy, and the electric interconnectedness of life.',
      pageCount: 462,
      readTimeEstimate: '8h read',
      synopsis:
          'Walt Whitman’s lifelong poetry collection celebrating human existence, selfhood, and natural landscapes.',
      catalogSource: 'Project Gutenberg',
    ),

    // Romance & Manners
    CuratedBook(
      id: 'hor-jane-eyre',
      title: 'Jane Eyre',
      author: 'Charlotte Bronte',
      genre: 'Romance & Drama',
      nicheId: 'romance',
      tag: 'Gothic Romance',
      coverUrl: 'https://covers.openlibrary.org/b/id/12521140-M.jpg',
      rating: 4.7,
      reviewCount: 105000,
      quoteSnippet: 'Unflinching moral integrity, passionate devotion, and dark secrets at Thornfield Hall.',
      pageCount: 507,
      readTimeEstimate: '10h read',
      synopsis:
          'Governess Jane Eyre falls deeply in love with the brooding Mr. Rochester, leading to a trial of faith and independence.',
      catalogSource: 'Project Gutenberg',
    ),

    // History & Chronicles
    CuratedBook(
      id: 'hor-art-of-war',
      title: 'The Art of War',
      author: 'Sun Tzu',
      genre: 'History & Strategy',
      nicheId: 'history',
      tag: 'Timeless Strategy',
      coverUrl: 'https://covers.openlibrary.org/b/id/8230231-M.jpg',
      rating: 4.4,
      reviewCount: 72000,
      quoteSnippet: 'Ancient strategic treatises on conflict, psychological deterrence, and wisdom.',
      pageCount: 112,
      readTimeEstimate: '2.5h read',
      synopsis:
          'Classical Chinese military treatise offering philosophical maxims on leadership, discipline, and diplomacy.',
      catalogSource: 'Project Gutenberg',
    ),
  ];

  /// Returns the complete combined pool of curated books.
  static List<CuratedBook> get allCuratedBooks {
    final seen = <String>{};
    final result = <CuratedBook>[];
    for (final book in [...openLibraryGems, ...exploreHorizons]) {
      if (seen.add(book.id)) {
        result.add(book);
      }
    }
    return result;
  }
}
