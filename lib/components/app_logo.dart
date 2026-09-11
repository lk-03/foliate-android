import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Dynamic vector App Logo widget recreating Variant 2 (Pure Paper & Subtle Shadows).
/// Dynamically adapts to the application UI color scheme, surfaces, and active accent color.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showTile;
  final Color? tileColor;
  final Gradient? tileGradient;
  final Color? accentColor;
  final Color? pageColor;
  final VoidCallback? onTap;

  const AppLogo({
    super.key,
    this.size = 32,
    this.showTile = true,
    this.tileColor,
    this.tileGradient,
    this.accentColor,
    this.pageColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final resolvedAccent = accentColor ?? Theme.of(context).colorScheme.primary;
    final resolvedPage = pageColor ?? const Color(0xFFFAF7F0);

    // Default black gradient background (guaranteed in light mode and default)
    final resolvedGradient = tileGradient ??
        (tileColor == null
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF28282D),
                  Color(0xFF141416),
                ],
              )
            : null);

    Widget logo = CustomPaint(
      size: Size(size, size),
      painter: _AppLogoPainter(
        showTile: showTile,
        tileColor: tileColor,
        tileGradient: resolvedGradient,
        borderColor: isDark ? colors.border : const Color(0xFF38383E),
        accentColor: resolvedAccent,
        pageColor: resolvedPage,
        isDark: isDark,
      ),
    );

    if (onTap != null) {
      logo = GestureDetector(onTap: onTap, child: logo);
    }

    return logo;
  }
}

class _AppLogoPainter extends CustomPainter {
  final bool showTile;
  final Color? tileColor;
  final Gradient? tileGradient;
  final Color borderColor;
  final Color accentColor;
  final Color pageColor;
  final bool isDark;

  _AppLogoPainter({
    required this.showTile,
    this.tileColor,
    this.tileGradient,
    required this.borderColor,
    required this.accentColor,
    required this.pageColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw Squircle Tile if requested
    if (showTile) {
      final tileRadius = Radius.circular(w * 0.22);
      final tileRect = Rect.fromLTWH(0, 0, w, h);
      final tileRRect = RRect.fromRectAndRadius(
        tileRect,
        tileRadius,
      );

      // Tile Background Fill
      final tilePaint = Paint()..style = PaintingStyle.fill;
      if (tileGradient != null) {
        tilePaint.shader = tileGradient!.createShader(tileRect);
      } else if (tileColor != null) {
        tilePaint.color = tileColor!;
      } else {
        tilePaint.color = const Color(0xFF1C1C1F);
      }
      canvas.drawRRect(tileRRect, tilePaint);

      // Subtle border
      final borderPaint = Paint()
        ..color = borderColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (w * 0.025).clamp(1.0, 2.0);
      canvas.drawRRect(tileRRect, borderPaint);
    }

    // Book geometry scale & offset (safe interior margins)
    final bookMarginX = showTile ? w * 0.18 : w * 0.05;
    final bookMarginY = showTile ? h * 0.22 : h * 0.08;
    final bw = w - (bookMarginX * 2);
    final bh = h - (bookMarginY * 2);
    final bx = bookMarginX;
    final by = bookMarginY;

    final centerX = bx + bw / 2;
    final bottomY = by + bh;
    final topY = by;
    final spineDipY = bottomY - (bh * 0.08);

    // 2. Ambient Under-Book Shadow
    final shadowPath = Path()
      ..moveTo(bx + bw * 0.08, bottomY + (bh * 0.04))
      ..quadraticBezierTo(centerX, bottomY + (bh * 0.12), bx + bw * 0.92, bottomY + (bh * 0.04))
      ..quadraticBezierTo(centerX, bottomY, bx + bw * 0.08, bottomY + (bh * 0.04))
      ..close();

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.12)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, (w * 0.04).clamp(1.5, 4.0));
    canvas.drawPath(shadowPath, shadowPaint);

    // 3. Base / Cover Spine Foundation
    final coverPath = Path()
      ..moveTo(bx + bw * 0.02, bottomY - (bh * 0.02))
      ..lineTo(bx + bw * 0.02, bottomY + (bh * 0.03))
      ..quadraticBezierTo(centerX - bw * 0.1, bottomY + (bh * 0.07), centerX, bottomY + (bh * 0.08))
      ..quadraticBezierTo(centerX + bw * 0.1, bottomY + (bh * 0.07), bx + bw * 0.98, bottomY + (bh * 0.03))
      ..lineTo(bx + bw * 0.98, bottomY - (bh * 0.02))
      ..quadraticBezierTo(centerX, bottomY + (bh * 0.04), bx + bw * 0.02, bottomY - (bh * 0.02))
      ..close();

