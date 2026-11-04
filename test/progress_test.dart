import 'dart:convert';

import 'package:eon_fitness/state/progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dates', () {
    test('dayKey pads and parses back', () {
      final d = DateTime(2026, 3, 7, 23, 59);
      expect(dayKey(d), '2026-03-07');
      expect(parseDayKey('2026-03-07'), DateTime(2026, 3, 7));
    });

    test('weekStart is Monday', () {
      expect(weekStart(DateTime(2026, 11, 4)), DateTime(2026, 11, 2)); // Wed
      expect(weekStart(DateTime(2026, 11, 2)), DateTime(2026, 11, 2)); // Mon
      expect(weekStart(DateTime(2026, 11, 8)), DateTime(2026, 11, 2)); // Sun
    });

    test('addDays crosses month and year boundaries', () {
      expect(addDays(DateTime(2026, 12, 31), 1), DateTime(2027, 1, 1));
      expect(addDays(DateTime(2026, 3, 1), -1), DateTime(2026, 2, 28));
    });
  });

  group('rollOver', () {
    test('archives yesterday and resets counters', () {
      final data =
          ProgressData(todayKey: '2026-11-03')
            ..waterMl = 2600
            ..steps = 12000
            ..calories = 2900
            ..workoutDone = true
            ..doneExercises.add('Daily/Bench Press')
            ..rewarded.addAll({'water', 'w_steps@2026-11-02'});

      final changed = data.rollOver(DateTime(2026, 11, 4, 8));

      expect(changed, isTrue);
      expect(data.todayKey, '2026-11-04');
      expect(data.waterMl, 0);
      expect(data.steps, 0);
      expect(data.workoutDone, isFalse);
      expect(data.doneExercises, isEmpty);
      expect(data.history['2026-11-03']!.complete, isTrue);
      expect(data.history['2026-11-03']!.steps, 12000);
      // Daily rewards reset, weekly rewards for this week survive.
      expect(data.rewarded, {'w_steps@2026-11-02'});
    });

    test('drops last week\'s weekly rewards on a new week', () {
      final data = ProgressData(todayKey: '2026-11-08')
        ..rewarded.add('w_steps@2026-11-02');
      data.rollOver(DateTime(2026, 11, 9));
      expect(data.rewarded, isEmpty);
    });

    test('same day is a no-op', () {
      final data = ProgressData(todayKey: '2026-11-04')..waterMl = 500;
      expect(data.rollOver(DateTime(2026, 11, 4, 23, 59)), isFalse);
      expect(data.waterMl, 500);
    });

    test('clock moving backwards does not archive a future day', () {
      final data = ProgressData(todayKey: '2026-11-05')..waterMl = 900;
      data.rollOver(DateTime(2026, 11, 4));
      expect(data.history.containsKey('2026-11-05'), isFalse);
      expect(data.todayKey, '2026-11-04');
    });
  });

  group('streak', () {
    test('demo profile has a 14-day streak while today is unfinished', () {
      final now = DateTime(2026, 11, 4, 12);
      final data = ProgressData.demo(now);
      expect(data.todayComplete, isFalse);
      expect(data.streak(now), 14);
    });

    test('finishing today extends the streak', () {
      final now = DateTime(2026, 11, 4, 12);
      final data =
          ProgressData.demo(now)
            ..waterMl = 2500
            ..steps = 10000
            ..calories = 2800
            ..workoutDone = true;
      expect(data.todayComplete, isTrue);
      expect(data.streak(now), 15);
    });

    test('a missed day breaks it', () {
      final now = DateTime(2026, 11, 4);
      final data = ProgressData(todayKey: dayKey(now));
      data.history[dayKey(addDays(now, -1))] = const DayRecord(complete: true);
      data.history[dayKey(addDays(now, -3))] = const DayRecord(complete: true);
      expect(data.streak(now), 1);
    });
  });

  test('week totals sum Monday..yesterday plus today', () {
    final now = DateTime(2026, 11, 4); // Wednesday
    final data =
        ProgressData(todayKey: dayKey(now))
          ..waterMl = 1000
          ..steps = 3000;
    data.history['2026-11-02'] = const DayRecord(
      waterMl: 2000,
      steps: 9000,
      workout: true,
    );
    data.history['2026-11-03'] = const DayRecord(waterMl: 1500, steps: 4000);
    data.history['2026-11-01'] = // previous Sunday: not this week
        const DayRecord(waterMl: 9999, steps: 99999, workout: true);
    final w = data.week(now);
    expect(w.waterMl, 4500);
    expect(w.steps, 16000);
    expect(w.trainingDays, 1);
  });

  group('json', () {
    test('round-trips', () {
      final now = DateTime(2026, 11, 4);
      final a =
          ProgressData.demo(now)
            ..untracked.add('carbs')
            ..doneExercises.add('Legs/Leg Press');
      final b = ProgressData.fromJson(
        (jsonDecode(jsonEncode(a.toJson())) as Map).cast<String, Object?>(),
        now,
      );
      expect(jsonEncode(b.toJson()), jsonEncode(a.toJson()));
    });

    test('survives garbage without throwing', () {
      final now = DateTime(2026, 11, 4);
      final d = ProgressData.fromJson({
        'todayKey': 'not-a-date',
        'level': 'seven',
        'waterMl': 12.7,
        'history': {
          '2026-11-01': 'oops',
          'x': {'w': 'y'},
        },
        'targets': [1, 2, 3],
        'rewarded': [1, 'water', null],
      }, now);
      expect(d.todayKey, '2026-11-04');
      expect(d.level, 1);
      expect(d.waterMl, 13);
      expect(d.history.length, 1); // only the map-shaped entry
      expect(d.targets.waterMl, 2500);
      expect(d.rewarded, {'water'});
    });
  });
}
