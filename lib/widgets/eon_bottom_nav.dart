import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/eon_theme.dart';

class EonNavItem {
  const EonNavItem(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const List<EonNavItem> kNavItems = [
  EonNavItem('Home', Icons.home_outlined, Icons.home_rounded),
  EonNavItem('Stats', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
  EonNavItem(
    'Quests',
    Icons.assignment_turned_in_outlined,
    Icons.assignment_turned_in_rounded,
  ),
  EonNavItem('Profile', Icons.person_outline_rounded, Icons.person_rounded),
];

/// Frosted bottom navigation bar with a glowing selected tile.
class EonBottomNav extends StatelessWidget {
  const EonBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = kNavItems,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<EonNavItem> items;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.background.withValues(alpha: 0.82),
            border: Border(top: BorderSide(color: p.border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _NavButton(
                        item: items[i],
                        selected: i == currentIndex,
                        onTap: () => onTap(i),
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

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final EonNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? (p.isDark ? p.text : p.accent) : p.textFaint;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color:
                selected
                    ? p.accent.withValues(alpha: p.isDark ? 0.22 : 0.12)
                    : Colors.transparent,
            border: Border.all(
              color:
                  selected
                      ? p.highlight.withValues(alpha: 0.55)
                      : Colors.transparent,
            ),
            boxShadow: selected ? p.boxGlow(strength: 0.8) : const [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? item.activeIcon : item.icon,
                size: 24,
                color: color,
                shadows: selected ? p.textGlow(0.8) : null,
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: eonText(
                  11.5,
                  color: color,
                  weight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
