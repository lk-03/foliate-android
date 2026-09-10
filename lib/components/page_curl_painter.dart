import 'package:flutter/material.dart';
import '../models/reader_settings.dart';

/// Clean reader gesture overlay that handles edge taps and HUD toggle
/// while letting native swipe gestures flow smoothly to the reading engine.
class PageCurlOverlay extends StatelessWidget {
  final Widget child;
  final ReaderSettings settings;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onNextPage;
  final VoidCallback onPrevPage;
  final VoidCallback onToggleHUD;
  final bool enabled;

  const PageCurlOverlay({
    super.key,
    required this.child,
    required this.settings,
    required this.backgroundColor,
    required this.textColor,
    required this.onNextPage,
    required this.onPrevPage,
    required this.onToggleHUD,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final width = MediaQuery.of(context).size.width;
    final edgeWidth = width * 0.28;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        // Left Edge Strip (Tap to go Prev)
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: edgeWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onPrevPage,
            onLongPress: () {},
          ),
        ),
        // Right Edge Strip (Tap to go Next)
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: edgeWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onNextPage,
            onLongPress: () {},
          ),
        ),
        // Center Area (Tap to toggle HUD)
        Positioned(
          left: edgeWidth,
          right: edgeWidth,
          top: 0,
          bottom: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onToggleHUD,
            onLongPress: () {},
          ),
        ),
      ],
    );
  }
}
