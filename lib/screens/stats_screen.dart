import 'package:flutter/material.dart';

import '../state/eon_state.dart';
import '../theme/eon_theme.dart';
import '../widgets/widgets.dart';
import 'trainer_screen.dart';

/// "Stats of Concern": routine tabs, desired body state, exercise list
/// (tap to mark done) and the Personal Trainer AI card.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, this.standalone = false});

  /// True when pushed as its own page (adds a back button + Scaffold).
  final bool standalone;

  @override
  Widget build(BuildContext context) {
    final s = context.eon;
    final p = context.palette;
    final routine = s.currentRoutine;
    final done = s.doneCount(routine);

    final content = EonBackground(
      child: SafeArea(
        bottom: standalone,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                if (standalone)
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                Icon(
                  Icons.bar_chart_rounded,
                  size: 34,
                  color: p.highlight,
                  shadows: p.textGlow(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Stats of Concern',
                    style: eonText(24, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            EonTabs(
              beveled: true,
              height: 50,
              fontSize: 18,
              labels: [for (final r in s.routines) r.name],
              index: s.routineIndex,
              onChanged: s.selectRoutine,
            ),
            const SizedBox(height: 18),
            const _BodyStateCard(),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  '${routine.name} routine',
                  style: eonText(14, color: p.textMuted),
                ),
                const Spacer(),
                Text(
                  '$done/${routine.exercises.length} done',
                  style: eonText(
                    14,
                    weight: FontWeight.w600,
                    color: p.highlight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final e in routine.exercises)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ExerciseTile(routine: routine, exercise: e),
              ),
            const SizedBox(height: 6),
            const _TrainerCard(),
          ],
        ),
      ),
    );

    if (!standalone) return content;
    return Scaffold(backgroundColor: p.background, body: content);
  }
}

class _BodyStateCard extends StatelessWidget {
  const _BodyStateCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      beveled: true,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          const SectionLabel(
            'Your Desired Body State',
            icon: Icons.track_changes_rounded,
          ),
          const SizedBox(height: 14),
          for (var row = 0; row < 2; row++) ...[
            if (row > 0) const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _GoalChip(goal: BodyGoal.values[row * 2])),
                const SizedBox(width: 10),
                Expanded(child: _GoalChip(goal: BodyGoal.values[row * 2 + 1])),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.goal});

  final BodyGoal goal;

  @override
  Widget build(BuildContext context) {
    final s = context.eon;
    final p = context.palette;
    final selected = s.bodyGoal == goal;

    return Semantics(
      button: true,
      selected: selected,
      label: goal.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => s.setBodyGoal(goal),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color:
                selected
                    ? p.accent.withValues(alpha: p.isDark ? 0.3 : 0.14)
                    : p.surfaceBottom.withValues(alpha: p.isDark ? 0.5 : 0.8),
            border: Border.all(
              color: selected ? p.highlight : p.border,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected ? p.boxGlow(strength: 0.9) : const [],
          ),
          child: Row(
            children: [
              Icon(
                goal.icon,
                size: 22,
                color: p.highlight,
                shadows: p.textGlow(0.7),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    goal.label,
                    style: eonText(
                      14,
                      weight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.routine, required this.exercise});

  final Routine routine;
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final s = context.eon;
    final p = context.palette;
    final done = s.isExerciseDone(routine, exercise);

    return Semantics(
      label:
          '${exercise.name}, ${exercise.scheme}, '
          '${done ? 'done' : 'not done'}. Tap to toggle.',
      child: GlassCard(
        beveled: true,
        radius: 16,
        highlight: done,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => s.toggleExercise(routine, exercise),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder:
                  (child, anim) => ScaleTransition(scale: anim, child: child),
              child: IconBadge(
                key: ValueKey(done),
                icon: done ? Icons.check_rounded : exercise.icon,
                filled: done,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                exercise.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: eonText(17, color: done ? p.highlight : p.text),
              ),
            ),
            const SizedBox(width: 8),
            Text(exercise.scheme, style: eonText(17)),
          ],
        ),
      ),
    );
  }
}

class _TrainerCard extends StatelessWidget {
  const _TrainerCard();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      beveled: true,
      radius: 20,
      highlight: true,
      padding: EdgeInsets.zero,
      onTap:
          () =>
              Navigator.of(context).push(eonRoute<void>(const TrainerScreen())),
      child: SizedBox(
        height: 150,
        child: Row(
          children: [
            const SizedBox(width: 8),
            const Expanded(
              flex: 9,
              child: Padding(
                padding: EdgeInsets.only(top: 10),
                child: HunterFigure(),
              ),
            ),
            Expanded(
              flex: 11,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Personal Trainer\nAI',
                      style: eonText(20, height: 1.35),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 36,
                    color: p.highlight,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
