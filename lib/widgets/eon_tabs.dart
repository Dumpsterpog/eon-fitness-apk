import 'package:flutter/material.dart';

import '../theme/eon_theme.dart';

/// Row of selectable tabs. [beveled] = cut corners (Stats screen),
/// otherwise rounded pills (Quests screen).
class EonTabs extends StatelessWidget {
  const EonTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.beveled = false,
    this.height = 44,
    this.fontSize = 15,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final bool beveled;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 10),
              child: _Tab(
                label: labels[i],
                selected: i == index,
                beveled: beveled,
                height: height,
                fontSize: fontSize,
                onTap: () => onChanged(i),
              ),
            ),
          ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.beveled,
    required this.height,
    required this.fontSize,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool beveled;
  final double height;
  final double fontSize;
  final VoidCallback onTap;

  ShapeBorder _shape(BorderSide side) =>
      beveled
          ? BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: side,
          )
          : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: side,
          );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final decoration = ShapeDecoration(
      shape: _shape(
        BorderSide(
          color: selected ? p.highlight : p.border,
          width: selected ? 1.6 : 1,
        ),
      ),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors:
            selected
                ? (p.isDark
                    ? [
                      p.accent.withValues(alpha: 0.45),
                      p.surfaceBottom.withValues(alpha: 0.9),
                    ]
                    : [p.accent, p.accentDeep])
                : [
                  p.surfaceTop.withValues(alpha: p.isDark ? 0.35 : 0.85),
                  p.surfaceBottom.withValues(alpha: p.isDark ? 0.6 : 0.85),
                ],
      ),
      shadows: selected ? p.boxGlow(strength: 1.1) : const [],
    );

    final textColor = selected ? (p.isDark ? p.text : p.onAccent) : p.highlight;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          height: height,
          alignment: Alignment.center,
          decoration: decoration,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: eonText(
              fontSize,
              weight: selected ? FontWeight.w600 : FontWeight.w500,
              color: textColor,
              shadows: selected && p.isDark ? p.textGlow(0.7) : null,
            ),
            child: Text(label, maxLines: 1),
          ),
        ),
      ),
    );
  }
}
