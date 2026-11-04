import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/main_shell.dart';
import 'screens/welcome_screen.dart';
import 'state/eon_state.dart';
import 'state/prefs_store.dart';
import 'theme/eon_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final store = await PrefsStore.open();
  runApp(EonApp(state: EonState.load(store)));
}

class EonApp extends StatefulWidget {
  const EonApp({super.key, required this.state});

  final EonState state;

  @override
  State<EonApp> createState() => _EonAppState();
}

class _EonAppState extends State<EonApp> {
  late ThemeMode _themeMode = widget.state.themeMode;

  // Decided once: returning hunters skip the welcome screen.
  late final Widget _home =
      widget.state.isLoggedIn ? const MainShell() : const WelcomeScreen();

  late final AppLifecycleListener _lifecycle;

  static final _darkTheme = EonTheme.build(EonPalette.dark);
  static final _lightTheme = EonTheme.build(EonPalette.light);

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChanged);
    // Save when the app leaves the foreground; start a new day on return.
    _lifecycle = AppLifecycleListener(
      onResume: widget.state.rollOverIfNeeded,
      onInactive: _flush,
      onHide: _flush,
      onPause: _flush,
      onDetach: _flush,
    );
  }

  void _flush() => unawaited(widget.state.flush());

  /// Only rebuild MaterialApp when the theme mode actually changes, not on
  /// every glass of water.
  void _onStateChanged() {
    if (widget.state.themeMode != _themeMode) {
      setState(() => _themeMode = widget.state.themeMode);
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    widget.state.removeListener(_onStateChanged);
    widget.state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EonScope(
      state: widget.state,
      child: MaterialApp(
        title: 'Eon Fitness',
        debugShowCheckedModeBanner: false,
        theme: _lightTheme,
        darkTheme: _darkTheme,
        themeMode: _themeMode,
        themeAnimationDuration: const Duration(milliseconds: 450),
        themeAnimationCurve: Curves.easeInOutCubic,
        home: _home,
      ),
    );
  }
}
