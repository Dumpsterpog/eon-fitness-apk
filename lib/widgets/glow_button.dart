import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/eon_theme.dart';

/// Frosted glass button with a gradient border and a breathing glow.
/// In light mode it becomes a solid violet call-to-action for contrast.
class GlowButton extends StatefulWidget {
  const GlowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.height = 58,
    this.fontSize = 16,
    this.loading = false,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// Shown just before the label (e.g. a crown).
  final Widget? leading;

  /// Pinned to the right edge (e.g. a chevron).
  final Widget? trailing;
  final double height;
  final double fontSize;

  /// Replaces the label with a spinner and ignores taps.
  final bool loading;

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const radius = 16.0;
    final p = context.palette;
    final labelColor = p.isDark ? p.text : p.onAccent;

    final Widget label =
        widget.loading
            ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: labelColor,
              ),
            )
            : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.leading != null) ...[
                  widget.leading!,
                  const SizedBox(width: 12),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: eonText(
                      widget.fontSize,
                      weight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: labelColor,
                    ),
                  ),
                ),
              ],
            );

    final fill =
        p.isDark
            ? [
              p.surfaceTop.withValues(alpha: 0.78),
              p.surfaceBottom.withValues(alpha: 0.88),
            ]
            : [p.accent, p.accentDeep];

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => _setPressed(true) : null,
        onTapUp: _enabled ? (_) => _setPressed(false) : null,
        onTapCancel: () => _setPressed(false),
        onTap:
            _enabled
                ? () {
                  HapticFeedback.lightImpact();
                  widget.onPressed!();
                }
                : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.onPressed == null ? 0.5 : 1,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final t = _pulse.value;
                return Container(
                  width: double.infinity,
                  height: widget.height,
                  padding: const EdgeInsets.all(1.2), // gradient border width
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    gradient: LinearGradient(
                      colors: [
                        p.highlight.withValues(alpha: 0.85),
                        p.accent.withValues(alpha: 0.45),
                        p.highlight.withValues(alpha: 0.85),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: p.glow.withValues(
                          alpha: (0.22 + 0.2 * t) * (p.isDark ? 1 : 0.8),
                        ),
                        blurRadius: 16 + 12 * t,
                        offset: p.isDark ? Offset.zero : const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius - 1.2),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: fill,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: widget.trailing != null ? 28 : 0,
                            ),
                            child: label,
                          ),
                          if (widget.trailing != null && !widget.loading)
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconTheme.merge(
                                data: IconThemeData(
                                  color: p.isDark ? p.highlight : p.onAccent,
                                ),
                                child: widget.trailing!,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
