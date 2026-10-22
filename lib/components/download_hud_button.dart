import 'package:flutter/material.dart';
import '../models/download_task.dart';
import '../services/download_service.dart';
import '../theme/theme.dart';
import 'download_manager_sheet.dart';

/// Top HUD button displaying active download badge and progress animation.
/// Tapping opens the DownloadManagerSheet.
class DownloadHudButton extends StatelessWidget {
  final bool inAppBar;

  const DownloadHudButton({
    super.key,
    this.inAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<FoliateThemeColors>() ?? FoliateThemeColors.dark;
    final primaryAccent = theme.colorScheme.primary;

    return ValueListenableBuilder<List<DownloadTask>>(
      valueListenable: DownloadService.instance.tasksNotifier,
      builder: (context, tasks, _) {
        final activeTasks = tasks.where((t) => t.isActive).toList();
        final hasActive = activeTasks.isNotEmpty;
        final activeCount = activeTasks.length;
        final totalProgress = DownloadService.instance.totalActiveProgress;

        if (inAppBar) {
          return IconButton(
            icon: Stack(
              alignment: Alignment.center,
              children: [
                if (hasActive)
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      value: totalProgress > 0 ? totalProgress : null,
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                    ),
                  ),
                Icon(
                  hasActive ? Icons.downloading_rounded : Icons.download_rounded,
                  size: 20,
                  color: hasActive ? primaryAccent : colors.textPrimary,
                ),
                if (hasActive)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: primaryAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '$activeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: hasActive ? '$activeCount active downloads' : 'Downloads',
            onPressed: () => DownloadManagerSheet.show(context),
          );
        }

        // Header button variant (for HomeScreen row)
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => DownloadManagerSheet.show(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: hasActive
                    ? primaryAccent.withValues(alpha: 0.15)
                    : colors.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasActive
                      ? primaryAccent.withValues(alpha: 0.4)
                      : colors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasActive)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        value: totalProgress > 0 ? totalProgress : null,
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                      ),
                    )
                  else
                    Icon(
                      Icons.download_rounded,
                      size: 16,
                      color: colors.textMuted,
                    ),
                  const SizedBox(width: 5),
                  Text(
                    hasActive ? '$activeCount Active' : 'Downloads',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasActive ? primaryAccent : colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
