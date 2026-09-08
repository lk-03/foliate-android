import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../theme/theme.dart';

/// Discrete font sizes matching Apple Books typographic scale starting at 10pt
const List<double> kAppleBooksFontSizes = [
  10.0,
  12.0,
  14.0,
  16.0,
  18.0,
  21.0,
  25.0,
  30.0,
];

/// Apple Books-style Dotted Font Size Stepper.
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
    final activeColor = accentColor ?? AdwaitaColors.foliateGreen;

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
      left: 16,
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

/// Floating three-dot circular button that summons the Apple Books menu
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
    final activeColor = accentColor ?? AdwaitaColors.foliateGreen;

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
              Icons.more_horiz_rounded,
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
        if (loc?.currentLocation != null && loc?.totalLocations != null) {
          final left = (loc!.totalLocations! - loc.currentLocation!).clamp(0, 9999);
          return left == 1 ? '1 page left in chapter' : '$left pages left in chapter';
        }
        final leftPct = (100 - pct).clamp(0.0, 100.0).round();
        return '$leftPct% left in chapter';

      case ProgressDisplayType.timeLeftInChapter:
        final pagesRemaining = (loc?.currentLocation != null && loc?.totalLocations != null)
            ? (loc!.totalLocations! - loc.currentLocation!).clamp(1, 9999)
            : ((100 - pct) / 2).clamp(1.0, 100.0).round();
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

/// Floating Quick Action Toolbar with Scrubber (displayed when quickActionsBar is enabled)
class QuickActionsToolbar extends StatelessWidget {
  final double progressPercentage;
  final ValueChanged<double> onScrubPercentage;
  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;
  final VoidCallback onOpenTOC;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenAppearance;
  final VoidCallback onOpenMenu;
  final Color? accentColor;

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
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final activeColor = accentColor ?? AdwaitaColors.foliateGreen;

    return Positioned(
      bottom: 64 + MediaQuery.of(context).padding.bottom,
      left: 16,
      right: 16,
      child: RepaintBoundary(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.headerBar.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.border.withValues(alpha: 0.8),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick Icon Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.list_rounded, size: 22),
                      tooltip: 'Contents',
                      onPressed: onOpenTOC,
                    ),
                    IconButton(
                      icon: const Icon(Icons.search_rounded, size: 20),
                      tooltip: 'Search',
                      onPressed: onOpenSearch,
                    ),
                    IconButton(
                      icon: const Icon(Icons.text_fields_rounded, size: 20),
                      tooltip: 'Themes & Settings',
                      onPressed: onOpenAppearance,
                    ),
                    IconButton(
                      icon: Icon(Icons.more_horiz_rounded, size: 22, color: activeColor),
                      tooltip: 'Menu',
                      onPressed: onOpenMenu,
                    ),
                  ],
                ),

                // Scrubber Slider
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 22),
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
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          activeTrackColor: activeColor,
                          inactiveTrackColor: colors.border,
                          thumbColor: activeColor,
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
                      icon: const Icon(Icons.chevron_right_rounded, size: 22),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onNextPage();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Apple Books-style Floating Reader Menu Card.
class FloatingReaderMenu extends StatelessWidget {
  final double currentFontSize;
  final ValueChanged<double> onFontSizeChanged;
  final double progressPercentage;
  final String progressLabel;
  final ValueChanged<double> onScrubPercentage;
  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;
  final VoidCallback onClose;
  final VoidCallback? onBackToLibrary;
  final VoidCallback onOpenTOC;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenAppearance;
  final bool isOrientationLocked;
  final VoidCallback onToggleOrientation;
  final ProgressDisplayType progressDisplayType;
  final ValueChanged<ProgressDisplayType> onProgressDisplayTypeChanged;
  final ProgressDisplayLocation progressDisplayLocation;
  final ValueChanged<ProgressDisplayLocation> onProgressDisplayLocationChanged;
  final bool quickActionsBar;
  final ValueChanged<bool> onQuickActionsBarChanged;
  final Color? accentColor;

  const FloatingReaderMenu({
    super.key,
    required this.currentFontSize,
    required this.onFontSizeChanged,
    required this.progressPercentage,
    required this.progressLabel,
    required this.onScrubPercentage,
    required this.onPrevPage,
    required this.onNextPage,
    required this.onClose,
    this.onBackToLibrary,
    required this.onOpenTOC,
    required this.onOpenSearch,
    required this.onOpenAppearance,
    required this.isOrientationLocked,
    required this.onToggleOrientation,
    required this.progressDisplayType,
    required this.onProgressDisplayTypeChanged,
    required this.progressDisplayLocation,
    required this.onProgressDisplayLocationChanged,
    required this.quickActionsBar,
    required this.onQuickActionsBarChanged,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final activeColor = accentColor ?? AdwaitaColors.foliateGreen;
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = screenHeight * 0.60;

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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: Action Shortcuts Bar (Close icon dismisses the popup)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildActionButton(
                            icon: Icons.close_rounded,
                            label: 'Close',
                            onTap: onClose,
                            colors: colors,
                            activeColor: activeColor,
                          ),
                          _buildActionButton(
                            icon: Icons.list_rounded,
                      label: 'Contents',
                      onTap: onOpenTOC,
                      colors: colors,
                      activeColor: activeColor,
                    ),
                    _buildActionButton(
                      icon: Icons.search_rounded,
                      label: 'Search',
                      onTap: onOpenSearch,
                      colors: colors,
                      activeColor: activeColor,
                    ),
                    _buildActionButton(
                      icon: Icons.text_fields_rounded,
                      label: 'Themes',
                      onTap: onOpenAppearance,
                      colors: colors,
                      activeColor: activeColor,
                    ),
                    _buildActionButton(
                      icon: isOrientationLocked
                          ? Icons.screen_lock_portrait_rounded
                          : Icons.screen_rotation_rounded,
                      label: isOrientationLocked ? 'Locked' : 'Rotate',
                      isActive: isOrientationLocked,
                      onTap: onToggleOrientation,
                      colors: colors,
                      activeColor: activeColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Row 2: Tactile Dotted Font Size Stepper
                DottedFontSizeStepper(
                  currentFontSize: currentFontSize,
                  onFontSizeChanged: onFontSizeChanged,
                  accentColor: activeColor,
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
                          activeTrackColor: activeColor,
                          inactiveTrackColor: colors.border,
                          thumbColor: activeColor,
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
                  padding: const EdgeInsets.only(top: 2, bottom: 8),
                  child: Text(
                    progressLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                ),
                Divider(color: colors.border, height: 16),

                // Reading Display Preferences Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reading Display',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    Text(
                      'Tap to cycle',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Display Type Picker Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ProgressDisplayType.values.map((type) {
                      final isSelected = progressDisplayType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(type.label),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                            color: isSelected ? Colors.white : colors.textMuted,
                          ),
                          selected: isSelected,
                          selectedColor: activeColor,
                          backgroundColor: colors.inputBackground,
                          side: BorderSide(color: colors.border),
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            onProgressDisplayTypeChanged(type);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),

                // Quick Action Toolbar Toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  title: const Text(
                    'Quick Action Toolbar',
                    style: TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    'Show quick bar & slider above progress indicator',
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                  ),
                  value: quickActionsBar,
                  activeThumbColor: activeColor,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    onQuickActionsBarChanged(val);
                  },
                ),
              ],
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
