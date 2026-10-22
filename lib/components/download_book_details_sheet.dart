import 'dart:io';
import 'package:flutter/material.dart';
import '../models/download_task.dart';
import '../services/download_service.dart';
import '../services/storage_service.dart';
import '../theme/theme.dart';
import '../screens/reader_screen.dart';

/// Modal inspection sheet displaying deep book metadata, download statistics,
/// file paths, and direct reading/management actions.
class DownloadBookDetailsSheet extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback? onTaskUpdated;

  const DownloadBookDetailsSheet({
    super.key,
    required this.task,
    this.onTaskUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required DownloadTask task,
    VoidCallback? onTaskUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DownloadBookDetailsSheet(
        task: task,
        onTaskUpdated: onTaskUpdated,
      ),
    );
  }

  Future<void> _openReader(BuildContext context) async {
    final books = await StorageService.instance.getBooks();
    final book = books.where((b) {
      if (task.localFilePath != null && b.filePath == task.localFilePath) {
        return true;
      }
      return b.hash == task.id;
    }).firstOrNull;

    if (!context.mounted) return;

    if (book != null) {
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReaderScreen(book: book),
        ),
      );
    } else if (task.localFilePath != null && File(task.localFilePath!).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book file exists on disk and is indexed in your Library.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book file could not be found locally.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _getStatusColor(DownloadStatus status, Color primaryAccent) {
    switch (status) {
      case DownloadStatus.completed:
        return const Color(0xFF2EC27E); // Adwaita success green
      case DownloadStatus.downloading:
        return primaryAccent;
      case DownloadStatus.paused:
        return const Color(0xFFE5A50A); // Adwaita warning amber
      case DownloadStatus.failed:
        return const Color(0xFFE01B24); // Adwaita error red
      case DownloadStatus.cancelled:
        return Colors.grey;
      case DownloadStatus.queued:
        return primaryAccent.withValues(alpha: 0.7);
    }
  }

  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
      case DownloadStatus.queued:
        return 'Queued';
    }
  }

  String _formatDate(int? timestamp) {
    if (timestamp == null || timestamp == 0) return 'Unknown';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<FoliateThemeColors>() ?? FoliateThemeColors.dark;
    final primaryAccent = theme.colorScheme.primary;
    final statusColor = _getStatusColor(task.status, primaryAccent);

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: colors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top section: tactile cover & book title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book Cover
                Container(
                  width: 80,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: colors.windowBackground,
                    border: Border.all(color: colors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: task.coverUrl != null && task.coverUrl!.isNotEmpty
                      ? Image.network(
                          task.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildFallbackCover(colors, primaryAccent),
                        )
                      : _buildFallbackCover(colors, primaryAccent),
                ),
                const SizedBox(width: 16),

                // Title, Author & Status Chip
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.author,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // Status pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _getStatusText(task.status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Progress bar if active or paused
            if (task.isActive || task.isPaused) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: task.progress > 0 ? task.progress : null,
                  backgroundColor: colors.windowBackground,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${task.formattedDownloadedSize} / ${task.formattedTotalSize}',
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                  ),
                  Text(
                    task.formattedSpeed.isNotEmpty
                        ? '${task.formattedProgress} - ${task.formattedSpeed}'
                        : task.formattedProgress,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Error display if failed
            if (task.isFailed && task.error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE01B24).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE01B24).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFE01B24), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        task.error!,
                        style: const TextStyle(fontSize: 13, color: Color(0xFFE01B24)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Metadata card
            Container(
              decoration: BoxDecoration(
                color: colors.windowBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  _buildMetaTile('Download URL', task.downloadUrl, colors, isLink: true),
                  Divider(height: 1, color: colors.border),
                  _buildMetaTile('Total File Size', task.formattedTotalSize, colors),
                  Divider(height: 1, color: colors.border),
                  _buildMetaTile('Downloaded Bytes', task.formattedDownloadedSize, colors),
                  if (task.localFilePath != null) ...[
                    Divider(height: 1, color: colors.border),
                    _buildMetaTile('Storage Location', task.localFilePath!, colors),
                  ],
                  Divider(height: 1, color: colors.border),
                  _buildMetaTile('Started At', _formatDate(task.startedAt), colors),
                  if (task.completedAt != null) ...[
                    Divider(height: 1, color: colors.border),
                    _buildMetaTile('Completed At', _formatDate(task.completedAt), colors),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actions
            if (task.isCompleted) ...[
              FilledButton.icon(
                onPressed: () => _openReader(context),
                icon: const Icon(Icons.auto_stories_rounded, size: 20),
                label: const Text('Read Now', style: TextStyle(fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else if (task.isActive) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        DownloadService.instance.pauseDownload(task.id);
                        onTaskUpdated?.call();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.pause_rounded, size: 20),
                      label: const Text('Pause'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () {
                        DownloadService.instance.cancelDownload(task.id);
                        onTaskUpdated?.call();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close_rounded, size: 20),
                      label: const Text('Cancel'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (task.isPaused) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        DownloadService.instance.resumeDownload(task.id);
                        onTaskUpdated?.call();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text('Resume'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        DownloadService.instance.removeTask(task.id);
                        onTaskUpdated?.call();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      label: const Text('Remove'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (task.isFailed || task.isCancelled) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        DownloadService.instance.retryDownload(task.id);
                        onTaskUpdated?.call();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: const Text('Retry'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        DownloadService.instance.removeTask(task.id);
                        onTaskUpdated?.call();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildMetaTile(String title, String value, FoliateThemeColors colors, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: colors.textPrimary,
                fontFamily: isLink ? 'monospace' : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackCover(FoliateThemeColors colors, Color primaryAccent) {
    return Container(
      color: colors.windowBackground,
      child: Center(
        child: Icon(
          Icons.menu_book_rounded,
          color: primaryAccent.withValues(alpha: 0.6),
          size: 32,
        ),
      ),
    );
  }
}
