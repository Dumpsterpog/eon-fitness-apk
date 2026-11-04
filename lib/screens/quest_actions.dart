import 'package:flutter/material.dart';

import '../state/eon_state.dart';
import '../theme/eon_theme.dart';
import '../widgets/widgets.dart';
import 'diet_plan_screen.dart';
import 'main_shell.dart';
import 'stats_screen.dart';
import 'water_intake_screen.dart';

/// What happens when a quest card is tapped (Home + Quests screens).
void openQuest(BuildContext context, Quest quest) {
  switch (quest.action) {
    case QuestAction.water:
      Navigator.of(context).push(eonRoute<void>(const WaterIntakeScreen()));
    case QuestAction.calories:
      Navigator.of(context).push(eonRoute<void>(const DietPlanScreen()));
    case QuestAction.workout:
      final shell = MainShell.maybeOf(context);
      if (shell != null) {
        shell.goToTab(1);
      } else {
        Navigator.of(
          context,
        ).push(eonRoute<void>(const StatsScreen(standalone: true)));
      }
    case QuestAction.steps:
      final state = context.eonRead;
      showQuickAddSheet(
        context,
        title: 'Log Steps',
        unit: 'steps',
        icon: Icons.directions_run_rounded,
        subtitle:
            '${fmtThousands(state.steps)} / ${fmtThousands(state.stepsTarget)} today',
        amounts: const [500, 1000, 2500],
        onAdd: state.addSteps,
      );
    case QuestAction.none:
      return;
  }
}
