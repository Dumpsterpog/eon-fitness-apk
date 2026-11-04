import 'package:flutter/material.dart';

import '../state/eon_state.dart';
import '../theme/eon_theme.dart';
import '../widgets/widgets.dart';

/// Monthly calendar with streak days highlighted + streak banner.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
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
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _weekdayLong = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  late final DateTime _today = _dateOnly(DateTime.now());
  late DateTime _month = DateTime(_today.year, _today.month);
  late DateTime _selected = _today;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final s = context.eon;
    final p = context.palette;

    final first = DateTime(_month.year, _month.month);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = first.weekday - 1; // Monday-first grid
    final cells = ((leading + daysInMonth + 6) ~/ 7) * 7;

    return Scaffold(
      backgroundColor: p.background,
      body: EonBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              EonHeader(
                title: 'Calendar',
                icon: Icons.calendar_month_rounded,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassCard(
                  blur: true,
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Previous month',
                            onPressed: () => _shiftMonth(-1),
                            icon: const Icon(Icons.chevron_left_rounded),
                          ),
                          Expanded(
                            child: Text(
                              '${_months[_month.month - 1]} ${_month.year}',
                              textAlign: TextAlign.center,
                              style: eonText(18, weight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Next month',
                            onPressed: () => _shiftMonth(1),
                            icon: const Icon(Icons.chevron_right_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          for (var i = 0; i < 7; i++)
                            Expanded(
                              child: Center(
                                child: Text(
                                  _weekdays[i],
                                  style: eonText(
                                    13,
                                    color: i == 6 ? p.highlight : p.textMuted,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      for (var week = 0; week < cells ~/ 7; week++)
                        Row(
                          children: [
                            for (var col = 0; col < 7; col++)
                              Expanded(
                                child: _buildCell(
                                  s,
                                  week * 7 + col - leading + 1,
                                  daysInMonth,
                                  col,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SelectedDayCard(
                  title:
                      '${_weekdayLong[_selected.weekday - 1]}, '
                      '${_months[_selected.month - 1]} ${_selected.day}',
                  status: _statusFor(s, _selected),
                  complete: s.isDayComplete(_selected),
                  detail: _detailFor(s, _selected),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _StreakBanner(streak: s.streak),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(EonState s, int day, int daysInMonth, int col) {
    if (day < 1 || day > daysInMonth) {
      return const AspectRatio(aspectRatio: 1, child: SizedBox.shrink());
    }
    final date = DateTime(_month.year, _month.month, day);
    return _DayCell(
      day: day,
      isToday: date == _today,
      isSelected: date == _selected,
      isComplete: s.isDayComplete(date),
      isFuture: date.isAfter(_today),
      isSunday: col == 6,
      onTap: () => setState(() => _selected = date),
    );
  }

  String? _detailFor(EonState s, DateTime d) {
    final r = s.recordFor(d);
    if (r == null || d.isAfter(_today)) return null;
    return '${fmtLitres(r.waterMl)} water · ${fmtThousands(r.steps)} steps · '
        '${fmtThousands(r.calories)} kcal${r.workout ? ' · workout' : ''}';
  }

  String _statusFor(EonState s, DateTime d) {
    if (s.isDayComplete(d)) return 'All daily quests cleared';
    if (d == _today) {
      final cleared = s.todayQuests.where((q) => q.isComplete).length;
      return 'In progress: $cleared/${s.todayQuests.length} quests cleared';
    }
    if (d.isAfter(_today)) return 'Upcoming';
    return 'No quests cleared';
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.isComplete,
    required this.isFuture,
    required this.isSunday,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final bool isComplete;
  final bool isFuture;
  final bool isSunday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final Color textColor;
    if (isToday) {
      textColor = p.onAccent;
    } else if (isFuture) {
      textColor = p.textFaint;
    } else if (isSunday || isComplete) {
      textColor = p.highlight;
    } else {
      textColor = p.text;
    }

    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Semantics(
          button: true,
          selected: isSelected,
          label:
              'Day $day${isComplete ? ', quests cleared' : ''}'
              '${isToday ? ', today' : ''}',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient:
                    isToday
                        ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(p.accent, Colors.white, 0.15)!,
                            p.accentDeep,
                          ],
                        )
                        : null,
                color:
                    !isToday && isComplete
                        ? p.accent.withValues(alpha: p.isDark ? 0.22 : 0.14)
                        : null,
                border: Border.all(
                  color:
                      isSelected
                          ? p.highlight
                          : isToday || isComplete
                          ? p.highlight.withValues(alpha: 0.45)
                          : Colors.transparent,
                  width: isSelected ? 1.6 : 1,
                ),
                boxShadow: isToday ? p.boxGlow(strength: 1.2) : const [],
              ),
              child: Text(
                '$day',
                style: eonText(
                  15,
                  color: textColor,
                  weight: isToday ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedDayCard extends StatelessWidget {
  const _SelectedDayCard({
    required this.title,
    required this.status,
    required this.complete,
    this.detail,
  });

  final String title;
  final String status;
  final bool complete;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            complete
                ? Icons.verified_rounded
                : Icons.radio_button_unchecked_rounded,
            color: p.highlight,
            shadows: p.textGlow(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: eonText(15, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(status, style: eonText(13, color: p.textMuted)),
                if (detail != null) ...[
                  const SizedBox(height: 4),
                  Text(detail!, style: eonText(12, color: p.textFaint)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final text =
        streak > 0
            ? "You're on a $streak day streak!"
            : 'Clear all quests today to start a streak!';

    return GlassCard(
      highlight: true,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 76,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const FractionallySizedBox(
                alignment: Alignment.centerRight,
                widthFactor: 0.45,
                child: Padding(
                  padding: EdgeInsets.only(top: 6, right: 6),
                  child: HunterFigure(aura: 0.8),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    const CrownIcon(size: 30),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        text,
                        style: eonText(16, weight: FontWeight.w600),
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
