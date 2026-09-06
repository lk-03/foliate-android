import 'package:flutter/material.dart';
import '../components/components.dart';
import '../models/models.dart';
import '../theme/theme.dart';
import 'reader_screen.dart';

/// Screen displaying all starred / favorite books
class FavoritesScreen extends StatelessWidget {
  final List<Book> books;

  const FavoritesScreen({
    super.key,
    required this.books,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final favorites = books.where((b) => b.isFavorite).toList();

    if (favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.surfaceCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border),
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  size: 44,
                  color: AdwaitaColors.libadwaitaRed,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Favorites Yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the heart icon on any book to add it to your favorites.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final book = favorites[index];
        return RecentBookCard(
          book: book,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ReaderScreen(book: book),
              ),
            );
          },
        );
      },
    );
  }
}