    final coverPaint = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.4 : 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawPath(coverPath, coverPaint);

    // 4. Secondary Under-Pages (Layers of paper)
    final underPagePaint = Paint()
      ..color = pageColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    // Left under-page
    final leftUnderPath = Path()
      ..moveTo(centerX, spineDipY)
      ..quadraticBezierTo(bx + bw * 0.22, topY + bh * 0.08, bx + bw * 0.03, topY + bh * 0.16)
      ..lineTo(bx + bw * 0.03, bottomY - bh * 0.04)
      ..quadraticBezierTo(bx + bw * 0.25, bottomY - bh * 0.1, centerX, bottomY)
      ..close();
    canvas.drawPath(leftUnderPath, underPagePaint);

    // Right under-page
    final rightUnderPath = Path()
      ..moveTo(centerX, spineDipY)
      ..quadraticBezierTo(bx + bw * 0.78, topY + bh * 0.08, bx + bw * 0.97, topY + bh * 0.16)
      ..lineTo(bx + bw * 0.97, bottomY - bh * 0.04)
      ..quadraticBezierTo(bx + bw * 0.75, bottomY - bh * 0.1, centerX, bottomY)
      ..close();
    canvas.drawPath(rightUnderPath, underPagePaint);

    // 5. Main Top Pages (Symmetrical smooth open wings)
    final topPagePaint = Paint()
      ..color = pageColor
      ..style = PaintingStyle.fill;

    // Left Page
    final leftPagePath = Path()
      ..moveTo(centerX, spineDipY)
      ..cubicTo(
        centerX - bw * 0.18,
        topY - bh * 0.02,
        bx + bw * 0.15,
        topY + bh * 0.06,
        bx + bw * 0.06,
        topY + bh * 0.14,
      )
      ..lineTo(bx + bw * 0.06, bottomY - bh * 0.08)
      ..cubicTo(
        bx + bw * 0.18,
        bottomY - bh * 0.15,
        centerX - bw * 0.18,
        bottomY - bh * 0.07,
        centerX,
        bottomY,
      )
      ..close();
    canvas.drawPath(leftPagePath, topPagePaint);

    // Right Page
    final rightPagePath = Path()
      ..moveTo(centerX, spineDipY)
      ..cubicTo(
        centerX + bw * 0.18,
        topY - bh * 0.02,
        bx + bw * 0.85,
        topY + bh * 0.06,
        bx + bw * 0.94,
        topY + bh * 0.14,
      )
      ..lineTo(bx + bw * 0.94, bottomY - bh * 0.08)
      ..cubicTo(
        bx + bw * 0.82,
        bottomY - bh * 0.15,
        centerX + bw * 0.18,
        bottomY - bh * 0.07,
        centerX,
        bottomY,
      )
      ..close();
    canvas.drawPath(rightPagePath, topPagePaint);

    // 6. Delicate Page Shading / Crease Shadows
    final creaseShadowPaint = Paint()
      ..color = (isDark ? Colors.black : Colors.brown).withValues(alpha: isDark ? 0.22 : 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.02).clamp(1.0, 2.5);

    final creasePath = Path()
      ..moveTo(centerX, spineDipY)
      ..lineTo(centerX, bottomY);
    canvas.drawPath(creasePath, creaseShadowPaint);

    // 7. Subtle UI Accent Glow at Spine Center (Reacts to App UI Accent)
    final accentSpinePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (w * 0.025).clamp(1.2, 3.0);

    final accentSpinePath = Path()
      ..moveTo(centerX, spineDipY + (bh * 0.15))
      ..lineTo(centerX, bottomY - (bh * 0.1));
    canvas.drawPath(accentSpinePath, accentSpinePaint);
  }

  @override
  bool shouldRepaint(covariant _AppLogoPainter oldDelegate) {
    return oldDelegate.tileColor != tileColor ||
        oldDelegate.tileGradient != tileGradient ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.pageColor != pageColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.showTile != showTile;
  }
}
