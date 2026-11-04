import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/eon_state.dart';
import '../theme/eon_theme.dart';
import '../widgets/widgets.dart';

/// "Personal Trainer AI": a status window plus guidance generated on-device
/// from today's numbers. Pure rules, no network.
class TrainerScreen extends StatelessWidget {
  const TrainerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.eon;
    final p = context.palette;
    final advice = TrainerAdvice.from(s);
    final suggested = TrainerAdvice.suggestedRoutine(s, DateTime.now());

    final cards = <Widget>[
      _StatusWindow(state: s),
      const SizedBox(height: 18),
      const SectionLabel("Today's Orders", icon: Icons.bolt_rounded),
      const SizedBox(height: 12),
      for (final a in advice) ...[
        _AdviceCard(advice: a),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 8),
      GlowButton(
        label: 'Start ${kRoutines[suggested].name} Routine',
        leading: const Icon(Icons.fitness_center_rounded, size: 22),
        onPressed: () {
          s.selectRoutine(suggested);
          Navigator.of(context).maybePop();
        },
      ),
      const SizedBox(height: 14),
      Text(
        'Guidance is generated on your phone from your logged numbers. '
        'It is not medical advice.',
        textAlign: TextAlign.center,
        style: eonText(11.5, color: p.textFaint, height: 1.4),
      ),
    ];

