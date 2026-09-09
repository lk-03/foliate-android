import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../theme/theme.dart';

/// Card displaying a saved text highlight / note snippet with Libadwaita styling
class AnnotationCard extends StatelessWidget {
  final Annotation annotation;
  final String? bookTitle;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;

  const AnnotationCard({
    super.key,
    required this.annotation,
    this.bookTitle,
    required this.onTap,
    this.onEdit,
    this.onCopy,
    this.onDelete,
  });

  Color _parseHighlightColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFFFFE066);
    }
  }

  String _formatDate(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: annotation.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quote copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final highlightColor = _parseHighlightColor(annotation.color);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quote Snippet with Left Color Bar
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: highlightColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '“${annotation.text}”',
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Note (if present)
              if (annotation.note != null && annotation.note!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.inputBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.edit_note_rounded, size: 16, color: colors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          annotation.note!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              // Footer: Book Title, Date, and Actions Menu
              Row(
                children: [
                  const Icon(
                    Icons.bookmark_rounded,
                    size: 14,
                    color: AdwaitaColors.foliateGreen,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      bookTitle ?? 'Unknown Book',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(annotation.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textMuted,
                    ),
                  ),
                  // Three-Dot Context Menu
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, size: 18, color: colors.textMuted),
                    tooltip: 'More options',
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    color: colors.surfaceCard,
                    onSelected: (action) {
                      switch (action) {
                        case 'copy':
                          if (onCopy != null) {
                            onCopy!();
                          } else {
                            _copyToClipboard(context);
                          }
                          break;
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.copy_rounded, size: 16, color: colors.textPrimary),
                            const SizedBox(width: 8),
                            const Text('Copy Quote', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      if (onEdit != null)
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 16, color: colors.textPrimary),
                              const SizedBox(width: 8),
                              const Text('Edit Note', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              const Text('Delete', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
