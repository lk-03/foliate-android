import 'package:flutter/material.dart';

/// Represents a distinct literary niche or genre category used for
/// personalized book recommendations and catalog browsing.
@immutable
class ReadingNiche {
  final String id;
  final String label;
  final String shortLabel;
  final String description;
  final IconData icon;
  final String openLibrarySubject;
  final List<String> keywords;

  const ReadingNiche({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.icon,
    required this.openLibrarySubject,
    this.keywords = const [],
  });

  /// Curated list of all supported reading niches in Foliate.
  static const List<ReadingNiche> allNiches = [
    ReadingNiche(
      id: 'philosophy',
      label: 'Philosophy & Stoicism',
      shortLabel: 'Philosophy',
      description: 'Meditations, ethics, existential thought, and moral inquiry',
      icon: Icons.psychology_outlined,
      openLibrarySubject: 'philosophy',
      keywords: ['philosophy', 'stoic', 'ethics', 'existential', 'meditations', 'wisdom'],
    ),
    ReadingNiche(
      id: 'scifi',
      label: 'Science Fiction & Space',
      shortLabel: 'Sci-Fi',
      description: 'Galactic voyages, time travel, alien encounters, and cosmic scale',
      icon: Icons.rocket_launch_outlined,
      openLibrarySubject: 'science_fiction',
      keywords: ['sci-fi', 'science fiction', 'space', 'galaxy', 'future', 'alien', 'cosmos'],
    ),
    ReadingNiche(
      id: 'gothic',
      label: 'Gothic & Dark Mystery',
      shortLabel: 'Gothic Mystery',
      description: 'Atmospheric dread, haunted ruins, psychological horror, and dark intrigue',
      icon: Icons.castle_outlined,
      openLibrarySubject: 'gothic_fiction',
      keywords: ['gothic', 'mystery', 'horror', 'macabre', 'victorian', 'supernatural'],
    ),
    ReadingNiche(
      id: 'classics',
      label: 'Classic Literature & Canon',
      shortLabel: 'Classics',
      description: 'Foundational novels, enduring drama, and literary milestones',
      icon: Icons.auto_stories_outlined,
      openLibrarySubject: 'classic_literature',
      keywords: ['classic', 'literature', 'canon', 'novel', 'prose', 'historical'],
    ),
    ReadingNiche(
      id: 'cyberpunk',
      label: 'Cyberpunk & Dystopia',
      shortLabel: 'Cyberpunk',
      description: 'High-tech subterranean cities, artificial minds, and totalitarian futures',
      icon: Icons.terminal_outlined,
      openLibrarySubject: 'dystopian',
      keywords: ['cyberpunk', 'dystopia', 'dystopian', 'hacker', 'surveillance', 'technology'],
    ),
    ReadingNiche(
      id: 'solarpunk',
      label: 'Solarpunk & Hopepunk',
      shortLabel: 'Solarpunk',
      description: 'Ecological harmony, community resilience, and restorative optimism',
      icon: Icons.eco_outlined,
      openLibrarySubject: 'environment',
      keywords: ['solarpunk', 'hopepunk', 'nature', 'ecology', 'optimism', 'community'],
    ),
    ReadingNiche(
      id: 'fantasy',
      label: 'Fantasy & Mythic Lore',
      shortLabel: 'Fantasy',
      description: 'Ancient mythologies, heroic quests, sorcery, and magical realism',
      icon: Icons.auto_awesome_outlined,
      openLibrarySubject: 'fantasy',
      keywords: ['fantasy', 'myth', 'magic', 'legend', 'quest', 'sorcery', 'folklore'],
    ),
    ReadingNiche(
      id: 'adventure',
      label: 'Adventure & Maritime Journeys',
      shortLabel: 'Adventure',
      description: 'High seas expeditions, treacherous survival, and unmapped frontiers',
      icon: Icons.explore_outlined,
      openLibrarySubject: 'adventure',
      keywords: ['adventure', 'sea', 'voyage', 'ship', 'ocean', 'expedition', 'survival'],
    ),
    ReadingNiche(
      id: 'psychological',
      label: 'Psychological Fiction & Noir',
      shortLabel: 'Psychology',
      description: 'Inner torment, moral ambiguity, unreliable minds, and hardboiled noir',
      icon: Icons.visibility_outlined,
      openLibrarySubject: 'psychological_fiction',
      keywords: ['psychological', 'noir', 'crime', 'guilt', 'mind', 'confession'],
    ),
    ReadingNiche(
      id: 'poetry',
      label: 'Poetry & Lyrical Verse',
      shortLabel: 'Poetry',
      description: 'Transcendent verse, epic poems, sonnets, and contemplative stanzas',
      icon: Icons.history_edu_outlined,
      openLibrarySubject: 'poetry',
      keywords: ['poetry', 'verse', 'poem', 'sonnet', 'rhyme', 'lyrical', 'stanzas'],
    ),
    ReadingNiche(
      id: 'romance',
      label: 'Romance & Comedy of Manners',
      shortLabel: 'Romance',
      description: 'Wit, societal drama, enduring passion, and intricate courtship',
      icon: Icons.favorite_border_rounded,
      openLibrarySubject: 'romance',
      keywords: ['romance', 'love', 'courtship', 'society', 'passion', 'marriage'],
    ),
    ReadingNiche(
      id: 'history',
      label: 'History & Chronicles',
      shortLabel: 'History',
      description: 'True chronicles of civilizations, revolutionary epochs, and memoirs',
      icon: Icons.menu_book_outlined,
      openLibrarySubject: 'history',
      keywords: ['history', 'historical', 'biography', 'memoir', 'empire', 'revolution'],
    ),
  ];

  /// Default starting niches suggested for a balanced reading taste profile.
  static const List<String> defaultNicheIds = [
    'philosophy',
    'classics',
    'scifi',
    'gothic',
  ];

  /// Finds a niche by ID or returns null if not found.
  static ReadingNiche? findById(String id) {
    try {
      return allNiches.firstWhere(
        (n) => n.id.toLowerCase() == id.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Finds a niche by its label or short label.
  static ReadingNiche? findByName(String name) {
    try {
      final query = name.trim().toLowerCase();
      return allNiches.firstWhere(
        (n) =>
            n.id.toLowerCase() == query ||
            n.label.toLowerCase() == query ||
            n.shortLabel.toLowerCase() == query ||
            n.keywords.any((k) => k.toLowerCase() == query),
      );
    } catch (_) {
      return null;
    }
  }
}
