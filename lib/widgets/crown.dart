import 'package:flutter/material.dart';

import '../theme/eon_theme.dart';

/// Glowing outlined crown drawn in code (used in the logo and banners).
class CrownIcon extends StatelessWidget {
  const CrownIcon({super.key, this.size = 24, this.glow = 1.0, this.color});

  final double size;
  final double glow;

  /// Defaults to the palette highlight colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CustomPaint(
      size: Size(size, size * 0.74),
      painter: CrownPainter(
        glow: glow * p.glowStrength,
        color: color ?? p.highlight,
        glowColor: p.glow,
        accent: p.accent,
      ),
    );
  }
}

class CrownPainter extends CustomPainter {
  CrownPainter({
    required this.color,
    required this.glowColor,
    required this.accent,
    this.glow = 1.0,
  });

  final double glow;
  final Color color;
  final Color glowColor;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = w * 0.045;

    final leftTip = Offset(w * 0.06, h * 0.30);
    final midTip = Offset(w * 0.50, h * 0.10);
    final rightTip = Offset(w * 0.94, h * 0.30);

    final body =
        Path()
          ..moveTo(w * 0.14, h * 0.80)
          ..lineTo(leftTip.dx, leftTip.dy)
          ..lineTo(w * 0.33, h * 0.54)
          ..lineTo(midTip.dx, midTip.dy)
          ..lineTo(w * 0.67, h * 0.54)
          ..lineTo(rightTip.dx, rightTip.dy)
          ..lineTo(w * 0.86, h * 0.80)
          ..close();

    final band = RRect.fromLTRBR(
      w * 0.14,
      h * 0.86,
      w * 0.86,
      h * 0.97,
      Radius.circular(w * 0.03),
    );

    final strokePaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeJoin = StrokeJoin.round;

    if (glow > 0.01) {
      final glowPaint =
          Paint()
            ..color = glowColor.withValues(alpha: (0.7 * glow).clamp(0.0, 1.0))
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke * 2.4
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas
        ..drawPath(body, glowPaint)
        ..drawRRect(band, glowPaint);
    }

    final fillPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.35),
              accent.withValues(alpha: 0.15),
            ],
          ).createShader(Offset.zero & size);

    canvas
      ..drawPath(body, fillPaint)
      ..drawPath(body, strokePaint)
      ..drawRRect(band, strokePaint);

    final jewelPaint = Paint()..color = color;
    for (final tip in [leftTip, midTip, rightTip]) {
      canvas.drawCircle(tip, w * 0.045, jewelPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CrownPainter old) =>
      old.glow != glow ||
      old.color != color ||
      old.glowColor != glowColor ||
      old.accent != accent;
}
