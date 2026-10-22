import 'package:flutter/material.dart';
import '../models/download_task.dart';
import '../services/download_service.dart';
import '../services/storage_service.dart';
import '../theme/theme.dart';
import '../screens/reader_screen.dart';
import 'download_book_details_sheet.dart';

/// Comprehensive download management sheet displaying active transfers,
/// live speeds, pause/resume/cancel controls, and completed history.
class DownloadManagerSheet extends StatelessWidget {
  const DownloadManagerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DownloadManagerSheet(),
    );
  }

  Future<void> _openReader(BuildContext context, DownloadTask task) async {
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
    } else {
      DownloadBookDetailsSheet.show(context, task: task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<FoliateThemeColors>() ?? FoliateThemeColors.dark;
    final primaryAccent = theme.colorScheme.primary;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            // Drag handle & Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  ValueListenableBuilder<List<DownloadTask>>(
                    valueListenable: DownloadService.instance.tasksNotifier,
                    builder: (context, tasks, _) {
                      final activeCount = tasks.where((t) => t.isActive).length;

                      return Row(
                        children: [
                          Icon(Icons.download_rounded, color: primaryAccent, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            'Download Manager',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (activeCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryAccent.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$activeCount active',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: primaryAccent,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (tasks.any((t) => t.isTerminal))
                            TextButton.icon(
                              onPressed: () {
                                DownloadService.instance.clearCompletedTasks();
                              },
                              icon: const Icon(Icons.clear_all_rounded, size: 18),
                              label: const Text('Clear', style: TextStyle(fontSize: 13)),
                              style: TextButton.styleFrom(
                                foregroundColor: colors.textMuted,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.border),

            // Content body
            Expanded(
              child: ValueListenableBuilder<List<DownloadTask>>(
                valueListenable: DownloadService.instance.tasksNotifier,
                builder: (context, tasks, _) {
                  if (tasks.isEmpty) {
                    return _buildEmptyState(colors, primaryAccent);
                  }

                  final activeTasks = tasks.where((t) => t.isActive || t.isPaused).toList();
                  final finishedTasks = tasks.where((t) => t.isTerminal).toList();

                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      // Active Downloads Section
                      if (activeTasks.isNotEmpty) ...[
                        _buildSectionHeader('ACTIVE DOWNLOADS (${activeTasks.length})', colors),
                        const SizedBox(height: 8),
                        ...activeTasks.map((t) => _buildActiveTaskItem(context, t, colors, primaryAccent)),
                        const SizedBox(height: 16),
                      ],

                      // History Section
                      if (finishedTasks.isNotEmpty) ...[
                        _buildSectionHeader('DOWNLOAD HISTORY (${finishedTasks.length})', colors),
                        const SizedBox(height: 8),
                        ...finishedTasks.map((t) => _buildFinishedTaskItem(context, t, colors, primaryAccent)),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, FoliateThemeColors colors) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        color: colors.textMuted,
      ),
    );
  }

  Widget _buildActiveTaskItem(
    BuildContext context,
    DownloadTask task,
    FoliateThemeColors colors,
    Color primaryAccent,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.windowBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => DownloadBookDetailsSheet.show(context, task: task),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildThumbnail(task.coverUrl, colors, primaryAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          task.author,
                          style: TextStyle(fontSize: 12, color: colors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              task.formattedDownloadedSize,
                              style: TextStyle(fontSize: 11, color: colors.textMuted),
                            ),
                            if (task.fileSizeBytes != null) ...[
                              Text(' / ', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                              Text(
                                task.formattedTotalSize,
                                style: TextStyle(fontSize: 11, color: colors.textMuted),
                              ),
                            ],
                            const Spacer(),
                            if (task.formattedSpeed.isNotEmpty)
                              Text(
                                task.formattedSpeed,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: primaryAccent,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Pause / Resume / Cancel Controls
                  if (task.status == DownloadStatus.downloading)
                    IconButton(
                      icon: const Icon(Icons.pause_rounded, size: 22),
                      tooltip: 'Pause',
                      onPressed: () => DownloadService.instance.pauseDownload(task.id),
                    )
                  else if (task.status == DownloadStatus.paused)
                    IconButton(
                      icon: Icon(Icons.play_arrow_rounded, color: primaryAccent, size: 22),
                      tooltip: 'Resume',
                      onPressed: () => DownloadService.instance.resumeDownload(task.id),
                    ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.textMuted, size: 20),
                    tooltip: 'Cancel',
                    onPressed: () => DownloadService.instance.cancelDownload(task.id),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: task.progress > 0 ? task.progress : null,
                  backgroundColor: colors.surfaceCard,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    task.isPaused ? const Color(0xFFE5A50A) : primaryAccent,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinishedTaskItem(
    BuildContext context,
    DownloadTask task,
    FoliateThemeColors colors,
    Color primaryAccent,
  ) {
    final isSuccess = task.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.windowBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: () => DownloadBookDetailsSheet.show(context, task: task),
          leading: _buildThumbnail(task.coverUrl, colors, primaryAccent),
          title: Text(
            task.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                size: 14,
                color: isSuccess ? const Color(0xFF2EC27E) : const Color(0xFFE01B24),
              ),
              const SizedBox(width: 4),
              Text(
                isSuccess ? task.formattedTotalSize : (task.isCancelled ? 'Cancelled' : 'Failed'),
                style: TextStyle(
                  fontSize: 11,
                  color: isSuccess ? const Color(0xFF2EC27E) : colors.textMuted,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSuccess)
                IconButton(
                  icon: Icon(Icons.auto_stories_rounded, color: primaryAccent, size: 20),
                  tooltip: 'Read Book',
                  onPressed: () => _openReader(context, task),
                )
              else
                IconButton(
                  icon: Icon(Icons.refresh_rounded, color: primaryAccent, size: 20),
                  tooltip: 'Retry Download',
                  onPressed: () => DownloadService.instance.retryDownload(task.id),
                ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: colors.textMuted, size: 18),
                tooltip: 'Remove',
                onPressed: () => DownloadService.instance.removeTask(task.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? coverUrl, FoliateThemeColors colors, Color primaryAccent) {
    return Container(
      width: 42,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: colors.surfaceCard,
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: coverUrl != null && coverUrl.isNotEmpty
          ? Image.network(
              coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildThumbFallback(primaryAccent),
            )
          : _buildThumbFallback(primaryAccent),
    );
  }

  Widget _buildThumbFallback(Color primaryAccent) {
    return Center(
      child: Icon(Icons.menu_book_rounded, color: primaryAccent.withValues(alpha: 0.5), size: 20),
    );
  }

  Widget _buildEmptyState(FoliateThemeColors colors, Color primaryAccent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: primaryAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.download_done_rounded, color: primaryAccent, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'No Downloads Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Books downloaded from Open Libraries or external sources will appear here with live transfer speeds and offline storage controls.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
