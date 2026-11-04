// Pure-Dart progress model: today's counters, targets, day history, rollover,
// streaks and weekly totals. No Flutter imports, so it is unit-tested on the
// plain Dart VM (see test/progress_test.dart).

import 'dart:math' as math;

/// Local calendar day as 'yyyy-mm-dd'.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

String _two(int n) => n.toString().padLeft(2, '0');

DateTime parseDayKey(String key) {
  final parts = key.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Calendar arithmetic that is safe across DST changes (unlike adding
/// `Duration(days: n)`).
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

/// Monday of the week containing [d].
DateTime weekStart(DateTime d) => addDays(dateOnly(d), -(d.weekday - 1));

/// Daily targets the quests are measured against.
class Targets {
  Targets({
    this.waterMl = 2500,
    this.steps = 10000,
    this.calories = 2800,
    this.protein = 110,
    this.carbs = 150,
  });

  int waterMl;
  int steps;
  int calories;
  int protein;
  int carbs;

  Map<String, Object?> toJson() => {
    'waterMl': waterMl,
    'steps': steps,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
  };

  factory Targets.fromJson(Map<String, Object?> j) {
    final d = Targets();
    return Targets(
      waterMl: _int(j['waterMl'], d.waterMl),
      steps: _int(j['steps'], d.steps),
      calories: _int(j['calories'], d.calories),
      protein: _int(j['protein'], d.protein),
      carbs: _int(j['carbs'], d.carbs),
    );
  }
}

/// What happened on one past day.
class DayRecord {
  const DayRecord({
    this.waterMl = 0,
    this.steps = 0,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.workout = false,
    this.complete = false,
  });

  final int waterMl;
  final int steps;
  final int calories;
  final int protein;
  final int carbs;
  final bool workout;

  /// All daily quests were cleared that day (counts toward the streak).
  final bool complete;

  Map<String, Object?> toJson() => {
    'w': waterMl,
    's': steps,
    'c': calories,
    'p': protein,
    'cb': carbs,
    'wo': workout,
    'ok': complete,
  };

  factory DayRecord.fromJson(Map<String, Object?> j) => DayRecord(
    waterMl: _int(j['w'], 0),
    steps: _int(j['s'], 0),
    calories: _int(j['c'], 0),
    protein: _int(j['p'], 0),
    carbs: _int(j['cb'], 0),
    workout: j['wo'] == true,
    complete: j['ok'] == true,
  );
}

/// Sums for the current Monday–Sunday week, today included.
class WeekTotals {
  const WeekTotals({
    required this.waterMl,
    required this.steps,
    required this.trainingDays,
  });

  final int waterMl;
  final int steps;
  final int trainingDays;
}

/// Everything about the hunter's progress that is persisted.
class ProgressData {
  ProgressData({
    required this.todayKey,
    Targets? targets,
    this.level = 1,
    this.waterMl = 0,
    this.steps = 0,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.workoutDone = false,
    this.bodyGoal = 'buildMuscle',
    this.routineIndex = 0,
    Set<String>? doneExercises,
    Set<String>? rewarded,
    Set<String>? untracked,
    Map<String, DayRecord>? history,
  }) : targets = targets ?? Targets(),
       doneExercises = doneExercises ?? <String>{},
       rewarded = rewarded ?? <String>{},
       untracked = untracked ?? <String>{},
       history = history ?? <String, DayRecord>{};

  static const schemaVersion = 1;

  /// Days of history kept on device.
  static const historyDays = 400;

  String todayKey;
  Targets targets;
  int level;

  // Today's counters.
  int waterMl;
  int steps;
  int calories;
  int protein;
  int carbs;

  /// Set by the app whenever an entire routine has been ticked off today.
  bool workoutDone;

  String bodyGoal;
  int routineIndex;

  /// 'Routine/Exercise' keys ticked off today.
  final Set<String> doneExercises;

  /// Quest ids that already granted a level today (daily: 'water'),
  /// or this week (weekly: 'w_steps@2026-11-02'). Stops re-farming a quest by
  /// un-ticking and re-ticking it.
  final Set<String> rewarded;

  /// Nutrients the hunter switched tracking off for.
  final Set<String> untracked;

  /// Past days keyed by [dayKey]. Today is NOT in here until it rolls over.
  final Map<String, DayRecord> history;

  bool get waterDone => waterMl >= targets.waterMl;
  bool get stepsDone => steps >= targets.steps;
  bool get caloriesDone => calories >= targets.calories;

  bool get todayComplete =>
      waterDone && stepsDone && caloriesDone && workoutDone;

  DayRecord snapshotToday() => DayRecord(
    waterMl: waterMl,
    steps: steps,
    calories: calories,
    protein: protein,
    carbs: carbs,
    workout: workoutDone,
    complete: todayComplete,
  );

  /// Archives "today" into [history] and resets the counters if the calendar
  /// day has changed since the data was last touched. Returns true if it did.
  bool rollOver(DateTime now) {
    final key = dayKey(now);
    if (key == todayKey) return false;

    // Never archive a day that is in the future relative to now (clock moved
    // backwards); just start the new day.
    if (parseDayKey(todayKey).isBefore(dateOnly(now))) {
      history[todayKey] = snapshotToday();
    }

    todayKey = key;
    waterMl = 0;
    steps = 0;
    calories = 0;
    protein = 0;
    carbs = 0;
    workoutDone = false;
    doneExercises.clear();

    final thisWeek = dayKey(weekStart(now));
    rewarded.removeWhere((id) {
      final at = id.indexOf('@');
      if (at < 0) return true; // daily reward: reset every day
      return id.substring(at + 1) != thisWeek; // weekly: reset each week
    });

    _pruneHistory(now);
    return true;
  }

  void _pruneHistory(DateTime now) {
    final oldest = dayKey(addDays(now, -historyDays));
    history.removeWhere((k, _) => k.compareTo(oldest) < 0);
  }

  bool isDayComplete(DateTime d) {
    final key = dayKey(d);
    if (key == todayKey) return todayComplete;
    return history[key]?.complete ?? false;
  }

  /// Consecutive completed days ending today (or yesterday, if today isn't
  /// finished yet — the streak isn't broken until the day is over).
  int streak(DateTime now) {
    var day = dateOnly(now);
    if (!isDayComplete(day)) day = addDays(day, -1);
    var count = 0;
    while (isDayComplete(day)) {
      count++;
      day = addDays(day, -1);
      if (count > historyDays) break;
    }
    return count;
  }

  WeekTotals week(DateTime now) {
    var water = waterMl;
    var walked = steps;
    var training = workoutDone ? 1 : 0;
    final today = dateOnly(now);
    for (var d = weekStart(now); d.isBefore(today); d = addDays(d, 1)) {
      final r = history[dayKey(d)];
      if (r == null) continue;
      water += r.waterMl;
      walked += r.steps;
      if (r.workout) training++;
    }
    return WeekTotals(waterMl: water, steps: walked, trainingDays: training);
  }

  // ---- Serialisation -------------------------------------------------------

  Map<String, Object?> toJson() => {
    'v': schemaVersion,
    'todayKey': todayKey,
    'targets': targets.toJson(),
    'level': level,
    'waterMl': waterMl,
    'steps': steps,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'workoutDone': workoutDone,
    'bodyGoal': bodyGoal,
    'routineIndex': routineIndex,
    'doneExercises': doneExercises.toList(),
    'rewarded': rewarded.toList(),
    'untracked': untracked.toList(),
    'history': {for (final e in history.entries) e.key: e.value.toJson()},
  };

  /// Tolerant of missing/garbled fields so a bad write can never brick the
  /// app: anything unreadable falls back to its default.
  factory ProgressData.fromJson(Map<String, Object?> j, DateTime now) {
    final rawHistory = j['history'];
    final history = <String, DayRecord>{};
    if (rawHistory is Map) {
      rawHistory.forEach((k, v) {
        if (k is String && v is Map) {
          history[k] = DayRecord.fromJson(v.cast<String, Object?>());
        }
      });
    }
    final rawTargets = j['targets'];
    final todayKey = j['todayKey'];
    return ProgressData(
      todayKey:
          todayKey is String && _isDayKey(todayKey) ? todayKey : dayKey(now),
      targets:
          rawTargets is Map
              ? Targets.fromJson(rawTargets.cast<String, Object?>())
              : null,
      level: math.max(1, _int(j['level'], 1)),
      waterMl: _int(j['waterMl'], 0),
      steps: _int(j['steps'], 0),
      calories: _int(j['calories'], 0),
      protein: _int(j['protein'], 0),
      carbs: _int(j['carbs'], 0),
      workoutDone: j['workoutDone'] == true,
      bodyGoal:
          j['bodyGoal'] is String ? j['bodyGoal']! as String : 'buildMuscle',
      routineIndex: _int(j['routineIndex'], 0),
      doneExercises: _stringSet(j['doneExercises']),
      rewarded: _stringSet(j['rewarded']),
      untracked: _stringSet(j['untracked']),
      history: history,
    );
  }

  // ---- Seed data -----------------------------------------------------------

  /// A believable 'already playing for two weeks' profile for showcasing:
  /// a 14-day streak, some partial days before it, and today half done.
  /// Deterministic so screenshots are reproducible.
  factory ProgressData.demo(DateTime now) {
    final rnd = math.Random(2026);
    final t = Targets();
    final history = <String, DayRecord>{};
    for (var i = 1; i <= 24; i++) {
      final day = addDays(now, -i);
      final streakDay = i <= 14;
      final skipped = !streakDay && rnd.nextInt(3) == 0;
      if (skipped) continue;
      int around(int target, {double min = 1.0, double max = 1.25}) =>
          (target * (min + rnd.nextDouble() * (max - min))).round();
      final full = streakDay || rnd.nextBool();
      history[dayKey(day)] = DayRecord(
        waterMl:
            full ? around(t.waterMl) : around(t.waterMl, min: 0.5, max: 0.9),
        steps: full ? around(t.steps) : around(t.steps, min: 0.3, max: 0.9),
        calories:
            full
                ? around(t.calories, max: 1.1)
                : around(t.calories, min: 0.6, max: 0.95),
        protein: around(t.protein, min: 0.7, max: 1.1),
        carbs: around(t.carbs, min: 0.7, max: 1.1),
        workout: full,
        complete: full,
      );
    }
    return ProgressData(
      todayKey: dayKey(now),
      targets: t,
      level: 7,
      waterMl: 1500,
      steps: 2800,
      calories: 1500,
      protein: 60,
      carbs: 75,
      history: history,
    );
  }

  /// A clean slate for a hunter who wants to start from zero.
  factory ProgressData.fresh(DateTime now) =>
      ProgressData(todayKey: dayKey(now));
}

bool _isDayKey(String s) => RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s);

int _int(Object? v, int fallback) => switch (v) {
  final int i => i,
  final double d when d.isFinite => d.round(),
  _ => fallback,
};

Set<String> _stringSet(Object? v) =>
    v is List ? v.whereType<String>().toSet() : <String>{};
