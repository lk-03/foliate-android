import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../theme/theme.dart';

/// Discrete font sizes matching curated reader typographic scale starting at 10pt
const List<double> kReaderFontSizes = [
  10.0,
  12.0,
  14.0,
  16.0,
  18.0,
  21.0,
  25.0,
  30.0,
];

/// Tactile Dotted Font Size Stepper.
///
/// Features a small 'A' on the left, a large 'A' on the right, and a tactile
/// dotted track with discrete snap points. Never displays numeric pt/px labels.
class DottedFontSizeStepper extends StatelessWidget {
  final double currentFontSize;
  final ValueChanged<double> onFontSizeChanged;
  final Color? accentColor;

  const DottedFontSizeStepper({
    super.key,
    required this.currentFontSize,
    required this.onFontSizeChanged,
    this.accentColor,
  });

  int get _currentIndex {
    int closestIdx = 0;
    double minDiff = double.infinity;
    for (int i = 0; i < kReaderFontSizes.length; i++) {
      final diff = (kReaderFontSizes[i] - currentFontSize).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestIdx = i;
      }
    }
    return closestIdx;
  }

  void _step(int direction) {
    final nextIdx = (_currentIndex + direction).clamp(0, kReaderFontSizes.length - 1);
    if (nextIdx != _currentIndex) {
      HapticFeedback.selectionClick();
      onFontSizeChanged(kReaderFontSizes[nextIdx]);
    }
  }

  void _snapToPosition(double relativeFraction) {
    final targetIdx = (relativeFraction * (kReaderFontSizes.length - 1))
        .round()
        .clamp(0, kReaderFontSizes.length - 1);
    if (targetIdx != _currentIndex) {
      HapticFeedback.selectionClick();
      onFontSizeChanged(kReaderFontSizes[targetIdx]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final totalSteps = kReaderFontSizes.length;
    final activeIdx = _currentIndex;
    final activeColor = accentColor ?? AdwaitaColors.terracottaDark;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            // Smaller 'A' button
            IconButton(
              icon: const Text(
                'A',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              visualDensity: VisualDensity.compact,
              tooltip: 'Smaller Text',
              onPressed: activeIdx > 0 ? () => _step(-1) : null,
            ),
            const SizedBox(width: 4),

            // Dotted Track with Interactive Gestures
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final trackWidth = constraints.maxWidth;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      final fraction = (details.localPosition.dx / trackWidth).clamp(0.0, 1.0);
                      _snapToPosition(fraction);
                    },
                    onHorizontalDragUpdate: (details) {
                      final fraction = (details.localPosition.dx / trackWidth).clamp(0.0, 1.0);
                      _snapToPosition(fraction);
                    },
                    child: SizedBox(
                      height: 36,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // Base horizontal guide line
                          Center(
                            child: Container(
                              height: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: colors.border.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),

                          // Discrete Snap Dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(totalSteps, (index) {
                              final isPassed = index <= activeIdx;
                              return Container(
                                width: index == 0 || index == totalSteps - 1 ? 5 : 4,
                                height: index == 0 || index == totalSteps - 1 ? 5 : 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isPassed
                                      ? activeColor
                                      : colors.textMuted.withValues(alpha: 0.4),
                                ),
                              );
                            }),
                          ),

                          // Active Thumb Indicator
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 140),
                            curve: Curves.easeOutCubic,
                            left: (trackWidth - 16) * (activeIdx / (totalSteps - 1)),
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: activeColor,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 4),

            // Larger 'A' button
            IconButton(
              icon: const Text(
                'A',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              visualDensity: VisualDensity.compact,
              tooltip: 'Larger Text',
              onPressed: activeIdx < totalSteps - 1 ? () => _step(1) : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom clipper that cuts an inverted triangular notch into the bottom of a ribbon
class RibbonClipper extends CustomClipper<Path> {
  final double notchDepth;

  const RibbonClipper({this.notchDepth = 12.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width / 2, size.height - notchDepth);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant RibbonClipper oldClipper) =>
      oldClipper.notchDepth != notchDepth;
}

/// Animated silk ribbon bookmark in the top-right corner of the reader.
class SilkRibbonBookmark extends StatefulWidget {
  final bool isBookmarked;
  final VoidCallback onToggle;

  const SilkRibbonBookmark({
    super.key,
    required this.isBookmarked,
    required this.onToggle,
  });

  @override
  State<SilkRibbonBookmark> createState() => _SilkRibbonBookmarkState();
}

class _SilkRibbonBookmarkState extends State<SilkRibbonBookmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _dropAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _dropAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    if (widget.isBookmarked) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant SilkRibbonBookmark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBookmarked != oldWidget.isBookmarked) {
      if (widget.isBookmarked) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double ribbonWidth = 26.0;
    const double ribbonHeight = 52.0;
    const double hiddenOffset = -ribbonHeight;
    const double visibleOffset = 0.0;

    return Positioned(
      top: 0,
      right: 20,
      child: RepaintBoundary(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onToggle();
          },
          child: SizedBox(
            width: 48,
            height: 64,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Animated Ribbon Drop
                AnimatedBuilder(
                  animation: _dropAnimation,
                  builder: (context, child) {
                    final currentY = hiddenOffset +
                        (visibleOffset - hiddenOffset) * _dropAnimation.value;

                    return Transform.translate(
                      offset: Offset(0, currentY),
                      child: child,
                    );
                  },
                  child: ClipPath(
                    clipper: const RibbonClipper(notchDepth: 10),
                    child: Container(
                      width: ribbonWidth,
                      height: ribbonHeight,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFE01B24), // Libadwaita rich red
                            Color(0xFFC0151E),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 1,
                          height: ribbonHeight - 16,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                ),

                // Subtle Peek Notch indicator when not bookmarked
                if (!widget.isBookmarked)
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 18,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimal frosted-glass circular Close button for the top-left corner
class ReaderCloseButton extends StatelessWidget {
  final VoidCallback onClose;
  final Color? accentColor;

  const ReaderCloseButton({
    super.key,
    required this.onClose,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      right: 18,
      child: RepaintBoundary(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onClose();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.headerBar.withValues(alpha: 0.88),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.border.withValues(alpha: 0.8),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.close_rounded,
                size: 20,
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating circular button that summons the reader menu
class FloatingReaderCapsule extends StatelessWidget {
  final VoidCallback onTap;
  final Color? accentColor;

  const FloatingReaderCapsule({
    super.key,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final activeColor = accentColor ?? AdwaitaColors.terracottaDark;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.headerBar.withValues(alpha: 0.88),
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.border.withValues(alpha: 0.8),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.menu_rounded,
              size: 22,
              color: activeColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Customizable reading progress indicator supporting 1-tap cycling
class ReaderProgressIndicator extends StatelessWidget {
  final ReadingLocation? location;
  final double percentage;
  final ProgressDisplayType displayType;
  final ProgressDisplayLocation displayLocation;
  final VoidCallback onCycleDisplayType;
  final Color? accentColor;

  const ReaderProgressIndicator({
    super.key,
    required this.location,
    required this.percentage,
    required this.displayType,
    required this.displayLocation,
    required this.onCycleDisplayType,
    this.accentColor,
  });

  String _formatText() {
    final loc = location;
    final pct = percentage.clamp(0.0, 100.0);

    switch (displayType) {
      case ProgressDisplayType.pageNumber:
        if (loc?.currentLocation != null &&
            loc?.totalLocations != null &&
            loc!.totalLocations! > 0) {
          return 'Page ${loc.currentLocation} of ${loc.totalLocations}';
        }
        final estimatedPage = (pct * 2.0).clamp(1.0, 200.0).round();
        return 'Page $estimatedPage of 200';

      case ProgressDisplayType.pagesLeftInChapter:
        if (loc != null && loc.pagesLeftInChapter != null) {
          final left = loc.pagesLeftInChapter!;
          return left == 1 ? '1 page left in chapter' : '$left pages left in chapter';
        }
        if (loc != null && loc.chapterTotalPages != null && loc.chapterCurrentPage != null) {
          final left = (loc.chapterTotalPages! - loc.chapterCurrentPage!).clamp(0, 9999);
          return left == 1 ? '1 page left in chapter' : '$left pages left in chapter';
        }
        final leftPct = (100 - pct).clamp(0.0, 100.0).round();
        return '$leftPct% left in chapter';

      case ProgressDisplayType.timeLeftInChapter:
        if (loc != null && loc.timeLeftSectionSeconds != null && loc.timeLeftSectionSeconds! > 0) {
          final mins = (loc.timeLeftSectionSeconds! / 60).round().clamp(1, 9999);
          return mins < 60 ? '$mins min left in chapter' : '${mins ~/ 60}h ${mins % 60}m left in chapter';
        }
        final pagesRemaining = (loc != null && loc.pagesLeftInChapter != null)
            ? loc.pagesLeftInChapter!.clamp(1, 9999)
            : ((loc != null && loc.chapterTotalPages != null && loc.chapterCurrentPage != null)
                ? (loc.chapterTotalPages! - loc.chapterCurrentPage!).clamp(1, 9999)
                : ((100 - pct) / 2).clamp(1.0, 100.0).round());
        final mins = (pagesRemaining * 1.2).round().clamp(1, 9999);
        return mins < 60 ? '$mins min left in chapter' : '${mins ~/ 60}h ${mins % 60}m left in chapter';

      case ProgressDisplayType.timeLeftInBook:
        final totalPages = (loc?.totalLocations != null && loc!.totalLocations! > 0)
            ? loc.totalLocations! * 8
            : 240;
        final remainingPages = ((100 - pct) / 100 * totalPages).round().clamp(1, 99999);
        final mins = (remainingPages * 1.2).round().clamp(1, 99999);
        return mins < 60 ? '$mins min left' : '${mins ~/ 60}h ${mins % 60}m left';

      case ProgressDisplayType.percentage:
        return '${pct.round()}%';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (displayLocation == ProgressDisplayLocation.hidden) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final text = _formatText();
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final pillWidget = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onCycleDisplayType();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.headerBar.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.border.withValues(alpha: 0.6),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: colors.textSecondary,
          ),
        ),
      ),
    );

    switch (displayLocation) {
      case ProgressDisplayLocation.bottomCenter:
        return Positioned(
          bottom: 24 + bottomPadding,
          left: 60,
          right: 60,
          child: Center(child: pillWidget),
        );
      case ProgressDisplayLocation.topCenter:
        return Positioned(
          top: 14 + topPadding,
          left: 60,
          right: 60,
          child: Center(child: pillWidget),
        );
      case ProgressDisplayLocation.bottomLeft:
        return Positioned(
          bottom: 24 + bottomPadding,
          left: 20,
          child: pillWidget,
        );
      case ProgressDisplayLocation.bottomRight:
        return Positioned(
          bottom: 24 + bottomPadding,
          right: 76,
          child: pillWidget,
        );
      case ProgressDisplayLocation.topLeft:
        return Positioned(
          top: 14 + topPadding,
          left: 64,
          child: pillWidget,
        );
      case ProgressDisplayLocation.topRight:
        return Positioned(
          top: 14 + topPadding,
          right: 64,
          child: pillWidget,
        );
      case ProgressDisplayLocation.hidden:
        return const SizedBox.shrink();
    }
  }
}

/// Custom slider track shape that renders vertical chapter tick marks along the line.
/// Matches the Apple Books slider scrub interaction (grows when held, shows chapter tick marks).
class ChapterSliderTrackShape extends RoundedRectSliderTrackShape {
  final List<double> chapterPercentages;
  final bool isDragging;
  final Color activeColor;
  final Color inactiveColor;
  final FoliateThemeColors colors;

  const ChapterSliderTrackShape({
    required this.chapterPercentages,
    required this.isDragging,
    required this.activeColor,
    required this.inactiveColor,
    required this.colors,
  });

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    super.paint(
      context,
      offset,
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      enableAnimation: enableAnimation,
      textDirection: textDirection,
      thumbCenter: thumbCenter,
      secondaryOffset: secondaryOffset,
      isDiscrete: isDiscrete,
      isEnabled: isEnabled,
      additionalActiveTrackHeight: additionalActiveTrackHeight,
    );

    if (chapterPercentages.isEmpty) return;

    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isDiscrete: isDiscrete,
      isEnabled: isEnabled,
    );

    final trackWidth = trackRect.width;
    final trackLeft = trackRect.left;
    final centerY = trackRect.center.dy;

    // Tick height and width grow when held/dragged, matching reference screenshot
    final tickHalfHeight = isDragging ? 5.5 : 3.5;
    final tickWidth = isDragging ? 1.8 : 1.2;

    final inactiveTickPaint = Paint()
      ..color = colors.textMuted.withValues(alpha: isDragging ? 0.70 : 0.40)
      ..strokeWidth = tickWidth
      ..strokeCap = StrokeCap.round;

    final activeTickPaint = Paint()
      ..color = colors.windowBackground.withValues(alpha: isDragging ? 0.90 : 0.65)
      ..strokeWidth = tickWidth
      ..strokeCap = StrokeCap.round;

    for (final pct in chapterPercentages) {
      if (pct <= 0.0 || pct >= 100.0) continue;
      final x = trackLeft + (pct / 100.0) * trackWidth;

      // Do not draw tick under the thumb
      if ((x - thumbCenter.dx).abs() < (isDragging ? 8.0 : 5.0)) continue;

      final isPast = x < thumbCenter.dx;
      context.canvas.drawLine(
        Offset(x, centerY - tickHalfHeight),
        Offset(x, centerY + tickHalfHeight),
        isPast ? activeTickPaint : inactiveTickPaint,
      );
    }
  }
}

/// Floating bottom page scrubber slider bar that appears when tapping the reader screen.
/// Features tactile sticky magnetic snapping to chapter marks, holding size expansion,
/// and vertical chapter ticks along the track line.
class ReaderPageSliderBar extends StatefulWidget {
  final double progressPercentage;
  final ValueChanged<double> onScrubPercentage;
  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;
  final ReadingLocation? location;
  final String? pageLabel;
  final Color? accentColor;
  final List<TOCItem> toc;

  const ReaderPageSliderBar({
    super.key,
    required this.progressPercentage,
    required this.onScrubPercentage,
    required this.onPrevPage,
    required this.onNextPage,
    this.location,
    this.pageLabel,
    this.accentColor,
    this.toc = const [],
  });

  @override
  State<ReaderPageSliderBar> createState() => _ReaderPageSliderBarState();
}

class _ReaderPageSliderBarState extends State<ReaderPageSliderBar> {
  bool _isDragging = false;
  double? _currentScrubPct;
  int? _lastStuckMarkerIndex;
  Timer? _throttleTimer;
  double? _pendingScrubValue;

  @override
  void dispose() {
    _throttleTimer?.cancel();
    super.dispose();
  }

  List<({double percentage, String title, int? pageNumber})> _getChapterMarkers() {
    final totalLocations = widget.location?.totalLocations ?? 0;
    final markers = <({double percentage, String title, int? pageNumber})>[];

    void recurse(List<TOCItem> list) {
      for (final item in list) {
        final page = item.digitalPageNumber ?? item.pageNumber;
        if (page != null && totalLocations > 0) {
          final pct = ((page - 1) / (totalLocations > 1 ? totalLocations - 1 : 1) * 100.0)
              .clamp(0.0, 100.0);
          markers.add((percentage: pct, title: item.label, pageNumber: page));
        }
        if (item.subitems.isNotEmpty) {
          recurse(item.subitems);
        }
      }
    }

    recurse(widget.toc);
    markers.sort((a, b) => a.percentage.compareTo(b.percentage));

    final unique = <({double percentage, String title, int? pageNumber})>[];
    for (final m in markers) {
      if (unique.isEmpty || (m.percentage - unique.last.percentage).abs() > 0.4) {
        unique.add(m);
      }
    }
    return unique;
  }

  double _applyStickySnap(double rawVal, List<({double percentage, String title, int? pageNumber})> markers) {
    if (markers.isEmpty) {
      _lastStuckMarkerIndex = null;
      return rawVal;
    }

    // Gentle magnetic snapping zone of ~1.2%
    const double snapWindow = 1.2;
    const double deadZone = 0.5;

    for (int i = 0; i < markers.length; i++) {
      final m = markers[i];
      final dist = (rawVal - m.percentage).abs();
      if (dist <= snapWindow) {
        if (dist <= deadZone) {
          if (_lastStuckMarkerIndex != i) {
            _lastStuckMarkerIndex = i;
            HapticFeedback.selectionClick();
          }
          return m.percentage;
        } else {
          final factor = (dist - deadZone) / (snapWindow - deadZone);
          final pulled = m.percentage +
              (rawVal - m.percentage).sign *
                  (deadZone + (snapWindow - deadZone) * (factor * factor));
          return pulled.clamp(0.0, 100.0);
        }
      }
    }
    _lastStuckMarkerIndex = null;
    return rawVal;
  }

  void _handleThrottledScrub(double val) {
    _pendingScrubValue = val;
    if (_throttleTimer?.isActive ?? false) return;
    _throttleTimer = Timer(const Duration(milliseconds: 60), () {
      if (_pendingScrubValue != null && mounted) {
        widget.onScrubPercentage(_pendingScrubValue!);
      }
    });
  }

  String _formatPageLabel(List<({double percentage, String title, int? pageNumber})> markers) {
    if (_isDragging && _lastStuckMarkerIndex != null && _lastStuckMarkerIndex! < markers.length) {
      final m = markers[_lastStuckMarkerIndex!];
      if (m.pageNumber != null) {
        return '${m.title}  •  Page ${m.pageNumber}';
      }
      return '${m.title}  •  ${m.percentage.round()}%';
    }

    if (_isDragging && _currentScrubPct != null) {
      final totalLocations = widget.location?.totalLocations ?? 0;
      if (totalLocations > 0) {
        final scrubPage = ((_currentScrubPct! / 100.0) * (totalLocations - 1) + 1).round().clamp(1, totalLocations);
        return 'Page $scrubPage of $totalLocations  •  ${_currentScrubPct!.round()}%';
      }
      return '${_currentScrubPct!.round()}%';
    }

    if (widget.pageLabel != null && widget.pageLabel!.isNotEmpty) return widget.pageLabel!;
    if (widget.location?.currentLocation != null &&
        widget.location!.totalLocations != null &&
        widget.location!.totalLocations! > 0) {
      return 'Page ${widget.location!.currentLocation} of ${widget.location!.totalLocations}';
    }
    final estimatedPage = (widget.progressPercentage * 2.0).clamp(1.0, 200.0).round();
    if (widget.progressPercentage > 0) {
      return 'Page $estimatedPage of 200  •  ${widget.progressPercentage.round()}%';
    }
    return '${widget.progressPercentage.round()}%';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final activeColor = widget.accentColor ?? AdwaitaColors.terracottaDark;
    final chapterMarkers = _getChapterMarkers();
    final pageText = _formatPageLabel(chapterMarkers);
    final displayValue = (_currentScrubPct ?? widget.progressPercentage).clamp(0.0, 100.0);

    return Positioned(
      bottom: 16 + MediaQuery.of(context).padding.bottom,
      left: 18,
      right: 74,
      child: RepaintBoundary(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Page Number Badge centered above slider bar
            AnimatedScale(
              scale: _isDragging ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3.5),
                decoration: BoxDecoration(
                  color: colors.headerBar.withValues(alpha: _isDragging ? 0.98 : 0.92),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isDragging
                        ? activeColor.withValues(alpha: 0.6)
                        : colors.border.withValues(alpha: 0.8),
                    width: _isDragging ? 1.0 : 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _isDragging ? 0.35 : 0.2),
                      blurRadius: _isDragging ? 10 : 6,
                      offset: Offset(0, _isDragging ? 3 : 2),
                    ),
                  ],
                ),
                child: Text(
                  pageText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: _isDragging ? colors.textPrimary : colors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              height: _isDragging ? 52 : 44,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: colors.headerBar.withValues(alpha: _isDragging ? 0.98 : 0.92),
                borderRadius: BorderRadius.circular(_isDragging ? 26 : 22),
                border: Border.all(
                  color: _isDragging
                      ? activeColor.withValues(alpha: 0.6)
                      : colors.border.withValues(alpha: 0.8),
                  width: _isDragging ? 1.2 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isDragging ? 0.45 : 0.3),
                    blurRadius: _isDragging ? 16 : 12,
                    offset: Offset(0, _isDragging ? 6 : 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 22),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      widget.onPrevPage();
                    },
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: _isDragging ? 6.0 : 3.5,
                        trackShape: ChapterSliderTrackShape(
                          chapterPercentages: chapterMarkers.map((m) => m.percentage).toList(),
                          isDragging: _isDragging,
                          activeColor: activeColor,
                          inactiveColor: colors.border,
                          colors: colors,
                        ),
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: _isDragging ? 9.0 : 6.0,
                          elevation: _isDragging ? 4 : 1,
                        ),
                        overlayShape: RoundSliderOverlayShape(
                          overlayRadius: _isDragging ? 18.0 : 14.0,
                        ),
                        activeTrackColor: activeColor,
                        inactiveTrackColor: colors.border,
                        thumbColor: activeColor,
                      ),
                      child: Slider(
                        value: displayValue,
                        min: 0.0,
                        max: 100.0,
                        onChangeStart: (val) {
                          setState(() {
                            _isDragging = true;
                            _currentScrubPct = val;
                          });
                          HapticFeedback.selectionClick();
                        },
                        onChanged: (rawVal) {
                          final snapped = _applyStickySnap(rawVal, chapterMarkers);
                          setState(() => _currentScrubPct = snapped);
                          _handleThrottledScrub(snapped);
                        },
                        onChangeEnd: (finalVal) {
                          final snapped = _applyStickySnap(finalVal, chapterMarkers);
                          _throttleTimer?.cancel();
                          setState(() {
                            _isDragging = false;
                            _currentScrubPct = null;
                            _lastStuckMarkerIndex = null;
                          });
                          widget.onScrubPercentage(snapped);
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 22),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      widget.onNextPage();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating Quick Action Toolbar with Scrubber (backwards-compatibility wrapper)
class QuickActionsToolbar extends StatelessWidget {
  final double progressPercentage;
  final ValueChanged<double> onScrubPercentage;
  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;
  final VoidCallback onOpenTOC;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenAppearance;
  final VoidCallback onOpenMenu;
  final ReadingLocation? location;
  final String? pageLabel;
  final Color? accentColor;
  final List<TOCItem> toc;

  const QuickActionsToolbar({
    super.key,
    required this.progressPercentage,
    required this.onScrubPercentage,
    required this.onPrevPage,
    required this.onNextPage,
    required this.onOpenTOC,
    required this.onOpenSearch,
    required this.onOpenAppearance,
    required this.onOpenMenu,
    this.location,
    this.pageLabel,
    this.accentColor,
    this.toc = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ReaderPageSliderBar(
      progressPercentage: progressPercentage,
      onScrubPercentage: onScrubPercentage,
      onPrevPage: onPrevPage,
      onNextPage: onNextPage,
      location: location,
      pageLabel: pageLabel,
      accentColor: accentColor,
      toc: toc,
    );
  }
}

class ReaderThemeOption {
  final String label;
  final ReaderThemeMode mode;
  final bool isDark;
  final Color bg;
  final Color text;

  const ReaderThemeOption({
    required this.label,
    required this.mode,
    required this.isDark,
    required this.bg,
    required this.text,
  });
}

const List<ReaderThemeOption> kReaderThemeOptions = [
  ReaderThemeOption(
    label: 'White',
    mode: ReaderThemeMode.defaultTheme,
    isDark: false,
    bg: Color(0xFFFFFFFF),
    text: Color(0xFF1A1A1A),
  ),
  ReaderThemeOption(
    label: 'Calm Sepia',
    mode: ReaderThemeMode.sepia,
    isDark: false,
    bg: Color(0xFFF8F1E5),
    text: Color(0xFF4D3826),
  ),
  ReaderThemeOption(
    label: 'Warm Cream',
    mode: ReaderThemeMode.solarized,
    isDark: false,
    bg: Color(0xFFFDF6E3),
    text: Color(0xFF5F4B32),
  ),
  ReaderThemeOption(
    label: 'Sepia Dark',
    mode: ReaderThemeMode.sepia,
    isDark: true,
    bg: Color(0xFF24201C),
    text: Color(0xFFD4C5B0),
  ),
  ReaderThemeOption(
    label: 'Quiet Black',
    mode: ReaderThemeMode.night,
    isDark: true,
    bg: Color(0xFF1E1D1B),
    text: Color(0xFFEDEDED),
  ),
  ReaderThemeOption(
    label: 'Contrast Black',
    mode: ReaderThemeMode.black,
    isDark: true,
    bg: Color(0xFF000000),
    text: Color(0xFFD1D1D6),
  ),
  ReaderThemeOption(
    label: 'Grey',
    mode: ReaderThemeMode.gray,
    isDark: true,
    bg: Color(0xFF2E2E2E),
    text: Color(0xFFD8D8D8),
  ),
  ReaderThemeOption(
    label: 'Gruvbox',
    mode: ReaderThemeMode.gruvbox,
    isDark: true,
    bg: Color(0xFF282828),
    text: Color(0xFFEBDBB2),
  ),
];

/// Floating Reader Menu bottom sheet.
class FloatingReaderMenu extends StatefulWidget {
  final double currentFontSize;
  final ValueChanged<double> onFontSizeChanged;
  final VoidCallback onClose;
  final VoidCallback? onBackToLibrary;
  final VoidCallback onOpenTOC;
  final VoidCallback onOpenSearch;
  final VoidCallback? onOpenAppearance;
  final VoidCallback? onOpenLayout;
  final VoidCallback? onOpenThemeCustomize;
  final bool isOrientationLocked;
  final VoidCallback onToggleOrientation;
  final ReaderThemeMode currentTheme;
  final bool isDarkMode;
  final void Function(ReaderThemeMode theme, bool isDarkMode)? onThemeChanged;
  final String? currentFontFamily;
  final ValueChanged<String>? onFontFamilyChanged;
  final bool overridePublisherFont;
  final ValueChanged<bool>? onOverridePublisherFontChanged;
  final int? fontWeight;
  final ValueChanged<int>? onFontWeightChanged;
  final double lineHeight;
  final ValueChanged<double>? onLineHeightChanged;
  final bool fullJustification;
  final ValueChanged<bool>? onFullJustificationChanged;
  final bool hyphenation;
  final ValueChanged<bool>? onHyphenationChanged;
  final String pageFlipping;
  final ValueChanged<String>? onPageFlippingChanged;
  final ProgressDisplayType? progressDisplayType;
  final ValueChanged<ProgressDisplayType>? onProgressDisplayTypeChanged;
  final ProgressDisplayLocation? progressDisplayLocation;
  final ValueChanged<ProgressDisplayLocation>? onProgressDisplayLocationChanged;
  final bool showPageSlider;
  final ValueChanged<bool>? onShowPageSliderChanged;
  final bool? quickActionsBar;
  final ValueChanged<bool>? onQuickActionsBarChanged;
  final double? progressPercentage;
  final String? progressLabel;
  final ValueChanged<double>? onScrubPercentage;
  final VoidCallback? onPrevPage;
  final VoidCallback? onNextPage;
  final Color? accentColor;
  final double brightness;
  final ValueChanged<double>? onBrightnessChanged;
  final bool isStayAwake;
  final VoidCallback? onToggleStayAwake;
  final VoidCallback? onStartTTS;

  const FloatingReaderMenu({
    super.key,
    required this.currentFontSize,
    required this.onFontSizeChanged,
    required this.onClose,
    this.onBackToLibrary,
    required this.onOpenTOC,
    required this.onOpenSearch,
    this.onOpenAppearance,
    this.onOpenLayout,
    this.onOpenThemeCustomize,
    this.onStartTTS,
    required this.isOrientationLocked,
    required this.onToggleOrientation,
    this.currentTheme = ReaderThemeMode.defaultTheme,
    this.isDarkMode = true,
    this.onThemeChanged,
    this.currentFontFamily = 'serif',
    this.onFontFamilyChanged,
    this.overridePublisherFont = true,
    this.onOverridePublisherFontChanged,
    this.fontWeight = 400,
    this.onFontWeightChanged,
    this.lineHeight = 1.5,
    this.onLineHeightChanged,
    this.fullJustification = true,
    this.onFullJustificationChanged,
    this.hyphenation = true,
    this.onHyphenationChanged,
    this.pageFlipping = 'horizontal',
    this.onPageFlippingChanged,
    this.progressDisplayType,
    this.onProgressDisplayTypeChanged,
    this.progressDisplayLocation,
    this.onProgressDisplayLocationChanged,
    this.showPageSlider = false,
    this.onShowPageSliderChanged,
    this.quickActionsBar,
    this.onQuickActionsBarChanged,
    this.progressPercentage,
    this.progressLabel,
    this.onScrubPercentage,
    this.onPrevPage,
    this.onNextPage,
    this.accentColor,
    this.brightness = 1.0,
    this.onBrightnessChanged,
    this.isStayAwake = false,
    this.onToggleStayAwake,
  });

  @override
  State<FloatingReaderMenu> createState() => _FloatingReaderMenuState();
}

class _FloatingReaderMenuState extends State<FloatingReaderMenu> {
  late double _brightness;

  @override
  void initState() {
    super.initState();
    _brightness = widget.brightness;
  }

  @override
  void didUpdateWidget(covariant FloatingReaderMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.brightness != widget.brightness) {
      _brightness = widget.brightness;
    }
  }

  bool _isOptionSelected(ReaderThemeOption opt) {
    if (opt.mode == ReaderThemeMode.defaultTheme) {
      return (widget.currentTheme == ReaderThemeMode.defaultTheme ||
              widget.currentTheme == ReaderThemeMode.day) &&
          !widget.isDarkMode;
    }
    if (opt.mode == ReaderThemeMode.night) {
      return widget.currentTheme == ReaderThemeMode.night ||
          (widget.currentTheme == ReaderThemeMode.defaultTheme && widget.isDarkMode);
    }
    return widget.currentTheme == opt.mode;
  }

  String _getActiveThemeLabel() {
    for (final opt in kReaderThemeOptions) {
      if (_isOptionSelected(opt)) return opt.label;
    }
    return widget.currentTheme.name;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final activeColor = widget.accentColor ?? AdwaitaColors.terracottaDark;
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = (screenHeight * 0.60).clamp(340.0, 560.0);

    return RepaintBoundary(
      child: Container(
        height: sheetHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.headerBar.withValues(alpha: 0.98),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: colors.border.withValues(alpha: 0.8),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // Top Drag Handle
                Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  decoration: BoxDecoration(
                    color: colors.border.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Row 1: Action Shortcuts Bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildActionButton(
                                  icon: Icons.close_rounded,
                                  label: 'Close',
                                  onTap: widget.onClose,
                                  colors: colors,
                                  activeColor: activeColor,
                                ),
                                _buildActionButton(
                                  icon: Icons.list_rounded,
                                  label: 'Contents',
                                  onTap: widget.onOpenTOC,
                                  colors: colors,
                                  activeColor: activeColor,
                                ),
                                _buildActionButton(
                                  icon: Icons.search_rounded,
                                  label: 'Search',
                                  onTap: widget.onOpenSearch,
                                  colors: colors,
                                  activeColor: activeColor,
                                ),
                                if (widget.onStartTTS != null)
                                  _buildActionButton(
                                    icon: Icons.headphones_rounded,
                                    label: 'Listen',
                                    onTap: widget.onStartTTS!,
                                    colors: colors,
                                    activeColor: activeColor,
                                  ),
                                _buildActionButton(
                                  icon: Icons.auto_stories_rounded,
                                  label: 'Layout',
                                  onTap: () {
                                    if (widget.onOpenLayout != null) {
                                      widget.onOpenLayout!();
                                    } else if (widget.onOpenAppearance != null) {
                                      widget.onOpenAppearance!();
                                    }
                                  },
                                  colors: colors,
                                  activeColor: activeColor,
                                ),
                                _buildActionButton(
                                  icon: widget.isStayAwake
                                      ? Icons.remove_red_eye_rounded
                                      : Icons.remove_red_eye_outlined,
                                  label: widget.isStayAwake ? 'Awake' : 'Sleep',
                                  isActive: widget.isStayAwake,
                                  onTap: () => widget.onToggleStayAwake?.call(),
                                  colors: colors,
                                  activeColor: activeColor,
                                ),
                                _buildActionButton(
                                  icon: widget.isOrientationLocked
                                      ? Icons.screen_lock_portrait_rounded
                                      : Icons.screen_rotation_rounded,
                                  label: widget.isOrientationLocked ? 'Locked' : 'Rotate',
                                  isActive: widget.isOrientationLocked,
                                  onTap: widget.onToggleOrientation,
                                  colors: colors,
                                  activeColor: activeColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Row 2: Tactile Dotted Font Size Stepper + Light/Dark Pill
                            Row(
                              children: [
                                Expanded(
                                  child: DottedFontSizeStepper(
                                    currentFontSize: widget.currentFontSize,
                                    onFontSizeChanged: widget.onFontSizeChanged,
                                    accentColor: activeColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    widget.onThemeChanged?.call(widget.currentTheme, !widget.isDarkMode);
                                  },
                                  child: Container(
                                    height: 50,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: colors.inputBackground,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: colors.border),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          widget.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                          size: 16,
                                          color: activeColor,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          widget.isDarkMode ? 'Dark' : 'Light',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Row 3: Brightness Slider
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.inputBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.brightness_low_rounded, size: 18, color: colors.textMuted),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 3,
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                        activeTrackColor: activeColor,
                                        inactiveTrackColor: colors.border,
                                        thumbColor: Colors.white,
                                      ),
                                      child: Slider(
                                        value: _brightness,
                                        min: 0.2,
                                        max: 1.0,
                                        onChanged: (val) {
                                          setState(() => _brightness = val);
                                          widget.onBrightnessChanged?.call(val);
                                        },
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.brightness_high_rounded, size: 19, color: colors.textPrimary),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Row 4: Reading Theme Palettes Section Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Theme Palette',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textSecondary,
                                  ),
                                ),
                                Text(
                                  _getActiveThemeLabel(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Vertically Scrollable Theme Grid
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.45,
                          ),
                          itemCount: kReaderThemeOptions.length,
                          itemBuilder: (context, index) {
                            final opt = kReaderThemeOptions[index];
                            final isSelected = _isOptionSelected(opt);
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                widget.onThemeChanged?.call(opt.mode, opt.isDark);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                decoration: BoxDecoration(
                                  color: opt.bg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? activeColor
                                        : colors.border.withValues(alpha: 0.8),
                                    width: isSelected ? 2.5 : 1.0,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: activeColor.withValues(alpha: 0.35),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Aa',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: opt.text,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          opt.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: opt.text.withValues(alpha: 0.85),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (isSelected)
                                      Positioned(
                                        top: 4,
                                        right: 6,
                                        child: Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: activeColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Row 5: Customize Font & Typography Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            if (widget.onOpenThemeCustomize != null) {
                              widget.onOpenThemeCustomize!();
                            } else if (widget.onOpenAppearance != null) {
                              widget.onOpenAppearance!();
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: colors.surfaceCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.tune_rounded, size: 18, color: activeColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Customize Font & Typography',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required FoliateThemeColors colors,
    required Color activeColor,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? activeColor : colors.textPrimary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isActive ? activeColor : colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

