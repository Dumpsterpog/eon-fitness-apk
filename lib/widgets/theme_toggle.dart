import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/eon_state.dart';
import '../theme/eon_theme.dart';

/// Sun / moon button that flips between light and dark. The icon spins and
/// cross-fades; the whole UI then animates to the new palette.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: dark ? 'Switch to light mode' : 'Switch to dark mode',
      onPressed: () {
        HapticFeedback.selectionClick();
        context.eonRead.toggleTheme(Theme.of(context).brightness);
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        transitionBuilder:
            (child, animation) => RotationTransition(
              turns: Tween<double>(begin: 0.6, end: 1).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: FadeTransition(opacity: animation, child: child),
            ),
        child: Icon(
          dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          key: ValueKey(dark),
          size: size,
          color: dark ? p.highlight : const Color(0xFFF5A623),
          shadows: p.textGlow(0.8),
        ),
      ),
    );
  }
}

/// System / Dark / Light picker for the Profile screen.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.eon;
    final p = context.palette;
    const modes = [
      (ThemeMode.system, 'System', Icons.brightness_auto_rounded),
      (ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
      (ThemeMode.light, 'Light', Icons.light_mode_rounded),
    ];
    return Row(
      children: [
        for (final (mode, label, icon) in modes)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: mode == ThemeMode.system ? 0 : 8),
              child: Semantics(
                button: true,
                selected: s.themeMode == mode,
                label: '$label theme',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    s.setThemeMode(mode);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color:
                          s.themeMode == mode
                              ? p.accent.withValues(
                                alpha: p.isDark ? 0.3 : 0.14,
                              )
                              : p.surfaceBottom.withValues(alpha: 0.5),
                      border: Border.all(
                        color: s.themeMode == mode ? p.highlight : p.border,
                        width: s.themeMode == mode ? 1.4 : 1,
                      ),
                      boxShadow:
                          s.themeMode == mode
                              ? p.boxGlow(strength: 0.8)
                              : const [],
                    ),
                    child: Column(
                      children: [
                        Icon(icon, size: 22, color: p.highlight),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: eonText(
                            13,
                            weight:
                                s.themeMode == mode
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
