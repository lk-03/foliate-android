import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';

/// Discrete font sizes matching Apple Books typographic scale
const List<double> kAppleBooksFontSizes = [
  12.0,
  14.0,
  16.0,
  18.0,
  20.0,
  23.0,
  27.0,
  32.0,
];

/// Apple Books-style Dotted Font Size Stepper.
///
/// Features a small 'A' on the left, a large 'A' on the right, and a tactile
/// dotted track with discrete snap points. Never displays numeric pt/px labels.
class DottedFontSizeStepper extends StatelessWidget {
  final double currentFontSize;
  final ValueChanged<double> onFontSizeChanged;

  const DottedFontSizeStepper({
    super.key,
    required this.currentFontSize,
    required this.onFontSizeChanged,
  });

  int get _currentIndex {
    int closestIdx = 0;
    double minDiff = double.infinity;
    for (int i = 0; i < kAppleBooksFontSizes.length; i++) {
      final diff = (kAppleBooksFontSizes[i] - currentFontSize).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestIdx = i;
      }
    }
    return closestIdx;
  }

  void _step(int direction) {
    final nextIdx = (_currentIndex + direction).clamp(0, kAppleBooksFontSizes.length - 1);
    if (nextIdx != _currentIndex) {
      HapticFeedback.selectionClick();
      onFontSizeChanged(kAppleBooksFontSizes[nextIdx]);
    }
  }

  void _snapToPosition(double relativeFraction) {
    final targetIdx = (relativeFraction * (kAppleBooksFontSizes.length - 1))
        .round()
        .clamp(0, kAppleBooksFontSizes.length - 1);
    if (targetIdx != _currentIndex) {
      HapticFeedback.selectionClick();
      onFontSizeChanged(kAppleBooksFontSizes[targetIdx]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final totalSteps = kAppleBooksFontSizes.length;
    final activeIdx = _currentIndex;

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
                  fontSize: 13,
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
                                      ? AdwaitaColors.foliateGreen
                                      : colors.textMuted.withValues(alpha: 0.4),
                                ),
                              );
                            }),
                          ),

                          // Active Thumb Pill / Indicator
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 140),
                            curve: Curves.easeOutCubic,
                            left: (trackWidth - 16) * (activeIdx / (totalSteps - 1)),
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AdwaitaColors.foliateGreen,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
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
///
/// Features an interactive drop and retract spring animation, silk texture gradient,
/// and haptic feedback.
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
      duration: const Duration(milliseconds: 380),
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

/// Floating circular trigger button that summons the Apple Books-style reading menu
class FloatingReaderCapsule extends StatelessWidget {
  final VoidCallback onTap;

  const FloatingReaderCapsule({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;

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
            child: const Icon(
              Icons.more_horiz_rounded,
              size: 22,
              color: AdwaitaColors.foliateGreen,
            ),
          ),
        ),
      ),
    );
  }
}

/// Apple Books-style Floating Reader Menu Card.
///
/// A compact, frosted-glass floating card containing quick actions, scrubber slider,
/// and immediate font size adjustment without cluttering the viewport.
class FloatingReaderMenu extends StatelessWidget {
  final double currentFontSize;
  final ValueChanged<double> onFontSizeChanged;
  final double progressPercentage;
  final String progressLabel;
  final ValueChanged<double> onScrubPercentage;
  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;
  final VoidCallback onBackToLibrary;
  final VoidCallback onOpenTOC;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenAppearance;
  final bool isOrientationLocked;
  final VoidCallback onToggleOrientation;

  const FloatingReaderMenu({
    super.key,
    required this.currentFontSize,
    required this.onFontSizeChanged,
    required this.progressPercentage,
    required this.progressLabel,
    required this.onScrubPercentage,
    required this.onPrevPage,
    required this.onNextPage,
    required this.onBackToLibrary,
    required this.onOpenTOC,
    required this.onOpenSearch,
    required this.onOpenAppearance,
    required this.isOrientationLocked,
    required this.onToggleOrientation,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;

    return RepaintBoundary(
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: colors.headerBar.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.border.withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Action Shortcuts Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    label: 'Library',
                    onTap: onBackToLibrary,
                    colors: colors,
                  ),
                  _buildActionButton(
                    icon: Icons.list_rounded,
                    label: 'Contents',
                    onTap: onOpenTOC,
                    colors: colors,
                  ),
                  _buildActionButton(
                    icon: Icons.search_rounded,
                    label: 'Search',
                    onTap: onOpenSearch,
                    colors: colors,
                  ),
                  _buildActionButton(
                    icon: Icons.text_fields_rounded,
                    label: 'Themes',
                    onTap: onOpenAppearance,
                    colors: colors,
                  ),
                  _buildActionButton(
                    icon: isOrientationLocked
                        ? Icons.screen_lock_portrait_rounded
                        : Icons.screen_rotation_rounded,
                    label: isOrientationLocked ? 'Locked' : 'Rotate',
                    isActive: isOrientationLocked,
                    onTap: onToggleOrientation,
                    colors: colors,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 2: Tactile Dotted Font Size Stepper
              DottedFontSizeStepper(
                currentFontSize: currentFontSize,
                onFontSizeChanged: onFontSizeChanged,
              ),
              const SizedBox(height: 10),

              // Row 3: Scrubber Slider with Chevrons
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 24),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onPrevPage();
                    },
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: AdwaitaColors.foliateGreen,
                        inactiveTrackColor: colors.border,
                        thumbColor: AdwaitaColors.foliateGreen,
                      ),
                      child: Slider(
                        value: progressPercentage.clamp(0.0, 100.0),
                        min: 0.0,
                        max: 100.0,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          onScrubPercentage(val);
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 24),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onNextPage();
                    },
                  ),
                ],
              ),

              // Progress details label
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  progressLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ),
            ],
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? AdwaitaColors.foliateGreen : colors.textPrimary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isActive ? AdwaitaColors.foliateGreen : colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
