import 'package:eon_fitness/main.dart';
import 'package:eon_fitness/state/eon_state.dart';
import 'package:eon_fitness/state/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('welcome screen renders and theme toggles', (tester) async {
    final state = EonState.load(MemoryStore());
    await tester.pumpWidget(EonApp(state: state));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Eon'), findsOneWidget);
    expect(find.text('Login / Sign Up'), findsOneWidget);
    expect(state.themeMode, ThemeMode.dark);

    await tester.tap(find.byTooltip('Switch to light mode'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(state.themeMode, ThemeMode.light);
  });
}
