import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/eon_theme.dart';
import 'realm_scene.dart';

/// Backdrop used behind every screen: the painted realm, a readability scrim
/// in the palette's background colour, violet edge smoke and floating embers.
class EonBackground extends StatelessWidget {
  const EonBackground({
    super.key,
    required this.child,
    this.scene = RealmVariant.ambient,
    this.embers = true,
    this.scrim = true,
    this.scrimStrength = 1,
  });

  final Widget child;
  final RealmVariant scene;
  final bool embers;
  final bool scrim;

  /// 0..1, scales how much the scrim darkens (or, in light mode, lightens)
  /// the scene behind content.
  final double scrimStrength;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = scrimStrength.clamp(0.0, 1.0);
    Color sc(double a) => p.scrim.withValues(alpha: (a * s).clamp(0.0, 1.0));

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: p.background),
        RealmScene(variant: scene),
        if (scrim)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.3, 0.7, 1.0],
                colors:
                    scene == RealmVariant.ambient
                        ? [sc(0.75), sc(0.55), sc(0.6), sc(0.92)]
                        : [sc(0.6), sc(0.13), sc(0.27), sc(0.9)],
              ),
            ),
          ),
        // Violet smoke along the edges.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.05,
              colors: [
                Colors.transparent,
                Colors.transparent,
                p.accentDeep.withValues(alpha: 0.33 * p.glowStrength),
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
        ),
        if (embers)
          const IgnorePointer(child: RepaintBoundary(child: EmberField())),
        child,
      ],
    );
  }
}

/// Slowly rising violet embers. Self-animating; pauses with [TickerMode].
class EmberField extends StatefulWidget {
  const EmberField({super.key, this.count = 24});

  final int count;

  @override
  State<EmberField> createState() => _EmberFieldState();
}

class _EmberFieldState extends State<EmberField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  late final List<_Ember> _embers = List.generate(
    widget.count,
    (i) => _Ember.random(math.Random(i * 7919 + 1)),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CustomPaint(
      painter: _EmberPainter(
        animation: _controller,
        embers: _embers,
        color: p.glow,
        strength: p.isDark ? 1 : 0.7,
      ),
      size: Size.infinite,
    );
  }
}

class _Ember {
  _Ember.random(math.Random r)
    : x = r.nextDouble(),
      offset = r.nextDouble(),
      speed = 1 + r.nextInt(2),
      wobble = 0.5 + r.nextDouble() * 1.5,
      radius = 1.0 + r.nextDouble() * 2.2,
      brightness = 0.4 + r.nextDouble() * 0.6;

  final double x;
  final double offset;
  final int speed; // integer so the loop is seamless
  final double wobble;
  final double radius;
  final double brightness;
}

class _EmberPainter extends CustomPainter {
  _EmberPainter({
    required this.animation,
    required this.embers,
    required this.color,
    required this.strength,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final List<_Ember> embers;
  final Color color;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    for (final e in embers) {
      final progress = (t * e.speed + e.offset) % 1.0;
      final fade = math.sin(progress * math.pi);
      if (fade <= 0.01) continue;

      final y = size.height * (1.02 - progress * 0.85);
      final x =
          size.width * e.x + math.sin(progress * math.pi * 2 * e.wobble) * 14;

      final paint =
          Paint()
            ..color = color.withValues(
              alpha: (0.6 * fade * e.brightness * strength).clamp(0.0, 1.0),
            )
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, e.radius);

      canvas.drawCircle(Offset(x, y), e.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EmberPainter old) =>
      old.embers != embers || old.color != color || old.strength != strength;
}
