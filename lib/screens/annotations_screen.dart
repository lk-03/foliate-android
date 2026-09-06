import 'package:flutter/material.dart';
import '../components/components.dart';
import '../models/models.dart';
import '../theme/theme.dart';

/// Screen displaying all user highlights and annotations across books
class AnnotationsScreen extends StatelessWidget {
  final List<Annotation> annotations;
  final Map<String, Book> booksMap;
  final ValueChanged<Annotation>? onAnnotationTap;

  const AnnotationsScreen({
    super.key,
    required this.annotations,
    required this.booksMap,
    this.onAnnotationTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;

    if (annotations.isEmpty) {
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
                  Icons.bookmarks_outlined,
                  size: 44,
                  color: AdwaitaColors.foliateGreen,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Annotations Yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Select any text while reading to highlight passages and save notes.',
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
      itemCount: annotations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = annotations[index];
        final book = booksMap[item.bookHash];

        return AnnotationCard(
          annotation: item,
          bookTitle: book?.title,
          onTap: () => onAnnotationTap?.call(item),
        );
      },
    );
  }
}
