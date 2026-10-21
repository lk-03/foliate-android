import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../theme/theme.dart';

/// Floating audio control capsule for Text-to-Speech chapter narration
class TtsFloatingBar extends StatelessWidget {
  final TtsPlaybackState state;
  final int currentIndex;
  final int totalParagraphs;
  final double speechRate;
  final String? chapterTitle;
  final Color accentColor;
  final bool isDarkMode;
  final VoidCallback onPlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCycleSpeed;
  final VoidCallback onClose;

  const TtsFloatingBar({
    super.key,
    required this.state,
    required this.currentIndex,
    required this.totalParagraphs,
    required this.speechRate,
    this.chapterTitle,
    required this.accentColor,
    this.isDarkMode = true,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onCycleSpeed,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final isPlaying = state == TtsPlaybackState.playing;

    final bg = isDarkMode
        ? const Color(0xE6242424)
        : const Color(0xF2F6F6F6);
    final borderColor = isDarkMode
        ? colors.border.withValues(alpha: 0.35)
        : colors.border.withValues(alpha: 0.4);
    final textPrimary = isDarkMode ? Colors.white : colors.textPrimary;
    final textSecondary = isDarkMode
        ? colors.textMuted
        : colors.textSecondary;

    final title = (chapterTitle != null && chapterTitle!.trim().isNotEmpty)
        ? chapterTitle!.trim()
        : 'Reading Aloud';

    final progressText = totalParagraphs > 0
        ? 'Paragraph ${currentIndex + 1} of $totalParagraphs'
        : 'Reading Chapter';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Row: Status & Close
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaying ? Icons.graphic_eq_rounded : Icons.headphones_rounded,
                          color: accentColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              progressText,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Speed chip
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onCycleSpeed,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            child: Text(
                              '${speechRate}x',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Close button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onClose,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: textSecondary,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Controls Row: Prev, Play/Pause, Next
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Previous paragraph
                      IconButton(
                        onPressed: onPrevious,
                        icon: const Icon(Icons.skip_previous_rounded),
                        color: textPrimary,
                        iconSize: 26,
                        splashRadius: 22,
                        tooltip: 'Previous Paragraph',
                      ),
                      const SizedBox(width: 14),
                      // Play / Pause Circle
                      Material(
                        color: accentColor,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onPlayPause,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: isDarkMode ? Colors.black87 : Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Next paragraph
                      IconButton(
                        onPressed: onNext,
                        icon: const Icon(Icons.skip_next_rounded),
                        color: textPrimary,
                        iconSize: 26,
                        splashRadius: 22,
                        tooltip: 'Next Paragraph',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
