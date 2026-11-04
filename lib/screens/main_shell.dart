import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/eon_state.dart';
import '../theme/eon_theme.dart';
import '../widgets/widgets.dart';
import 'home_screen.dart';
import 'level_up_view.dart';
import 'profile_screen.dart';
import 'quests_screen.dart';
import 'stats_screen.dart';

/// Bottom-nav shell: Home · Stats · Quests · Profile.
/// Also plays the Level Up animation whenever a quest is cleared.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  /// Lets any screen inside the shell switch tabs.
  static MainShellState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<MainShellState>();

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;
  bool _showLevelUp = false;
  EonState? _state;
  ModalRoute<dynamic>? _route;

  static const List<Widget> _pages = [
    HomeScreen(),
    StatsScreen(),
    QuestsScreen(),
    ProfileScreen(),
  ];

  void goToTab(int index) {
    setState(() {
      _index = index;
      _showLevelUp = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    final state = EonScope.read(context);
    if (!identical(state, _state)) {
      _state?.levelUps.removeListener(_onLevelUp);
      _state = state..levelUps.addListener(_onLevelUp);
    }
  }

  void _onLevelUp() {
    if (!mounted) return;
    final route = _route;
    if (route != null && !route.isCurrent) {
      // Another screen (e.g. Water Intake) is on top: celebrate there.
      Navigator.of(context).push(LevelUpView.route());
      return;
    }
    setState(() => _showLevelUp = true);
  }

  void _hideLevelUp() {
    if (mounted && _showLevelUp) setState(() => _showLevelUp = false);
  }

  @override
  void dispose() {
    _state?.levelUps.removeListener(_onLevelUp);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: p.overlayStyle,
      child: Scaffold(
        backgroundColor: p.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            IndexedStack(
              index: _index,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  TickerMode(enabled: i == _index, child: _pages[i]),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              child:
                  _showLevelUp
                      ? LevelUpView(
                        key: ValueKey(_state?.levelUps.value),
                        onDismiss: _hideLevelUp,
                      )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
        bottomNavigationBar: EonBottomNav(currentIndex: _index, onTap: goToTab),
      ),
    );
  }
}
