import 'package:flutter/material.dart';

import '../state/eon_state.dart';
import '../theme/eon_theme.dart';
import '../widgets/widgets.dart';
import 'calendar_screen.dart';
import 'main_shell.dart';
import 'quest_actions.dart';

/// Quests tab: Today / Weekly / Completed.
class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.eon;
    final quests = switch (_tab) {
      0 => s.todayQuests,
      1 => s.weeklyQuests,
      _ => s.completedQuests,
    };
    final shell = MainShell.maybeOf(context);
    final p = context.palette;

    return EonBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            EonHeader(
              title: 'Quests',
              icon: Icons.receipt_long_rounded,
              onBack:
                  shell != null
                      ? () => shell.goToTab(0)
                      : () => Navigator.of(context).maybePop(),
              trailing: IconButton(
                tooltip: 'Calendar',
                onPressed:
                    () => Navigator.of(
                      context,
                    ).push(eonRoute<void>(const CalendarScreen())),
                icon: Icon(
                  Icons.calendar_month_rounded,
                  color: p.highlight,
                  shadows: p.textGlow(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: EonTabs(
                labels: const ['Today', 'Weekly', 'Completed'],
                index: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child:
                    quests.isEmpty
                        ? const _EmptyState(key: ValueKey('empty'))
                        : ListView.separated(
                          key: ValueKey(_tab),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: quests.length,
                          separatorBuilder:
                              (context, i) => const SizedBox(height: 12),
                          itemBuilder:
                              (context, i) => _QuestCard(quest: quests[i]),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.quest});

  final Quest quest;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isWater = quest.action == QuestAction.water;

    return GlassCard(
      highlight: quest.isComplete,
      onTap: () => openQuest(context, quest),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Icon(
              quest.icon,
              size: 30,
              color: isWater ? p.water : p.highlight,
              shadows: p.textGlow(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        quest.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: eonText(16, weight: FontWeight.w600),
                      ),
                    ),
                    if (quest.weekly) ...[
                      const SizedBox(width: 8),
                      _Tag(label: 'WEEKLY', color: p.highlight),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  quest.progressLabel,
                  style: eonText(13, color: p.textMuted),
                ),
                const SizedBox(height: 8),
                EonProgressBar(value: quest.progress, height: 5),
              ],
            ),
          ),
          const SizedBox(width: 6),
          quest.isComplete
              ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.verified_rounded,
                  color: p.highlight,
                  shadows: p.textGlow(),
                ),
              )
              : Icon(Icons.chevron_right_rounded, size: 28, color: p.textMuted),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: eonText(
          9.5,
          weight: FontWeight.w700,
          letterSpacing: 1,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CrownIcon(size: 56, glow: 0.6),
          const SizedBox(height: 16),
          Text(
            'No quests cleared yet',
            style: eonText(17, weight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Finish a quest and it will show up here.',
            style: eonText(13.5, color: p.textMuted),
          ),
        ],
      ),
    );
  }
}
