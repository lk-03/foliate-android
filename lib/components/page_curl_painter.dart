import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../models/reader_settings.dart';

/// Interactive 3D Page Curl direction
enum PageCurlDirection {
  forward, // Turning next page (curling from right to left)
  backward, // Turning previous page (curling from left to right)
}

/// A high-performance 3D skeuomorphic page curl painter
class PageCurlPainter extends CustomPainter {
  final double progress; // 0.0 (flat) to 1.0 (fully turned)
  final PageCurlDirection direction;
  final Color backgroundColor;
  final Color textColor;
  final bool isDarkMode;
  final Offset? touchPoint;

  PageCurlPainter({
    required this.progress,
    required this.direction,
    required this.backgroundColor,
    required this.textColor,
    required this.isDarkMode,
    this.touchPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;
    if (progress >= 1.0) return;

    final width = size.width;
    final height = size.height;

    // Target drag position based on progress or touch
    final isForward = direction == PageCurlDirection.forward;
    final double dragX = isForward
        ? (touchPoint?.dx ?? width * (1.0 - progress))
        : (touchPoint?.dx ?? width * progress);
    final double dragY = touchPoint?.dy ?? height * 0.85;

    // Fold line parameters
    final originCorner = Offset(isForward ? width : 0.0, height);
    final currentPos = Offset(dragX.clamp(0.0, width), dragY.clamp(0.0, height));
    final delta = currentPos - originCorner;
    final dist = delta.distance;
    if (dist < 1.0) return;

    // Angle of the fold
    final angle = math.atan2(delta.dy, delta.dx);
    final midPoint = Offset(
      (originCorner.dx + currentPos.dx) / 2,
      (originCorner.dy + currentPos.dy) / 2,
    );

    // Compute fold line perpendicular to corner-drag vector
    final normalAngle = angle + math.pi / 2;
    final foldRadius = (width * 0.18).clamp(24.0, 70.0);

    // 1. Draw Drop Shadow on Revealed Page Below
    _drawUnderPageShadow(canvas, size, midPoint, normalAngle, isForward);

    // 2. Draw Curled Leaf (Backside of Page)
    _drawCurledLeaf(canvas, size, originCorner, currentPos, midPoint, normalAngle, foldRadius, isForward);
  }

  void _drawUnderPageShadow(
    Canvas canvas,
    Size size,
    Offset midPoint,
    double normalAngle,
    bool isForward,
  ) {
    final shadowWidth = (size.width * 0.12).clamp(16.0, 48.0);
    final shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: isForward ? Alignment.centerRight : Alignment.centerLeft,
        end: isForward ? Alignment.centerLeft : Alignment.centerRight,
        colors: [
          Colors.black.withValues(alpha: isDarkMode ? 0.45 : 0.22),
          Colors.black.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(
        midPoint.dx - shadowWidth,
        0,
        shadowWidth * 2,
        size.height,
      ));

    final shadowPath = Path()
      ..moveTo(midPoint.dx - (isForward ? shadowWidth : -shadowWidth), 0)
      ..lineTo(midPoint.dx + (isForward ? shadowWidth * 0.5 : -shadowWidth * 0.5), 0)
      ..lineTo(midPoint.dx + (isForward ? shadowWidth * 0.5 : -shadowWidth * 0.5), size.height)
      ..lineTo(midPoint.dx - (isForward ? shadowWidth : -shadowWidth), size.height)
      ..close();

    canvas.drawPath(shadowPath, shadowPaint);
  }

  void _drawCurledLeaf(
    Canvas canvas,
    Size size,
    Offset originCorner,
    Offset currentPos,
    Offset midPoint,
    double normalAngle,
    double foldRadius,
    bool isForward,
  ) {
    // Backside Paper Color Tint
    final undersideColor = isDarkMode
        ? Color.lerp(backgroundColor, Colors.white, 0.08)!
        : Color.lerp(backgroundColor, Colors.black, 0.04)!;

    final leafPath = Path();
    if (isForward) {
      leafPath.moveTo(size.width, 0);
      leafPath.lineTo(midPoint.dx, 0);
      leafPath.lineTo(currentPos.dx, currentPos.dy);
      leafPath.lineTo(midPoint.dx, size.height);
      leafPath.lineTo(size.width, size.height);
      leafPath.close();
    } else {
      leafPath.moveTo(0, 0);
      leafPath.lineTo(midPoint.dx, 0);
      leafPath.lineTo(currentPos.dx, currentPos.dy);
      leafPath.lineTo(midPoint.dx, size.height);
      leafPath.lineTo(0, size.height);
      leafPath.close();
    }

    // Cylindrical Lighting Gradient on Paper Backside
    final leafPaint = Paint()
      ..shader = LinearGradient(
        begin: isForward ? Alignment.centerRight : Alignment.centerLeft,
        end: isForward ? Alignment.centerLeft : Alignment.centerRight,
        colors: [
          undersideColor,
          isDarkMode
              ? undersideColor.withValues(alpha: 0.95)
              : Color.lerp(undersideColor, Colors.white, 0.15)!,
          undersideColor,
          isDarkMode
              ? Color.lerp(undersideColor, Colors.black, 0.25)!
              : Color.lerp(undersideColor, Colors.black, 0.12)!,
        ],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(leafPath, leafPaint);

    // Subtle Paper Ridge Highlight
    final ridgePaint = Paint()
      ..color = Colors.white.withValues(alpha: isDarkMode ? 0.12 : 0.28)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(midPoint.dx, 0),
      Offset(currentPos.dx, currentPos.dy),
      ridgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant PageCurlPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.direction != direction ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.isDarkMode != isDarkMode ||
        oldDelegate.touchPoint != touchPoint;
  }
}

/// Overlay widget that manages page-turn curl gestures and spring animations
class PageCurlOverlay extends StatefulWidget {
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
  State<PageCurlOverlay> createState() => PageCurlOverlayState();
}

class PageCurlOverlayState extends State<PageCurlOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  PageCurlDirection _direction = PageCurlDirection.forward;
  Offset? _touchPosition;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Triggers a programmatic page turn animation with curl physics
  void animateTurn(PageCurlDirection direction) {
    if (!widget.enabled || _animController.isAnimating) return;
    setState(() {
      _direction = direction;
      _touchPosition = null;
    });

    _animController.forward(from: 0.0).then((_) {
      if (direction == PageCurlDirection.forward) {
        widget.onNextPage();
      } else {
        widget.onPrevPage();
      }
      _animController.reset();
    });
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (!widget.enabled || _animController.isAnimating) return;
    final width = context.size?.width ?? 360.0;
    final isForward = details.localPosition.dx > width * 0.5;

    setState(() {
      _isDragging = true;
      _direction = isForward ? PageCurlDirection.forward : PageCurlDirection.backward;
      _touchPosition = details.localPosition;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    final width = context.size?.width ?? 360.0;
    final dx = details.localPosition.dx;

    final progress = _direction == PageCurlDirection.forward
        ? ((width - dx) / width).clamp(0.0, 1.0)
        : (dx / width).clamp(0.0, 1.0);

    setState(() {
      _touchPosition = details.localPosition;
      _animController.value = progress;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final velocity = details.primaryVelocity ?? 0.0;
    final isForward = _direction == PageCurlDirection.forward;
    final shouldComplete = isForward
        ? (_animController.value > 0.30 || velocity < -400.0)
        : (_animController.value > 0.30 || velocity > 400.0);

    if (shouldComplete) {
      final simulation = SpringSimulation(
        const SpringDescription(mass: 1.0, stiffness: 180.0, damping: 20.0),
        _animController.value,
        1.0,
        (velocity / 1000.0).abs(),
      );
      _animController.animateWith(simulation).then((_) {
        if (isForward) {
          widget.onNextPage();
        } else {
          widget.onPrevPage();
        }
        _animController.reset();
      });
    } else {
      final simulation = SpringSimulation(
        const SpringDescription(mass: 1.0, stiffness: 220.0, damping: 22.0),
        _animController.value,
        0.0,
        (velocity / 1000.0).abs(),
      );
      _animController.animateWith(simulation).then((_) {
        _animController.reset();
      });
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_isDragging || _animController.isAnimating) return;
    final width = context.size?.width ?? 360.0;
    final x = details.localPosition.dx;
    final ratio = x / width;

    if (ratio < 0.28) {
      if (widget.settings.pageAnimationMode == PageAnimationMode.curl) {
        animateTurn(PageCurlDirection.backward);
      } else {
        widget.onPrevPage();
      }
    } else if (ratio > 0.72) {
      if (widget.settings.pageAnimationMode == PageAnimationMode.curl) {
        animateTurn(PageCurlDirection.forward);
      } else {
        widget.onNextPage();
      }
    } else {
      widget.onToggleHUD();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: _onTapUp,
      onHorizontalDragStart: widget.settings.pageAnimationMode == PageAnimationMode.curl
          ? _onHorizontalDragStart
          : null,
      onHorizontalDragUpdate: widget.settings.pageAnimationMode == PageAnimationMode.curl
          ? _onHorizontalDragUpdate
          : null,
      onHorizontalDragEnd: widget.settings.pageAnimationMode == PageAnimationMode.curl
          ? _onHorizontalDragEnd
          : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (widget.settings.pageAnimationMode == PageAnimationMode.curl &&
              _animController.value > 0.0)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: PageCurlPainter(
                    progress: _animController.value,
                    direction: _direction,
                    backgroundColor: widget.backgroundColor,
                    textColor: widget.textColor,
                    isDarkMode: widget.settings.isDarkMode,
                    touchPoint: _touchPosition,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
