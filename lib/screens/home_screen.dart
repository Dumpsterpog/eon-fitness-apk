import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/eon_state.dart';
import '../theme/eon_theme.dart';
import '../widgets/widgets.dart';
import 'diet_plan_screen.dart';
import 'quest_actions.dart';

/// Home tab: greeting, daily quest, calorie ring, protein + carbs tiles.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openDiet(BuildContext context) =>
      Navigator.of(context).push(eonRoute<void>(const DietPlanScreen()));

  @override
  Widget build(BuildContext context) {
    final s = context.eon;
    final size = MediaQuery.sizeOf(context);
    final ringSize = math.min(size.width * 0.66, size.height * 0.34);

    const protein = NutrientGoal.protein;
    const carbs = NutrientGoal.carbs;
    const calories = NutrientGoal.calories;

    return EonBackground(
      scene: RealmVariant.home,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _Greeting(name: s.userName),
            const SizedBox(height: 20),
            _DailyQuestCard(quest: s.featuredQuest),
            const SizedBox(height: 28),
            Center(
              child: _CalorieRing(
                size: ringSize,
                current: s.nutrient(calories),
                target: s.nutrientTarget(calories),
                onTap: () => _openDiet(context),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.fitness_center_rounded,
                    label: "Today's\nProtein",
                    value:
                        '${s.nutrient(protein)} / ${s.nutrientTarget(protein)} gm',
                    progress: s.nutrientProgress(protein),
                    onTap: () => _openDiet(context),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatTile(
                    icon: Icons.bakery_dining_rounded,
                    label: "Today's\nCarbs",
                    value: '${s.nutrient(carbs)} / ${s.nutrientTarget(carbs)}',
                    progress: s.nutrientProgress(carbs),
                    onTap: () => _openDiet(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: eonText(18, weight: FontWeight.w400),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: eonText(22, weight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 18,
                    color: p.highlight,
                    shadows: p.textGlow(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const ThemeToggleButton(),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => _showNotifications(context),
          icon: Icon(
            Icons.notifications_none_rounded,
            size: 28,
            color: p.text,
            shadows: p.textGlow(0.8),
          ),
        ),
      ],
    );
  }
}

/// "System" notifications built from today's numbers.
void _showNotifications(BuildContext context) {
  final s = context.eonRead;
  final open = s.todayQuests.where((q) => !q.isComplete).toList();
  final message =
      open.isEmpty
          ? '[SYSTEM] All daily quests cleared. Rest well, ${s.userName}.'
          : '[SYSTEM] ${open.length} daily quest${open.length == 1 ? '' : 's'} '
              'remaining. Next: ${open.first.title}.';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _DailyQuestCard extends StatelessWidget {
  const _DailyQuestCard({required this.quest});

  final Quest? quest;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final q = quest;

    if (q == null) {
      return GlassCard(
        highlight: true,
        blur: true,
        child: Row(
          children: [
            const CrownIcon(size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Quests Cleared',
                    style: eonText(16, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rest up. New quests tomorrow.',
                    style: eonText(13.5, color: p.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      highlight: true,
      blur: true,
      onTap: () => openQuest(context, q),
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      child: Row(
        children: [
          const _AlertBadge(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Quest',
                  style: eonText(16, weight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(q.title, style: eonText(14, color: p.textMuted)),
                const SizedBox(height: 10),
                Text(q.progressLabel, style: eonText(12.5, color: p.textMuted)),
                const SizedBox(height: 6),
                EonProgressBar(value: q.progress),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 30, color: p.highlight),
        ],
      ),
    );
  }
}

/// The glowing "!" emblem on the Daily Quest card.
class _AlertBadge extends StatelessWidget {
  const _AlertBadge();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 48,
      height: 48,
      decoration: ShapeDecoration(
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: p.highlight, width: 1.4),
        ),
        gradient: RadialGradient(colors: [p.accent, p.accentDeep]),
        shadows: p.boxGlow(strength: 1.2),
      ),
      child: Icon(
        Icons.priority_high_rounded,
        color: p.onAccent,
        size: 26,
        shadows: p.textGlow(),
      ),
    );
  }
}

class _CalorieRing extends StatelessWidget {
  const _CalorieRing({
    required this.size,
    required this.current,
    required this.target,
    this.onTap,
  });

  final double size;
  final int current;
  final int target;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final progress = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);

    return Semantics(
      button: onTap != null,
      label: "Today's calories: $current of $target",
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress.toDouble()),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder:
                (context, value, child) => CustomPaint(
                  painter: CalorieRingPainter(progress: value, palette: p),
                  child: child,
                ),
            child: Padding(
              padding: EdgeInsets.all(size * 0.2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Today's\nCalories",
                      textAlign: TextAlign.center,
                      style: eonText(16, height: 1.25),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: fmtThousands(current),
                            style: eonText(30, weight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: ' / ${fmtThousands(target)}',
                            style: eonText(24),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 26,
                      color: p.highlight,
                      shadows: p.textGlow(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glowing circular progress ring with tick marks.
class CalorieRingPainter extends CustomPainter {
  CalorieRingPainter({required this.progress, required this.palette});

  final double progress;
  final EonPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final p = palette;
    final center = size.center(Offset.zero);
    final stroke = size.shortestSide * 0.045;
    final radius = size.shortestSide / 2 - stroke * 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Inner disc.
    canvas.drawCircle(
      center,
      radius - stroke * 0.5,
      Paint()
        ..shader = RadialGradient(
          colors:
              p.isDark
                  ? const [Color(0xCC1E1140), Color(0xEE0C0720)]
                  : [
                    p.surfaceTop.withValues(alpha: 0.92),
                    p.surfaceBottom.withValues(alpha: 0.95),
                  ],
        ).createShader(rect),
    );

    // Outer halo.
    canvas.drawCircle(
      center,
      radius + stroke * 1.6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = p.highlight.withValues(alpha: 0.25),
    );

    // Tick marks.
    final tick =
        Paint()
          ..color = p.highlight.withValues(alpha: 0.18)
          ..strokeWidth = 1;
    for (var i = 0; i < 60; i++) {
      final a = i / 60 * 2 * math.pi;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        center + dir * (radius + stroke * 0.9),
        center + dir * (radius + stroke * (i % 5 == 0 ? 1.5 : 1.2)),
        tick,
      );
    }

    // Track.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = p.track,
    );

    final sweep = 2 * math.pi * progress;
    if (sweep <= 0) return;

    // Glow under the arc.
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 2.2
        ..strokeCap = StrokeCap.round
        ..color = p.glow.withValues(alpha: 0.45 * p.glowStrength + 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Arc.
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [p.accent, p.highlight, p.accent],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );

    // Bright head.
    final head = -math.pi / 2 + sweep;
    canvas.drawCircle(
      center + Offset(math.cos(head), math.sin(head)) * radius,
      stroke * 0.75,
      Paint()
        ..color = p.isDark ? Colors.white : p.highlight
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(covariant CalorieRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.palette != palette;
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.progress,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final double progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
      child: Column(
        children: [
          Icon(icon, size: 34, color: p.highlight, shadows: p.textGlow()),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: eonText(14, height: 1.25),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: eonText(17, weight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          EonProgressBar(value: progress, height: 4),
        ],
      ),
    );
  }
}
