import 'dart:convert';

import 'package:eon_fitness/state/eon_state.dart';
import 'package:eon_fitness/state/progress.dart';
import 'package:eon_fitness/state/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  late MemoryStore store;
  EonState load() => EonState.load(store, clock: () => now);

  setUp(() {
    now = DateTime(2026, 11, 4, 10);
    store = MemoryStore();
  });

  test('sign up, persist, reload, log in', () async {
    final s = load();
    expect(s.isLoggedIn, isFalse);
    expect(
      await s.signUp(name: 'Jin', email: 'jin@hunter.gg', password: 'arise!1'),
      isNull,
    );
    expect(s.isLoggedIn, isTrue);
    expect(s.streak, 14); // demo progress
    s.addWater(250);
    await s.flush();
    s.dispose();

    final again = load();
    expect(again.isLoggedIn, isTrue);
    expect(again.userName, 'Jin');
    expect(again.waterMl, 1750);

    await again.logOut();
    expect(again.isLoggedIn, isFalse);
    expect(
      await again.logIn(email: 'jin@hunter.gg', password: 'nope'),
      isNotNull,
    );
    expect(
      await again.logIn(email: 'JIN@hunter.gg', password: 'arise!1'),
      isNull,
    );
  });

  test('clearing a quest levels up once, even if re-cleared', () async {
    final s = load();
    await s.signUp(name: 'Jin', email: 'jin@hunter.gg', password: 'arise!1');
    final start = s.level;
    var celebrations = 0;
    s.levelUps.addListener(() => celebrations++);

    s.addWater(s.waterRemainingMl); // clears the water quest
    expect(s.level, start + 1);
    s.addWater(-250); // un-clear
    s.addWater(250); // re-clear: no second reward
    expect(s.level, start + 1);
    expect(celebrations, 1);
  });

  test('a new day archives progress and resets counters', () async {
    final s = load();
    await s.signUp(name: 'Jin', email: 'jin@hunter.gg', password: 'arise!1');
    s.addSteps(500);
    now = DateTime(2026, 11, 5, 7);
    s.rollOverIfNeeded();
    expect(s.steps, 0);
    expect(s.recordFor(DateTime(2026, 11, 4))!.steps, 3300);
  });

  test('theme mode persists', () async {
    final s = load()..setThemeMode(ThemeMode.light);
    await s.flush();
    expect(jsonDecode(store.read(StoreKeys.settings)!)['themeMode'], 'light');
    expect(load().themeMode, ThemeMode.light);
  });

  test('corrupt storage never crashes startup', () {
    store = MemoryStore({
      StoreKeys.progress: '{not json',
      StoreKeys.account: '[]',
      StoreKeys.settings: 'null',
    });
    final s = load();
    expect(s.hasAccount, isFalse);
    expect(s.themeMode, ThemeMode.dark);
    expect(dayKey(now), '2026-11-04');
  });
}
