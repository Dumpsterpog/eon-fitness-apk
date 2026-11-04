import 'package:flutter/material.dart';

import '../theme/eon_theme.dart';

/// Thin glowing progress bar that animates from its previous value whenever
/// [value] changes.
class EonProgressBar extends StatelessWidget {
  const EonProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.colors,
  });

  /// 0.0 – 1.0
  final double value;
  final double height;

  /// Defaults to accent → highlight.
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fill = colors ?? [p.accent, p.highlight];
    final target = value.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: target),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return Container(
          height: height,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: p.track,
            borderRadius: BorderRadius.circular(height),
          ),
          child: FractionallySizedBox(
            widthFactor: v,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height),
                gradient: LinearGradient(colors: fill),
                boxShadow:
                    v <= 0.001
                        ? null
                        : [
                          BoxShadow(
                            color: fill.last.withValues(
                              alpha: 0.55 * p.glowStrength,
                            ),
                            blurRadius: 8,
                          ),
                        ],
              ),
            ),
          ),
        );
      },
    );
  }
}
