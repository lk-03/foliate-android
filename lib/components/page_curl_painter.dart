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

  void _onTapUp(BuildContext context, TapUpDetails details) {
    if (!enabled) return;
    final width = MediaQuery.of(context).size.width;
    final x = details.localPosition.dx;
    final ratio = x / width;

    if (ratio < 0.28) {
      onPrevPage();
    } else if (ratio > 0.72) {
      onNextPage();
    } else {
      onToggleHUD();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (details) => _onTapUp(context, details),
          ),
        ),
      ],
    );
  }
}
