import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/eon_state.dart';
import '../theme/eon_theme.dart';
import '../widgets/widgets.dart';

/// "LEVEL UP — One step closer to your goal..." celebration.
///
/// Shown automatically by [MainShell] over the current tab when a quest is
/// cleared, or pushed as its own route via [LevelUpView.route].
class LevelUpView extends StatefulWidget {
  const LevelUpView({
    super.key,
    this.onDismiss,
    this.autoDismissAfter = const Duration(milliseconds: 3200),
  });

  final VoidCallback? onDismiss;

  /// Set to null to keep it on screen until tapped.
  final Duration? autoDismissAfter;

  static Route<void> route() {
    return PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder:
          (context, animation, secondaryAnimation) =>
              LevelUpView(onDismiss: () => Navigator.of(context).maybePop()),
      transitionsBuilder:
          (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
    );
  }

  @override
  State<LevelUpView> createState() => _LevelUpViewState();
}

class _LevelUpViewState extends State<LevelUpView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  late final Animation<double> _titleScale = Tween<double>(
    begin: 0.6,
    end: 1,
  ).animate(
    CurvedAnimation(
      parent: _c,
      curve: const Interval(0.2, 0.75, curve: Curves.easeOutBack),
    ),
  );

  late final Animation<double> _titleFade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.2, 0.55, curve: Curves.easeOut),
  );

  late final Animation<double> _subFade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
  );

  Timer? _timer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    final delay = widget.autoDismissAfter;
    if (delay != null) _timer = Timer(delay, _dismiss);
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    widget.onDismiss?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = context.eon.level;
    final p = context.palette;

    return Semantics(
      liveRegion: true,
      label: 'Level up. You reached level $level. Tap to continue.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismiss,
        child: SizedBox.expand(
          child: Material(
            type: MaterialType.transparency,
            child: EonBackground(
              scene: RealmVariant.levelUp,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Light burst behind the title.
                  Align(
                    alignment: const Alignment(0, 0.3),
                    child: FadeTransition(
                      opacity: _subFade,
                      child: Container(
                        width: 340,
                        height: 340,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              p.glow.withValues(alpha: 0.35),
                              p.glow.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Column(
                      children: [
                        const Spacer(flex: 6),
                        FadeTransition(
                          opacity: _titleFade,
                          child: ScaleTransition(
                            scale: _titleScale,
                            child: Text(
                              'LEVEL UP',
                              style: eonText(
                                40,
                                weight: FontWeight.w800,
                                letterSpacing: 5,
                                shadows: [
                                  ...p.textGlow(1.6),
                                  Shadow(
                                    color: p.accent.withValues(alpha: 0.9),
                                    blurRadius: 40,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FadeTransition(
                          opacity: _subFade,
                          child: Text(
                            'One step closer to your goal...',
                            style: eonText(16, color: p.textMuted),
                          ),
                        ),
                        const SizedBox(height: 18),
                        FadeTransition(
                          opacity: _subFade,
                          child: _LevelChip(level: level),
                        ),
                        const Spacer(flex: 3),
                        FadeTransition(
                          opacity: _subFade,
                          child: Text(
                            'Tap to continue',
                            style: eonText(12, color: p.textFaint),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: p.accent.withValues(alpha: p.isDark ? 0.25 : 0.12),
        border: Border.all(color: p.borderStrong),
        boxShadow: p.boxGlow(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CrownIcon(size: 20),
          const SizedBox(width: 8),
          Text(
            'LV. $level',
            style: eonText(14, weight: FontWeight.w700, letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }
}
