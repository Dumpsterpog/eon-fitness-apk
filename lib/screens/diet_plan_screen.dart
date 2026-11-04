import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/eon_state.dart';
import '../theme/eon_theme.dart';
import '../widgets/widgets.dart';

/// Diet Plan: protein / calories / carbs goals with progress, food bowl art
/// and the "Eat smart, Hunter" banner. Tap a goal to log food.
class DietPlanScreen extends StatelessWidget {
  const DietPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.eon;
    final p = context.palette;
    final width = MediaQuery.sizeOf(context).width;
    final bowl = (width * 0.4).clamp(120.0, 190.0);

    return Scaffold(
      backgroundColor: p.background,
      body: EonBackground(
        child: SafeArea(
          child: Column(
            children: [
              EonHeader(
                title: 'Diet Plan',
                icon: Icons.restaurant_rounded,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: bowl * 0.7),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Nutrition Plan',
                                    style: eonText(22, weight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Goal: ${s.bodyGoal.label}',
                                    style: eonText(13.5, color: p.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: bowl * 0.5),
                            GlassCard(
                              blur: true,
                              highlight: true,
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                14,
                                14,
                                14,
                              ),
                              child: Column(
                                children: [
                                  for (final g in NutrientGoal.values) ...[
                                    if (g != NutrientGoal.values.first)
                                      const SizedBox(height: 10),
                                    _NutrientRow(goal: g),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap a goal to log what you ate.',
                              style: eonText(12, color: p.textFaint),
                            ),
                          ],
                        ),
                        Positioned(
                          right: -12,
                          top: -8,
                          width: bowl,
                          height: bowl,
                          child: const IgnorePointer(child: _Bowl()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GlassCard(
                      highlight: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CrownIcon(size: 30),
                          const SizedBox(width: 14),
                          Flexible(
                            child: Text(
                              'Eat smart, ${s.userName}.\nFuel your journey.',
                              style: eonText(16, height: 1.35),
                            ),
                          ),
                        ],
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

class _NutrientRow extends StatelessWidget {
  const _NutrientRow({required this.goal});

  final NutrientGoal goal;

  @override
  Widget build(BuildContext context) {
    final s = context.eon;
    final p = context.palette;
    final tracked = s.isTracked(goal);
    final value = s.nutrient(goal);
    final target = s.nutrientTarget(goal);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap:
          tracked
              ? () => showQuickAddSheet(
                context,
                title: 'Log ${goal.shortLabel}',
                unit: goal.unit,
                icon: goal.icon,
                subtitle: '$value / $target${goal.suffix} today',
                amounts: goal.quickAmounts,
                onAdd: (amount) => s.logNutrient(goal, amount),
              )
              : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: tracked ? 1 : 0.45,
          child: Row(
            children: [
              _GlowCheckbox(
                value: tracked,
                label: goal.label,
                onTap: () => s.toggleTracked(goal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            goal.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: eonText(14.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$value/$target${goal.suffix}',
                          style: eonText(13, color: p.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    EonProgressBar(value: s.nutrientProgress(goal)),
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

class _GlowCheckbox extends StatelessWidget {
  const _GlowCheckbox({
    required this.value,
    required this.label,
    required this.onTap,
  });

  final bool value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      checked: value,
      label: 'Track $label',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color:
                  value
                      ? p.accent.withValues(alpha: p.isDark ? 0.55 : 0.9)
                      : Colors.transparent,
              border: Border.all(color: p.highlight, width: 1.4),
              boxShadow: value ? p.boxGlow(strength: 0.8) : const [],
            ),
            child:
                value
                    ? Icon(Icons.check_rounded, size: 20, color: p.onAccent)
                    : null,
          ),
        ),
      ),
    );
  }
}

class _Bowl extends StatelessWidget {
  const _Bowl();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      image: true,
      label: 'Bowl of rice, salmon, egg and greens',
      child: CustomPaint(painter: _BowlPainter(p)),
    );
  }
}

/// A painted power bowl: rice, salmon, soft-boiled egg, broccoli, edamame.
class _BowlPainter extends CustomPainter {
  _BowlPainter(this.p);

  final EonPalette p;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final c = Offset(w / 2, size.height * 0.52);
    final rx = w * 0.46;
    final ry = w * 0.17;

    // Aura + table shadow.
    canvas
      ..drawCircle(
        c,
        w * 0.55,
        Paint()
          ..shader = RadialGradient(
            colors: [
              p.glow.withValues(alpha: 0.35 * p.glowStrength),
              p.glow.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: w * 0.55)),
      )
      ..drawOval(
        Rect.fromCenter(
          center: c + Offset(0, w * 0.33),
          width: w * 0.7,
          height: w * 0.1,
        ),
        Paint()
          ..color = Colors.black.withValues(alpha: p.isDark ? 0.5 : 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

    // Bowl body.
    final rim = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
    final body =
        Path()
          ..moveTo(c.dx - rx, c.dy)
          ..cubicTo(
            c.dx - rx,
            c.dy + w * 0.3,
            c.dx - rx * 0.45,
            c.dy + w * 0.36,
            c.dx,
            c.dy + w * 0.36,
          )
          ..cubicTo(
            c.dx + rx * 0.45,
            c.dy + w * 0.36,
            c.dx + rx,
            c.dy + w * 0.3,
            c.dx + rx,
            c.dy,
          )
          ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B2140), Color(0xFF0E0A18)],
        ).createShader(body.getBounds()),
    );
    // Glowing rim.
    canvas
      ..drawOval(
        rim,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = p.glow.withValues(alpha: 0.6 * p.glowStrength + 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..drawOval(rim, Paint()..color = const Color(0xFF1A1328));

    canvas
      ..save()
      ..clipPath(Path()..addOval(rim.deflate(2)));

    // Rice bed.
    canvas.drawOval(rim.deflate(3), Paint()..color = const Color(0xFFF3EEE2));
    final grain = Paint()..color = const Color(0xFFDCD5C6);
    final rnd = math.Random(7);
    for (var i = 0; i < 60; i++) {
      final o =
          c +
          Offset(
            (rnd.nextDouble() - 0.5) * rx * 1.9,
            (rnd.nextDouble() - 0.5) * ry * 1.8,
          );
      canvas.drawOval(
        Rect.fromCenter(center: o, width: w * 0.03, height: w * 0.014),
        grain,
      );
    }

    // Salmon slices (left).
    final salmon = Paint()..color = const Color(0xFFF08A5D);
    final fat =
        Paint()
          ..color = const Color(0xFFFFD2BC)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;
    for (var i = 0; i < 3; i++) {
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: c + Offset(-rx * (0.55 - i * 0.17), -ry * (0.15 - i * 0.12)),
          width: w * 0.18,
          height: w * 0.085,
        ),
        Radius.circular(w * 0.03),
      );
      canvas
        ..drawRRect(r, salmon)
        ..drawLine(
          r.center - Offset(w * 0.06, 0),
          r.center + Offset(w * 0.06, 0),
          fat,
        );
    }

    // Egg halves (back right).
    for (final dx in [0.18, 0.46]) {
      final e = c + Offset(rx * dx, -ry * 0.35);
      canvas
        ..drawOval(
          Rect.fromCenter(center: e, width: w * 0.17, height: w * 0.12),
          Paint()..color = Colors.white,
        )
        ..drawCircle(e, w * 0.035, Paint()..color = const Color(0xFFFFB627));
    }

    // Broccoli (front right).
    final floret = Paint()..color = const Color(0xFF3E9B4F);
    final floretLight = Paint()..color = const Color(0xFF63C06F);
    for (var i = 0; i < 4; i++) {
      final b = c + Offset(rx * (0.2 + i * 0.16), ry * (0.35 - (i % 2) * 0.2));
      canvas
        ..drawCircle(b, w * 0.045, floret)
        ..drawCircle(
          b + Offset(-w * 0.015, -w * 0.015),
          w * 0.022,
          floretLight,
        );
    }

    // Edamame (front centre).
    final bean = Paint()..color = const Color(0xFF9BD36A);
    for (var i = 0; i < 6; i++) {
      canvas.drawCircle(
        c + Offset(-rx * 0.2 + i * w * 0.035, ry * 0.55 + (i % 2) * w * 0.012),
        w * 0.018,
        bean,
      );
    }
    canvas.restore();

    // Sesame sparkle.
    final sesame = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (var i = 0; i < 10; i++) {
      final o =
          c +
          Offset(
            (rnd.nextDouble() - 0.5) * rx * 1.4,
            (rnd.nextDouble() - 0.6) * ry,
          );
      canvas.drawOval(
        Rect.fromCenter(center: o, width: 2.4, height: 1.4),
        sesame,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BowlPainter old) => old.p != p;
}
