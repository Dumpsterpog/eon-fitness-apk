import 'package:flutter/material.dart';

import '../state/account.dart';
import '../state/eon_state.dart';
import '../theme/eon_theme.dart';
import '../widgets/widgets.dart';
import 'calendar_screen.dart';
import 'diet_plan_screen.dart';
import 'trainer_screen.dart';
import 'water_intake_screen.dart';
import 'welcome_screen.dart';

/// Profile tab: hunter card, appearance (dark / light / system), targets,
/// shortcuts and local-data controls.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.eon;
    final p = context.palette;
    final cleared = s.todayQuests.where((q) => q.isComplete).length;
    final since = s.memberSince;

    void open(Widget page) => Navigator.of(context).push(eonRoute<void>(page));

    return EonBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  size: 30,
                  color: p.highlight,
                  shadows: p.textGlow(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Profile',
                    style: eonText(24, weight: FontWeight.w600),
                  ),
                ),
                const ThemeToggleButton(),
              ],
            ),
            const SizedBox(height: 18),
            GlassCard(
              highlight: true,
              blur: true,
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              child: Column(
                children: [
                  _Avatar(name: s.userName),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          s.userName,
                          overflow: TextOverflow.ellipsis,
                          style: eonText(22, weight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit name',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _editName(context),
                        icon: Icon(
                          Icons.edit_rounded,
                          size: 18,
                          color: p.highlight,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Level ${s.level} Hunter',
                    style: eonText(
                      14,
                      weight: FontWeight.w600,
                      color: p.highlight,
                    ),
                  ),
                  if (s.email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(s.email, style: eonText(13, color: p.textMuted)),
                  ],
                  if (since != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Awakened ${_months[since.month - 1]} ${since.year}',
                      style: eonText(12, color: p.textFaint),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Daily XP', style: eonText(12, color: p.textMuted)),
                      const Spacer(),
                      Text(
                        '$cleared / ${s.todayQuests.length} quests',
                        style: eonText(
                          12,
                          weight: FontWeight.w600,
                          color: p.highlight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  EonProgressBar(value: s.levelProgress),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StatChip(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Streak',
                    value: '${s.streak} days',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatChip(
                    icon: Icons.verified_rounded,
                    label: 'Days cleared',
                    value: '${s.totalClearedDays}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatChip(
                    icon: s.bodyGoal.icon,
                    label: 'Goal',
                    value: s.bodyGoal.label,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const SectionLabel('Appearance', icon: Icons.palette_rounded),
            const SizedBox(height: 12),
            const ThemeModeSelector(),
            const SizedBox(height: 22),
            const SectionLabel('Quest Log', icon: Icons.explore_rounded),
            const SizedBox(height: 12),
            _Tile(
              icon: Icons.tune_rounded,
              label: 'Daily Targets',
              subtitle:
                  '${fmtThousands(s.stepsTarget)} steps · '
                  '${fmtLitres(s.waterTargetMl)} · '
                  '${fmtThousands(s.nutrientTarget(NutrientGoal.calories))} kcal',
              onTap: () => _editTargets(context),
            ),
            _Tile(
              icon: Icons.calendar_month_rounded,
              label: 'Streak Calendar',
              onTap: () => open(const CalendarScreen()),
            ),
            _Tile(
              icon: Icons.water_drop_rounded,
              label: 'Water Intake',
              onTap: () => open(const WaterIntakeScreen()),
            ),
            _Tile(
              icon: Icons.restaurant_rounded,
              label: 'Diet Plan',
              onTap: () => open(const DietPlanScreen()),
            ),
            _Tile(
              icon: Icons.psychology_rounded,
              label: 'Personal Trainer AI',
              onTap: () => open(const TrainerScreen()),
            ),
            const SizedBox(height: 12),
            const SectionLabel('Data', icon: Icons.storage_rounded),
            const SizedBox(height: 12),
            _Tile(
              icon: Icons.auto_awesome_rounded,
              label: 'Load Demo Progress',
              subtitle: 'Sample 14-day streak for showcasing',
              onTap: () => _confirmReset(context, demo: true),
            ),
            _Tile(
              icon: Icons.restart_alt_rounded,
              label: 'Reset Progress',
              subtitle: 'Start again from level 1',
              onTap: () => _confirmReset(context, demo: false),
            ),
            _Tile(
              icon: Icons.logout_rounded,
              label: 'Log Out',
              onTap: () => _logOut(context),
            ),
            _Tile(
              icon: Icons.delete_forever_rounded,
              label: 'Delete Account',
              subtitle: 'Removes the hunter and all progress from this phone',
              danger: true,
              onTap: () => _deleteAccount(context),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Eon Fitness 1.0 · all data is stored on this device',
                style: eonText(11.5, color: p.textFaint),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _goToWelcome(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      eonRoute<void>(const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<void> _logOut(BuildContext context) async {
    await context.eonRead.logOut();
    if (context.mounted) _goToWelcome(context);
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final ok = await _confirm(
      context,
      title: 'Delete this hunter?',
      body:
          'Your account, streak and all logged progress will be removed '
          'from this phone. This cannot be undone.',
      action: 'Delete',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    await context.eonRead.deleteAccount();
    if (context.mounted) _goToWelcome(context);
  }

  Future<void> _confirmReset(BuildContext context, {required bool demo}) async {
    final ok = await _confirm(
      context,
      title: demo ? 'Load demo progress?' : 'Reset all progress?',
      body:
          demo
              ? 'Replaces your current progress with a sample 14-day streak and '
                  "today's quests half done."
              : 'Your level, streak and history go back to zero. Your account '
                  'stays.',
      action: demo ? 'Load demo' : 'Reset',
      danger: !demo,
    );
    if (!ok || !context.mounted) return;
    context.eonRead.resetProgress(demo: demo);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            demo ? 'Demo progress loaded.' : 'Progress reset. Level 1, Hunter.',
          ),
        ),
      );
  }

  static Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
    bool danger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final error = Theme.of(context).colorScheme.error;
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style:
                  danger ? TextButton.styleFrom(foregroundColor: error) : null,
              child: Text(action),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _editName(BuildContext context) async {
    final state = context.eonRead;
    final controller = TextEditingController(text: state.userName);
    final formKey = GlobalKey<FormState>();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        void submit() {
          if (formKey.currentState?.validate() ?? false) {
            Navigator.of(context).pop(controller.text.trim());
          }
        }

        return AlertDialog(
          title: const Text('Hunter name'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              maxLength: 20,
              textCapitalization: TextCapitalization.words,
              validator: AccountRules.name,
              onFieldSubmitted: (_) => submit(),
              decoration: const InputDecoration(counterText: ''),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(onPressed: submit, child: const Text('Save')),
          ],
        );
      },
    );
    controller.dispose();
    if (name != null) state.rename(name);
  }

  void _editTargets(BuildContext context) {
    showEonSheet<void>(context, builder: (_) => const _TargetsSheet());
  }
}

class _TargetsSheet extends StatelessWidget {
  const _TargetsSheet();

  @override
  Widget build(BuildContext context) {
    final s = context.eon;
    return EonSheet(
      title: 'Daily Targets',
      icon: Icons.tune_rounded,
      subtitle: 'Quests and the weekly goals scale with these.',
      child: Column(
        children: [
          _TargetSlider(
            label: 'Steps',
            value: s.stepsTarget,
            min: 2000,
            max: 25000,
            step: 500,
            format: fmtThousands,
            onChanged: s.setStepsTarget,
          ),
          _TargetSlider(
            label: 'Water',
            value: s.waterTargetMl,
            min: 1000,
            max: 5000,
            step: 250,
            format: fmtLitres,
            onChanged: s.setWaterTarget,
          ),
          _TargetSlider(
            label: 'Calories',
            value: s.nutrientTarget(NutrientGoal.calories),
            min: 1200,
            max: 4500,
            step: 50,
            format: (v) => '${fmtThousands(v)} kcal',
            onChanged: (v) => s.setNutrientTarget(NutrientGoal.calories, v),
          ),
          _TargetSlider(
            label: 'Protein',
            value: s.nutrientTarget(NutrientGoal.protein),
            min: 40,
            max: 250,
            step: 5,
            format: (v) => '$v g',
            onChanged: (v) => s.setNutrientTarget(NutrientGoal.protein, v),
          ),
          _TargetSlider(
            label: 'Carbs',
            value: s.nutrientTarget(NutrientGoal.carbs),
            min: 50,
            max: 450,
            step: 5,
            format: (v) => '$v g',
            onChanged: (v) => s.setNutrientTarget(NutrientGoal.carbs, v),
          ),
        ],
      ),
    );
  }
}

class _TargetSlider extends StatelessWidget {
  const _TargetSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.format,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final String Function(int) format;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final v = value.clamp(min, max);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        children: [
          Row(
            children: [
              Text(label, style: eonText(14.5, weight: FontWeight.w600)),
              const Spacer(),
              Text(
                format(v),
                style: eonText(14, color: p.highlight, weight: FontWeight.w600),
              ),
            ],
          ),
          Slider(
            value: v.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: (max - min) ~/ step,
            label: format(v),
            onChanged: (d) => onChanged((d / step).round() * step),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(p.accent, Colors.white, 0.15)!, p.accentDeep],
            ),
            border: Border.all(color: p.highlight, width: 1.6),
            boxShadow: p.boxGlow(strength: 1.4),
          ),
          child: Text(
            name.isEmpty ? '?' : name.characters.first.toUpperCase(),
            style: eonText(40, weight: FontWeight.w700, color: p.onAccent),
          ),
        ),
        const Positioned(top: -18, child: CrownIcon(size: 30)),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Column(
        children: [
          Icon(icon, color: p.highlight, shadows: p.textGlow()),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: eonText(14, weight: FontWeight.w600)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: eonText(12, color: p.textMuted)),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = danger ? Theme.of(context).colorScheme.error : p.highlight;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: accent, shadows: danger ? null : p.textGlow()),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: eonText(16, color: danger ? accent : null),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: eonText(12, color: p.textMuted)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.textMuted),
          ],
        ),
      ),
    );
  }
}