    return Scaffold(
      backgroundColor: p.background,
      body: EonBackground(
        child: SafeArea(
          child: Column(
            children: [
              EonHeader(
                title: 'Personal Trainer AI',
                icon: Icons.psychology_rounded,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    for (var i = 0; i < cards.length; i++)
                      _StaggeredIn(index: i, child: cards[i]),
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

/// One line of guidance.
class TrainerAdvice {
  const TrainerAdvice(this.icon, this.title, this.body, {this.done = false});

  final IconData icon;
  final String title;
  final String body;
  final bool done;

  static List<TrainerAdvice> from(EonState s) {
    final out = <TrainerAdvice>[];

    final waterLeft = s.waterRemainingMl;
    out.add(
      waterLeft <= 0
          ? const TrainerAdvice(
            Icons.water_drop_rounded,
            'Hydration complete',
            'Water target reached. Keep sipping with meals.',
            done: true,
          )
          : TrainerAdvice(
            Icons.water_drop_rounded,
            'Drink ${(waterLeft / 250).ceil()} more glasses',
            '${fmtLitres(waterLeft)} left today. One 250 ml glass every '
                'hour or two gets you there.',
          ),
    );

    final stepsLeft = math.max(0, s.stepsTarget - s.steps);
    out.add(
      stepsLeft == 0
          ? const TrainerAdvice(
            Icons.directions_run_rounded,
            'Steps cleared',
            'Step quest done. An easy evening walk still helps recovery.',
            done: true,
          )
          : TrainerAdvice(
            Icons.directions_run_rounded,
            'Walk about ${(stepsLeft / 100).ceil()} minutes',
            '${fmtThousands(stepsLeft)} steps to go, at roughly 100 '
                'steps a minute.',
          ),
    );

    final proteinLeft = math.max(
      0,
      s.nutrientTarget(NutrientGoal.protein) - s.nutrient(NutrientGoal.protein),
    );
    final calLeft = math.max(
      0,
      s.nutrientTarget(NutrientGoal.calories) -
          s.nutrient(NutrientGoal.calories),
    );
    out.add(
      proteinLeft == 0 && calLeft == 0
          ? const TrainerAdvice(
            Icons.restaurant_rounded,
            'Fuel targets met',
            'Protein and calories are on target for today.',
            done: true,
          )
          : TrainerAdvice(
            Icons.restaurant_rounded,
            proteinLeft > 0
                ? 'Get $proteinLeft g more protein'
                : 'Eat ${fmtThousands(calLeft)} more kcal',
            [
              if (proteinLeft > 0)
                'About ${(proteinLeft / 30).ceil()} servings of eggs, '
                    'chicken, paneer or lentils (~30 g each).',
              if (calLeft > 0) '${fmtThousands(calLeft)} kcal left in the day.',
            ].join(' '),
          ),
    );

    out.add(
      s.workoutDone
          ? const TrainerAdvice(
            Icons.fitness_center_rounded,
            'Workout cleared',
            "Today's routine is done. Stretch and sleep well.",
            done: true,
          )
          : TrainerAdvice(
            Icons.fitness_center_rounded,
            'Finish your ${s.currentRoutine.name} routine',
            '${s.doneCount(s.currentRoutine)} of '
                '${s.currentRoutine.exercises.length} exercises done. '
                'Goal: ${s.bodyGoal.label}.',
          ),
    );

    if (s.streak > 0) {
      out.add(
        TrainerAdvice(
          Icons.local_fire_department_rounded,
          'Protect your ${s.streak}-day streak',
          'Clear all four daily quests before midnight to extend it.',
        ),
      );
    }

    // Open items first.
    out.sort((a, b) => (a.done ? 1 : 0) - (b.done ? 1 : 0));
    return out;
  }

  /// Routine index that fits the hunter's goal and the day of the week.
  static int suggestedRoutine(EonState s, DateTime now) {
    const daily = 0, pull = 1, legs = 2;
    return switch (s.bodyGoal) {
      BodyGoal.buildMuscle => [daily, pull, legs][now.weekday % 3],
      BodyGoal.leanToned => now.weekday.isEven ? daily : pull,
      BodyGoal.fatLoss => now.weekday.isEven ? legs : daily,
      BodyGoal.endurance => legs,
    };
  }
}

/// Solo-Leveling-style status window. Stats are derived from real data.
class _StatusWindow extends StatelessWidget {
  const _StatusWindow({required this.state});

  final EonState state;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = state;
    final week = s.weeklyQuests;
    final trainDays = week.first.current.toInt();

    final stats = [
      ('STR', 10 + s.level + trainDays * 3, Icons.fitness_center_rounded),
      ('AGI', 10 + s.steps ~/ 800, Icons.directions_run_rounded),
      ('VIT', 10 + (s.waterProgress * 20).round(), Icons.favorite_rounded),
      ('SEN', 10 + s.streak * 2, Icons.visibility_rounded),
    ];

    return GlassCard(
      beveled: true,
      highlight: true,
      blur: true,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 56, height: 72, child: HunterFigure()),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STATUS',
                      style: eonText(
                        12,
                        weight: FontWeight.w700,
                        letterSpacing: 3,
                        color: p.highlight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: eonText(20, weight: FontWeight.w700),
                    ),
                    Text(
                      'Level ${s.level} · ${s.bodyGoal.label}',
                      style: eonText(13, color: p.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _StatCell(
                    label: stats[i].$1,
                    value: stats[i].$2,
                    icon: stats[i].$3,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Daily XP', style: eonText(12, color: p.textMuted)),
              const Spacer(),
              Text(
                '${(s.levelProgress * 100).round()}%',
                style: eonText(12, weight: FontWeight.w600, color: p.highlight),
              ),
            ],
          ),
          const SizedBox(height: 6),
          EonProgressBar(value: s.levelProgress),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: p.accent.withValues(alpha: p.isDark ? 0.14 : 0.08),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: p.highlight, shadows: p.textGlow(0.6)),
          const SizedBox(height: 4),
          Text('$value', style: eonText(17, weight: FontWeight.w700)),
          Text(
            label,
            style: eonText(10.5, letterSpacing: 1.5, color: p.textMuted),
          ),
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.advice});

  final TrainerAdvice advice;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      highlight: !advice.done,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(
            icon: advice.done ? Icons.check_rounded : advice.icon,
            filled: advice.done,
            size: 40,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advice.title,
                  style: eonText(15.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  advice.body,
                  style: eonText(13, color: p.textMuted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Slides + fades children in one after another on first build.
class _StaggeredIn extends StatelessWidget {
  const _StaggeredIn({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + 70 * math.min(index, 8)),
      curve: Curves.easeOutCubic,
      builder:
          (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - t)),
              child: child,
            ),
          ),
      child: child,
    );
  }
}
