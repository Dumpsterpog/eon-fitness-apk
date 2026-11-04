import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/eon_state.dart';
import '../theme/eon_theme.dart';
import '../widgets/widgets.dart';

/// Water Intake: animated glass, consumed / remaining, efficiency bar,
/// "Keep Going" (+250 ml) and "Set New Daily Target".
class WaterIntakeScreen extends StatelessWidget {
  const WaterIntakeScreen({super.key});

  static const _glassMl = 250;

  void _logGlass(BuildContext context) {
    final state = context.eonRead;
    state.addWater(_glassMl);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: const Text('+$_glassMl ml logged'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => state.addWater(-_glassMl),
          ),
        ),
      );
  }

  void _showTargetSheet(BuildContext context) {
    final state = context.eonRead;
    var target = state.waterTargetMl.toDouble().clamp(1000.0, 5000.0);

    showEonSheet<void>(
      context,
      builder:
          (sheetContext) => StatefulBuilder(
            builder:
                (context, setSheetState) => EonSheet(
                  title: 'Set New Daily Target',
                  icon: Icons.water_drop_rounded,
                  subtitle: 'Pick a target you can hit every day.',
                  child: Column(
                    children: [
                      Center(
                        child: Text(
                          fmtLitres(target.round()),
                          style: eonText(
                            36,
                            weight: FontWeight.w700,
                            shadows: context.palette.textGlow(),
                          ),
                        ),
                      ),
                      Slider(
                        value: target,
                        min: 1000,
                        max: 5000,
                        divisions: 16,
                        label: fmtLitres(target.round()),
                        onChanged: (v) => setSheetState(() => target = v),
                      ),
                      const SizedBox(height: 12),
                      GlowButton(
                        label: 'Save Target',
                        height: 52,
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          state.setWaterTarget(target.round());
                        },
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.eon;
    final p = context.palette;
    final percent = (s.waterProgress * 100).round();

    return Scaffold(
      backgroundColor: p.background,
      body: EonBackground(
        child: SafeArea(
          child: Column(
            children: [
              EonHeader(
                title: 'Water Intake',
                icon: Icons.water_drop_rounded,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Semantics(
                    label: 'Water glass, $percent percent full',
                    child: WaterGlass(level: s.waterProgress),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Column(
                  children: [
                    Text(
                      'Consumed : ${fmtLitres(s.waterMl)}',
                      style: eonText(19, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Remaining : ${fmtLitres(s.waterRemainingMl)}',
                      style: eonText(19, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 22),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Daily Target Efficiency',
                        style: eonText(13.5, color: p.textMuted),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: EonProgressBar(
                            value: s.waterProgress,
                            height: 8,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          '$percent%',
                          style: eonText(15, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GlowButton(
                      label: 'Keep Going, ${s.userName}!',
                      leading: const CrownIcon(size: 26),
                      onPressed: () => _logGlass(context),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => _showTargetSheet(context),
                      style: TextButton.styleFrom(
                        foregroundColor: p.text,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      icon: Icon(Icons.check_box_outlined, color: p.highlight),
                      label: Text(
                        'Set New Daily Target',
                        style: eonText(15, color: p.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glass of water drawn in code: level animates, surface waves, bubbles rise.
class WaterGlass extends StatefulWidget {
  const WaterGlass({super.key, required this.level});

  /// 0.0 – 1.0
  final double level;

  @override
  State<WaterGlass> createState() => _WaterGlassState();
}

class _WaterGlassState extends State<WaterGlass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: widget.level.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder:
          (context, level, _) => SizedBox.expand(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _WaterGlassPainter(
                  level: level,
                  wave: _wave,
                  palette: context.palette,
                ),
              ),
            ),
          ),
    );
  }
}

class _WaterGlassPainter extends CustomPainter {
  _WaterGlassPainter({
    required this.level,
    required this.wave,
    required this.palette,
  }) : super(repaint: wave);

  final double level;
  final Animation<double> wave;
  final EonPalette palette;

  /// Glass edges: white on dark backgrounds, deep violet on light ones.
  Color get _edge => palette.isDark ? Colors.white : palette.accentDeep;

  @override
  void paint(Canvas canvas, Size size) {
    final p = palette;
    final w = size.width;
    final h = size.height;
    final glassH = math.min(h * 0.86, w * 1.15);
    final glassW = glassH * 0.62;
    final cx = w / 2;
    final top = (h - glassH) / 2;
    final bottom = top + glassH;
    final topHalf = glassW / 2;
    final botHalf = glassW * 0.4;
    final r = glassW * 0.08;

    // Aura behind the glass.
    final auraCenter = Offset(cx, top + glassH * 0.5);
    canvas.drawCircle(
      auraCenter,
      glassH * 0.58,
      Paint()
        ..shader = RadialGradient(
          colors: [
            p.glow.withValues(alpha: 0.28 * (p.isDark ? 1 : 0.7)),
            p.glow.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(center: auraCenter, radius: glassH * 0.58),
        ),
    );

    // Glow under the base.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, bottom),
        width: glassW * 1.7,
        height: glassW * 0.3,
      ),
      Paint()
        ..color = p.water.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    final glass =
        Path()
          ..moveTo(cx - topHalf, top)
          ..lineTo(cx + topHalf, top)
          ..lineTo(cx + botHalf, bottom - r)
          ..quadraticBezierTo(cx + botHalf, bottom, cx + botHalf - r, bottom)
          ..lineTo(cx - botHalf + r, bottom)
          ..quadraticBezierTo(cx - botHalf, bottom, cx - botHalf, bottom - r)
          ..close();

    final glassRect = Rect.fromLTRB(cx - topHalf, top, cx + topHalf, bottom);

    // Glass tint.
    canvas.drawPath(
      glass,
      Paint()
        ..shader = LinearGradient(
          colors: [
            _edge.withValues(alpha: 0.10),
            _edge.withValues(alpha: 0.03),
            _edge.withValues(alpha: 0.08),
          ],
        ).createShader(glassRect),
    );

    final innerTop = top + glassH * 0.06;
    final waterBottom = bottom - glassW * 0.07; // thick glass base
    final waterTop = waterBottom - (waterBottom - innerTop) * level;

    if (level > 0.002) {
      canvas.save();
      canvas.clipPath(glass);

      final phase = wave.value * 2 * math.pi;
      final amp = glassH * 0.012;
      final left = cx - topHalf;
      final right = cx + topHalf;
      final waterRect = Rect.fromLTRB(left, waterTop, right, waterBottom);

      // Back wave.
      _wave(
        canvas,
        left,
        right,
        waterTop,
        waterBottom,
        phase + math.pi,
        amp,
        Paint()..color = p.water.withValues(alpha: 0.35),
      );

      // Front wave.
      _wave(
        canvas,
        left,
        right,
        waterTop + amp * 0.6,
        waterBottom,
        phase,
        amp,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(p.water, Colors.white, 0.2)!.withValues(alpha: 0.9),
              p.waterDeep.withValues(alpha: 0.95),
            ],
          ).createShader(waterRect),
      );

      // Bubbles.
      final bubble = Paint()..color = Colors.white.withValues(alpha: 0.35);
      for (var i = 0; i < 9; i++) {
        final t = (wave.value * (1 + i % 2) + i * 0.137) % 1.0;
        final y = waterBottom - t * (waterBottom - waterTop);
        if (y < waterTop + amp * 2) continue;
        final xFrac = 0.2 + 0.6 * ((i * 0.37) % 1.0);
        final x =
            left + (right - left) * xFrac + math.sin(t * math.pi * 4 + i) * 3;
        canvas.drawCircle(Offset(x, y), 1.4 + (i % 3) * 0.9, bubble);
      }

      canvas.restore();
    }

    // Thick glass base.
    canvas.save();
    canvas.clipPath(glass);
    final baseRect = Rect.fromLTRB(
      cx - botHalf,
      waterBottom,
      cx + botHalf,
      bottom,
    );
    canvas.drawRect(
      baseRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _edge.withValues(alpha: 0.28),
            p.highlight.withValues(alpha: 0.15),
          ],
        ).createShader(baseRect),
    );
    canvas.restore();

    // Outline.
    canvas.drawPath(
      glass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _edge.withValues(alpha: 0.55),
    );

    // Rim.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, top),
        width: glassW,
        height: glassW * 0.12,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = _edge.withValues(alpha: 0.6),
    );

    // Highlight strip.
    final hl =
        Path()
          ..moveTo(cx - topHalf * 0.80, top + glassH * 0.08)
          ..lineTo(cx - topHalf * 0.64, top + glassH * 0.08)
          ..lineTo(cx - botHalf * 0.62, bottom - glassH * 0.12)
          ..lineTo(cx - botHalf * 0.76, bottom - glassH * 0.12)
          ..close();
    canvas.drawPath(
      hl,
      Paint()..color = Colors.white.withValues(alpha: p.isDark ? 0.22 : 0.5),
    );
  }

  void _wave(
    Canvas canvas,
    double left,
    double right,
    double y,
    double bottom,
    double phase,
    double amp,
    Paint paint,
  ) {
    final path =
        Path()
          ..moveTo(left, bottom)
          ..lineTo(left, y);
    const segments = 40;
    for (var i = 0; i <= segments; i++) {
      final t = i / segments;
      path.lineTo(
        left + (right - left) * t,
        y + math.sin(t * 2 * math.pi * 1.5 + phase) * amp,
      );
    }
    path
      ..lineTo(right, bottom)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaterGlassPainter oldDelegate) =>
      oldDelegate.level != level || oldDelegate.palette != palette;
}
