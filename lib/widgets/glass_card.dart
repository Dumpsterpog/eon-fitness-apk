import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/eon_theme.dart';

/// Translucent card with a thin glowing border.
///
/// [beveled] gives the cut-corner "system window" look used on the Stats
/// screen; otherwise corners are rounded. [blur] adds a frosted backdrop
/// (use sparingly inside long lists).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 18,
    this.beveled = false,
    this.highlight = false,
    this.blur = false,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final bool beveled;
  final bool highlight;
  final bool blur;
  final Gradient? gradient;

  ShapeBorder _shape(EonPalette p) {
    final side = BorderSide(
      color: highlight ? p.borderStrong : p.border,
      width: highlight ? 1.4 : 1,
    );
    return beveled
        ? BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(radius * 0.6),
          side: side,
        )
        : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: side,
        );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shape = _shape(p);

    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = InkWell(
        customBorder: shape,
        onTap: onTap,
        splashColor: p.glow.withValues(alpha: 0.18),
        highlightColor: p.glow.withValues(alpha: 0.08),
        child: content,
      );
    }

    Widget card = DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        gradient:
            gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [p.cardTop, p.cardBottom],
            ),
      ),
      child: Material(type: MaterialType.transparency, child: content),
    );

    if (blur) {
      card = ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: card,
        ),
      );
    }

    // Light mode always gets a soft lift so white cards separate from the
    // pale background; dark mode only glows when highlighted.
    final shadows =
        highlight
            ? p.boxGlow()
            : p.isDark
            ? null
            : [
              BoxShadow(
                color: p.accentDeep.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ];
    if (shadows != null) {
      card = DecoratedBox(
        decoration: ShapeDecoration(shape: shape, shadows: shadows),
        child: card,
      );
    }

    return card;
  }
}

/// Glowing circle that holds an icon (quest icons, exercise icons...).
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.size = 44,
    this.color,
    this.filled = false,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = color ?? p.highlight;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors:
              filled
                  ? [p.accent, p.accentDeep]
                  : [
                    p.surfaceTop.withValues(alpha: p.isDark ? 0.2 : 0.9),
                    p.surfaceBottom.withValues(alpha: 0.6),
                  ],
        ),
        border: Border.all(color: c.withValues(alpha: 0.7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: p.glow.withValues(
              alpha: (filled ? 0.6 : 0.3) * p.glowStrength,
            ),
            blurRadius: filled ? 16 : 10,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: filled ? p.onAccent : c,
        shadows: p.textGlow(0.8),
      ),
    );
  }
}
