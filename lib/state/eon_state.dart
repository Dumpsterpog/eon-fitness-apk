import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/material.dart';

import '../theme/eon_theme.dart';
import 'account.dart';
import 'progress.dart';
import 'store.dart';

// ---------------------------------------------------------------------------
// Catalogue (static content)
// ---------------------------------------------------------------------------

enum BodyGoal {
  leanToned('Lean & Toned', Icons.accessibility_new_rounded),
  buildMuscle('Build Muscle', Icons.fitness_center_rounded),
  fatLoss('Fat Loss', Icons.local_fire_department_outlined),
  endurance('Improve Endurance', Icons.directions_run_rounded);

  const BodyGoal(this.label, this.icon);
  final String label;
  final IconData icon;

  static BodyGoal byName(String name) =>
      values.firstWhere((g) => g.name == name, orElse: () => buildMuscle);
}

enum NutrientGoal {
  protein('Daily Protein Goal', 'Protein', ' gm', Icons.fitness_center_rounded),
  calories(
    'Calories Goal',
    'Calories',
    '',
    Icons.local_fire_department_rounded,
  ),
  carbs('Carbs Goal', 'Carbs', '', Icons.bakery_dining_rounded);

  const NutrientGoal(this.label, this.shortLabel, this.suffix, this.icon);
  final String label;
  final String shortLabel;
  final String suffix;
  final IconData icon;

  String get unit => switch (this) {
    NutrientGoal.protein => 'g',
    NutrientGoal.calories => 'kcal',
    NutrientGoal.carbs => 'g',
  };

  List<int> get quickAmounts => switch (this) {
    NutrientGoal.protein => [10, 20, 30],
    NutrientGoal.calories => [150, 300, 500],
    NutrientGoal.carbs => [15, 30, 50],
  };
}

class Exercise {
  const Exercise(this.name, this.reps, this.sets, this.icon);

  final String name;
  final int reps;
  final int sets;
  final IconData icon;

  String get scheme => '$reps x $sets';
}

class Routine {
  const Routine(this.name, this.exercises);

  final String name;
  final List<Exercise> exercises;
}

/// Edit these lists to change the workouts shown on the Stats screen.
const List<Routine> kRoutines = [
  Routine('Daily', [
    Exercise('Bench Press', 8, 4, Icons.fitness_center_rounded),
    Exercise('Shoulder Press', 12, 4, Icons.sports_gymnastics_rounded),
    Exercise('Tricep Push', 10, 3, Icons.sports_martial_arts_rounded),
    Exercise('Overhead Extension', 8, 3, Icons.accessibility_new_rounded),
    Exercise('Tricep Dips', 10, 3, Icons.sports_handball_rounded),
    Exercise('Plank Hold', 60, 3, Icons.self_improvement_rounded),
  ]),
  Routine('Pull', [
    Exercise('Pull-Ups', 8, 4, Icons.sports_gymnastics_rounded),
    Exercise('Barbell Row', 10, 4, Icons.rowing_rounded),
    Exercise('Lat Pulldown', 12, 3, Icons.fitness_center_rounded),
    Exercise('Face Pull', 15, 3, Icons.sports_kabaddi_rounded),
    Exercise('Bicep Curl', 12, 3, Icons.sports_handball_rounded),
    Exercise('Hammer Curl', 10, 3, Icons.sports_martial_arts_rounded),
  ]),
  Routine('Legs', [
    Exercise('Back Squat', 8, 4, Icons.accessibility_new_rounded),
    Exercise('Romanian Deadlift', 10, 3, Icons.fitness_center_rounded),
    Exercise('Leg Press', 12, 3, Icons.airline_seat_legroom_extra_rounded),
    Exercise('Walking Lunges', 12, 3, Icons.directions_walk_rounded),
    Exercise('Leg Curl', 12, 3, Icons.hiking_rounded),
    Exercise('Calf Raise', 15, 4, Icons.directions_run_rounded),
  ]),
];

enum QuestAction { water, steps, calories, workout, none }

class Quest {
  const Quest({
    required this.id,
    required this.title,
    required this.icon,
    required this.current,
    required this.target,
    required this.progressLabel,
    this.weekly = false,
    this.action = QuestAction.none,
  });

  final String id;
  final String title;
  final IconData icon;
  final num current;
  final num target;
  final String progressLabel;
  final bool weekly;
  final QuestAction action;

  double get progress =>
      target <= 0 ? 0 : (current / target).clamp(0.0, 1.0).toDouble();
  bool get isComplete => current >= target;
}

// ---------------------------------------------------------------------------
// App state
// ---------------------------------------------------------------------------

/// All app data, persisted locally. Every screen rebuilds on
/// [notifyListeners]; writes are debounced and flushed when the app is
/// backgrounded (see `main.dart`).
class EonState extends ChangeNotifier {
  EonState._(
    this._store,
    this._clock,
    this._data,
    this._account,
    this._themeMode,
    this._loggedIn,
  );

  /// Reads everything from [store]. Corrupt or missing data never throws —
  /// it falls back to defaults so the app always opens.
  factory EonState.load(
    KeyValueStore store, {
    DateTime Function() clock = DateTime.now,
  }) {
    final now = clock();

    Map<String, Object?>? readJson(String key) {
      final raw = store.read(key);
      if (raw == null) return null;
      try {
        final decoded = jsonDecode(raw);
        return decoded is Map ? decoded.cast<String, Object?>() : null;
      } on FormatException {
        return null;
      }
    }

    final accountJson = readJson(StoreKeys.account);
    final account = accountJson == null ? null : Account.tryParse(accountJson);

    final progressJson = readJson(StoreKeys.progress);
    final data =
        progressJson == null
            ? ProgressData.demo(now)
            : ProgressData.fromJson(progressJson, now);

    final settings = readJson(StoreKeys.settings) ?? const {};
    final mode = ThemeMode.values.firstWhere(
      (m) => m.name == settings['themeMode'],
      orElse: () => ThemeMode.dark,
    );
    final loggedIn = account != null && settings['loggedIn'] == true;

    final state = EonState._(store, clock, data, account, mode, loggedIn);
    if (data.rollOver(now)) state._scheduleSave();
    return state;
  }

  final KeyValueStore _store;
  final DateTime Function() _clock;
  ProgressData _data;
  Account? _account;
  ThemeMode _themeMode;
  bool _loggedIn;
  Timer? _saveTimer;
  bool _disposed = false;

  /// Increments every time a quest is cleared for the first time today (or
  /// this week). The shell listens to this and plays the Level Up animation.
  final ValueNotifier<int> levelUps = ValueNotifier<int>(0);

  // ---- Session / profile ---------------------------------------------------

  Account? get account => _account;
  bool get hasAccount => _account != null;
  bool get isLoggedIn => _loggedIn && _account != null;
  String get userName => _account?.name ?? 'Hunter';
  String get email => _account?.email ?? '';
  DateTime? get memberSince => _account?.createdAt;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    _saveSettings();
    notifyListeners();
  }

  /// Flips between dark and light based on what is currently on screen.
  void toggleTheme(Brightness current) => setThemeMode(
    current == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
  );

  /// Creates the local hunter profile. Returns an error message, or null.
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    bool seedDemoProgress = true,
  }) async {
    final error =
        AccountRules.name(name) ??
        AccountRules.email(email) ??
        AccountRules.password(password);
    if (error != null) return error;

    // Hashing is deliberately slow; keep it off the UI thread.
    final account = await _createAccount(name, email, password);
    if (_disposed) return null;

    final now = _clock();
    _account = account;
    _data = seedDemoProgress ? ProgressData.demo(now) : ProgressData.fresh(now);
    _loggedIn = true;
    await Future.wait([
      _store.write(StoreKeys.account, jsonEncode(account.toJson())),
      _writeProgress(),
      _saveSettings(),
    ]);
    notifyListeners();
    return null;
  }

  /// Returns an error message, or null when the credentials match.
  Future<String?> logIn({
    required String email,
    required String password,
  }) async {
    final account = _account;
    if (account == null) {
      return 'No hunter is registered on this device yet. Sign up first.';
    }
    final ok = await _verify(account, email, password);
    if (!ok) return 'Email or password is incorrect.';
    if (_disposed) return null;
    _loggedIn = true;
    rollOverIfNeeded();
    await _saveSettings();
    notifyListeners();
    return null;
  }

  // Static so the isolate closures can't capture `this` (which holds timers
  // and listeners that can't be sent across isolates).
  static Future<Account> _createAccount(
    String name,
    String email,
    String password,
  ) => Isolate.run(
    () => Account.create(name: name, email: email, password: password),
  );

  static Future<bool> _verify(Account account, String email, String password) =>
      Isolate.run(() => account.matches(email: email, password: password));

  Future<void> logOut() async {
    await flush();
    _loggedIn = false;
    await _saveSettings();
    notifyListeners();
  }

  /// Removes the account and all progress from this device.
  Future<void> deleteAccount() async {
    _saveTimer?.cancel();
    _account = null;
    _loggedIn = false;
    _data = ProgressData.demo(_clock());
    await Future.wait([
      _store.delete(StoreKeys.account),
      _store.delete(StoreKeys.progress),
      _saveSettings(),
    ]);
    notifyListeners();
  }

  void rename(String name) {
    final account = _account;
    if (account == null || AccountRules.name(name) != null) return;
    _account = account.rename(name);
    unawaited(_store.write(StoreKeys.account, jsonEncode(_account!.toJson())));
    notifyListeners();
  }

  /// Replaces progress with the demo profile, or with a clean slate.
  void resetProgress({required bool demo}) {
    final now = _clock();
    _data = demo ? ProgressData.demo(now) : ProgressData.fresh(now);
    _scheduleSave();
    notifyListeners();
  }

  // ---- Level ---------------------------------------------------------------

  int get level => _data.level;

  /// Today's cleared quests as a fraction of all quests (for the XP bar).
  double get levelProgress {
    final q = todayQuests;
    return q.where((x) => x.isComplete).length / q.length;
  }

  // ---- Water (ml) ----------------------------------------------------------

  int get waterMl => _data.waterMl;
  int get waterTargetMl => _data.targets.waterMl;
  int get waterRemainingMl => (waterTargetMl - waterMl).clamp(0, 1 << 30);
  double get waterProgress => (waterMl / waterTargetMl).clamp(0.0, 1.0);

  // ---- Steps ---------------------------------------------------------------

  int get steps => _data.steps;
  int get stepsTarget => _data.targets.steps;

  // ---- Nutrition -----------------------------------------------------------

  int nutrient(NutrientGoal g) => switch (g) {
    NutrientGoal.protein => _data.protein,
    NutrientGoal.calories => _data.calories,
    NutrientGoal.carbs => _data.carbs,
  };

  int nutrientTarget(NutrientGoal g) => switch (g) {
    NutrientGoal.protein => _data.targets.protein,
    NutrientGoal.calories => _data.targets.calories,
    NutrientGoal.carbs => _data.targets.carbs,
  };

  double nutrientProgress(NutrientGoal g) =>
      (nutrient(g) / nutrientTarget(g)).clamp(0.0, 1.0);

  bool isTracked(NutrientGoal g) => !_data.untracked.contains(g.name);

  // ---- Training ------------------------------------------------------------

  BodyGoal get bodyGoal => BodyGoal.byName(_data.bodyGoal);
  int get routineIndex => _data.routineIndex.clamp(0, kRoutines.length - 1);
  List<Routine> get routines => kRoutines;
  Routine get currentRoutine => kRoutines[routineIndex];

  static String _exerciseKey(Routine r, Exercise e) => '${r.name}/${e.name}';

  bool isExerciseDone(Routine r, Exercise e) =>
      _data.doneExercises.contains(_exerciseKey(r, e));

  int doneCount(Routine r) =>
      r.exercises.where((e) => isExerciseDone(r, e)).length;

  bool get workoutDone => _data.workoutDone;

  bool _computeWorkoutDone() =>
      kRoutines.any((r) => r.exercises.every((e) => isExerciseDone(r, e)));

  // ---- Streak / calendar ---------------------------------------------------

  bool isDayComplete(DateTime d) => _data.isDayComplete(d);
  int get streak => _data.streak(_clock());
  int get totalClearedDays =>
      _data.history.values.where((r) => r.complete).length +
      (_data.todayComplete ? 1 : 0);
  DayRecord? recordFor(DateTime d) =>
      dayKey(d) == _data.todayKey
          ? _data.snapshotToday()
          : _data.history[dayKey(d)];

  // ---- Quests --------------------------------------------------------------

  List<Quest> get todayQuests {
    final cal = nutrient(NutrientGoal.calories);
    final calTarget = nutrientTarget(NutrientGoal.calories);
    return [
      Quest(
        id: 'water',
        title: 'Drink ${fmtLitres(waterTargetMl)} Water',
        icon: Icons.water_drop_rounded,
        current: waterMl,
        target: waterTargetMl,
        progressLabel: '${fmtLitres(waterMl)} / ${fmtLitres(waterTargetMl)}',
        action: QuestAction.water,
      ),
      Quest(
        id: 'steps',
        title: 'Hit ${fmtCompact(stepsTarget)} Steps',
        icon: Icons.directions_run_rounded,
        current: steps,
        target: stepsTarget,
        progressLabel: '${fmtThousands(steps)} / ${fmtThousands(stepsTarget)}',
        action: QuestAction.steps,
      ),
      Quest(
        id: 'calories',
        title: 'Eat ${fmtThousands(calTarget)} Calories',
        icon: Icons.local_fire_department_rounded,
        current: cal,
        target: calTarget,
        progressLabel: '${fmtThousands(cal)} / ${fmtThousands(calTarget)}',
        action: QuestAction.calories,
      ),
      Quest(
        id: 'workout',
        title: 'Complete Your Workout',
        icon: Icons.fitness_center_rounded,
        current: workoutDone ? 1 : 0,
        target: 1,
        progressLabel: '${workoutDone ? 1 : 0} / 1',
        action: QuestAction.workout,
      ),
    ];
  }

  List<Quest> get weeklyQuests {
    final now = _clock();
    final week = _data.week(now);
    final streakDays = streak.clamp(0, 7);
    final weekStepsTarget = stepsTarget * 7;
    final weekWaterTarget = waterTargetMl * 7;
    return [
      Quest(
        id: 'w_train',
        title: 'Train 5 Days This Week',
        icon: Icons.event_available_rounded,
        current: week.trainingDays,
        target: 5,
        progressLabel: '${week.trainingDays} / 5',
        weekly: true,
        action: QuestAction.workout,
      ),
      Quest(
        id: 'w_steps',
        title: 'Walk ${fmtCompact(weekStepsTarget)} Steps',
        icon: Icons.directions_walk_rounded,
        current: week.steps,
        target: weekStepsTarget,
        progressLabel:
            '${fmtThousands(week.steps)} / ${fmtThousands(weekStepsTarget)}',
        weekly: true,
        action: QuestAction.steps,
      ),
      Quest(
        id: 'w_water',
        title: 'Drink ${fmtLitres(weekWaterTarget)} This Week',
        icon: Icons.water_drop_outlined,
        current: week.waterMl,
        target: weekWaterTarget,
        progressLabel:
            '${fmtLitres(week.waterMl)} / ${fmtLitres(weekWaterTarget)}',
        weekly: true,
        action: QuestAction.water,
      ),
      Quest(
        id: 'w_streak',
        title: 'Keep a 7-Day Streak',
        icon: Icons.military_tech_rounded,
        current: streakDays,
        target: 7,
        progressLabel: '$streakDays / 7',
        weekly: true,
      ),
    ];
  }

  List<Quest> get completedQuests =>
      [...todayQuests, ...weeklyQuests].where((q) => q.isComplete).toList();

  /// First quest of the day that isn't cleared yet (shown on Home).
  Quest? get featuredQuest {
    for (final q in todayQuests) {
      if (!q.isComplete) return q;
    }
    return null;
  }

  // ---- Mutations -----------------------------------------------------------

  void addWater(int ml) =>
      _mutate(() => _data.waterMl = (_data.waterMl + ml).clamp(0, 20000));

  void setWaterTarget(int ml) =>
      _mutate(() => _data.targets.waterMl = ml.clamp(500, 10000));

  void addSteps(int n) =>
      _mutate(() => _data.steps = (_data.steps + n).clamp(0, 200000));

  void setStepsTarget(int n) =>
      _mutate(() => _data.targets.steps = n.clamp(1000, 50000));

  void logNutrient(NutrientGoal g, int amount) => _mutate(() {
    final v = (nutrient(g) + amount).clamp(0, 100000);
    switch (g) {
      case NutrientGoal.protein:
        _data.protein = v;
      case NutrientGoal.calories:
        _data.calories = v;
      case NutrientGoal.carbs:
        _data.carbs = v;
    }
  });

  void setNutrientTarget(NutrientGoal g, int value) => _mutate(() {
    final v = value.clamp(1, 100000);
    switch (g) {
      case NutrientGoal.protein:
        _data.targets.protein = v;
      case NutrientGoal.calories:
        _data.targets.calories = v;
      case NutrientGoal.carbs:
        _data.targets.carbs = v;
    }
  });

  void toggleTracked(NutrientGoal g) {
    if (!_data.untracked.remove(g.name)) _data.untracked.add(g.name);
    _changed();
  }

  void setBodyGoal(BodyGoal g) {
    _data.bodyGoal = g.name;
    _changed();
  }

  void selectRoutine(int i) {
    _data.routineIndex = i.clamp(0, kRoutines.length - 1);
    _changed();
  }

  void toggleExercise(Routine r, Exercise e) => _mutate(() {
    final key = _exerciseKey(r, e);
    if (!_data.doneExercises.remove(key)) _data.doneExercises.add(key);
  });

  /// Call when the app returns to the foreground: starts a new day if the
  /// date changed while the app was in the background.
  void rollOverIfNeeded() {
    if (_data.rollOver(_clock())) {
      _scheduleSave();
      notifyListeners();
    }
  }

  String _rewardId(Quest q) =>
      q.weekly ? '${q.id}@${dayKey(weekStart(_clock()))}' : q.id;

  void _mutate(VoidCallback change) {
    // A mutation after midnight belongs to the new day.
    _data.rollOver(_clock());

    Set<String> cleared() => {
      for (final q in [...todayQuests, ...weeklyQuests])
        if (q.isComplete) _rewardId(q),
    };

    final before = cleared();
    change();
    _data.workoutDone = _computeWorkoutDone();
    final newlyCleared = cleared()
        .difference(before)
        .difference(_data.rewarded);

    if (newlyCleared.isNotEmpty) {
      _data.rewarded.addAll(newlyCleared);
      _data.level += newlyCleared.length;
      levelUps.value++;
    }
    _changed();
  }

  void _changed() {
    _scheduleSave();
    notifyListeners();
  }

  // ---- Persistence ---------------------------------------------------------

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), _writeProgress);
  }

  Future<void> _writeProgress() {
    _saveTimer?.cancel();
    _saveTimer = null;
    return _store.write(StoreKeys.progress, jsonEncode(_data.toJson()));
  }

  Future<void> _saveSettings() => _store.write(
    StoreKeys.settings,
    jsonEncode({'themeMode': _themeMode.name, 'loggedIn': _loggedIn}),
  );

  /// Writes any pending change immediately (app paused / logging out).
  Future<void> flush() async {
    if (_saveTimer != null) await _writeProgress();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_saveTimer != null) unawaited(_writeProgress());
    levelUps.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Scope
// ---------------------------------------------------------------------------

/// Makes [EonState] available to the whole widget tree and rebuilds
/// dependents when it changes. No external state package needed.
class EonScope extends InheritedNotifier<EonState> {
  const EonScope({super.key, required EonState state, required super.child})
    : super(notifier: state);

  static EonState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<EonScope>();
    assert(scope != null, 'No EonScope above this widget');
    return scope!.notifier!;
  }

  static EonState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<EonScope>();
    assert(scope != null, 'No EonScope above this widget');
    return scope!.notifier!;
  }
}

extension EonContext on BuildContext {
  /// Watch the app state (rebuilds this widget on change).
  EonState get eon => EonScope.of(this);

  /// Read the app state once, e.g. inside callbacks.
  EonState get eonRead => EonScope.read(this);
}
