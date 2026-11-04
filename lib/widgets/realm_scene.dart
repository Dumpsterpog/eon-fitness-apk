import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/eon_theme.dart';

/// Which composition of the painted realm to draw.
enum RealmVariant {
  /// Big hooded hunter in front of the castle (Welcome / Login).
  welcome,

  /// Castle centre-left, small hunter on a ledge (Home).
  home,

  /// Hunter on a peak with a towering aura (Level Up).
  levelUp,

  /// Faint castle and moon only, behind content-heavy screens.
  ambient,
}

/// Original painted backdrop: moonlit sky, gothic castle, cliffs and a
/// cloaked hunter wreathed in a violet aura. Drawn entirely in code so it is
/// crisp at any resolution, themes with the palette, and adds nothing to the
/// APK size.
///
/// Static parts and animated parts (clouds, aura, eyes) are separate layers so
/// the animation only repaints what moves. Animation respects [TickerMode]
/// (paused on hidden tabs) and the system "remove animations" setting.
class RealmScene extends StatefulWidget {
  const RealmScene({super.key, required this.variant});

  final RealmVariant variant;

  @override
  State<RealmScene> createState() => _RealmSceneState();
}

class _RealmSceneState extends State<RealmScene>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _time = ValueNotifier<double>(1.3);
  late final Ticker _ticker = createTicker(
    (elapsed) => _time.value = 1.3 + elapsed.inMicroseconds / 1e6,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion && _ticker.isActive) _ticker.stop();
    if (!reduceMotion && !_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final spec = _VariantSpec.of(widget.variant);

    Widget layer(_Layer l, {bool animated = false}) => RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _RealmPainter(
          layer: l,
          spec: spec,
          palette: p,
          time: animated ? _time : null,
        ),
      ),
    );

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          layer(_Layer.sky),
          layer(_Layer.clouds, animated: true),
          layer(_Layer.castle),
          if (spec.figure != null) layer(_Layer.aura, animated: true),
          layer(_Layer.foreground),
          if (spec.figure != null) layer(_Layer.eyes, animated: true),
        ],
      ),
    );
  }
}

enum _Layer { sky, clouds, castle, aura, foreground, eyes }

/// Placement of each element in the 400 x 860 design space.
class _VariantSpec {
  const _VariantSpec({
    required this.moon,
    required this.moonRadius,
    required this.figure,
    required this.castleDx,
    required this.castleScale,
    required this.cliff,
    required this.aura,
    this.castleOpacity = 1,
  });

  final Offset moon;
  final double moonRadius;

  /// (x of figure centre, y of hood top, height). Null = no figure.
  final (double, double, double)? figure;
  final double castleDx;
  final double castleScale;
  final double castleOpacity;
  final List<List<double>> cliff;
  final double aura;

  static _VariantSpec of(RealmVariant v) => switch (v) {
    RealmVariant.welcome => const _VariantSpec(
      moon: Offset(290, 205),
      moonRadius: 52,
      figure: (190, 318, 470),
      castleDx: 0,
      castleScale: 1,
      cliff: _kCliffWelcome,
      aura: 1,
    ),
    RealmVariant.home => const _VariantSpec(
      moon: Offset(110, 150),
      moonRadius: 34,
      figure: (336, 488, 175),
      castleDx: -130,
      castleScale: 1.05,
      cliff: _kCliffHome,
      aura: 0.55,
    ),
    RealmVariant.levelUp => const _VariantSpec(
      moon: Offset(200, 250),
      moonRadius: 78,
      figure: (196, 318, 346),
      castleDx: 40,
      castleScale: 0.9,
      cliff: _kCliffLevelUp,
      aura: 1.4,
    ),
    RealmVariant.ambient => const _VariantSpec(
      moon: Offset(318, 128),
      moonRadius: 26,
      figure: null,
      castleDx: 30,
      castleScale: 0.85,
      castleOpacity: 0.7,
      cliff: _kCliffAmbient,
      aura: 0,
    ),
  };
}

class _RealmPainter extends CustomPainter {
  _RealmPainter({
    required this.layer,
    required this.spec,
    required this.palette,
    this.time,
  }) : super(repaint: time);

  static const double _dw = 400;
  static const double _dh = 860;

  final _Layer layer;
  final _VariantSpec spec;
  final EonPalette palette;
  final ValueListenable<double>? time;

  // Cover-fit transform, anchored bottom-centre (set per paint).
  late double _s;
  late double _ox;
  late double _oy;

  Offset _t(double x, double y) => Offset(_ox + x * _s, _oy + y * _s);

  double get _t0 => time?.value ?? 1.3;

  @override
  void paint(Canvas canvas, Size size) {
    _s = math.max(size.width / _dw, size.height / _dh);
    _ox = (size.width - _dw * _s) / 2;
    _oy = size.height - _dh * _s;

    switch (layer) {
      case _Layer.sky:
        _paintSky(canvas, size);
      case _Layer.clouds:
        _paintClouds(canvas);
      case _Layer.castle:
        _paintCastle(canvas, size);
      case _Layer.aura:
        _paintAura(canvas);
      case _Layer.foreground:
        _paintForeground(canvas);
      case _Layer.eyes:
        _paintEyes(canvas);
    }
  }

  // ---- Sky + moon ----------------------------------------------------------

  void _paintSky(Canvas canvas, Size size) {
    final p = palette;
    final full = Offset.zero & size;
    canvas.drawRect(
      full,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.skyTop, p.skyMid, p.skyHorizon, p.ridgeFar],
          stops: const [0, 0.5, 0.78, 1],
        ).createShader(full),
    );

    final m = _t(spec.moon.dx, spec.moon.dy);
    final r = spec.moonRadius * _s;
    canvas.drawRect(
      full,
      Paint()
        ..shader = RadialGradient(
          colors: [
            p.glow.withValues(alpha: 0.55 * p.glowStrength + 0.15),
            p.glow.withValues(alpha: 0.18),
            p.glow.withValues(alpha: 0),
          ],
          stops: const [0, 0.35, 1],
        ).createShader(Rect.fromCircle(center: m, radius: r * 5)),
    );
    canvas
      ..drawCircle(
        m,
        r,
        Paint()
          ..color = p.moon.withValues(alpha: 0.9)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.4),
      )
      ..drawCircle(m, r, Paint()..color = p.moon);

    if (p.isDark) {
      final crater = Paint()..color = const Color(0x59B9A8F0);
      for (final c in const [
        (-0.3, -0.2, 0.22),
        (0.25, 0.15, 0.16),
        (-0.05, 0.35, 0.12),
      ]) {
        canvas.drawCircle(m + Offset(c.$1 * r, c.$2 * r), c.$3 * r, crater);
      }
    }
  }

  // ---- Clouds (animated) ---------------------------------------------------

  void _paintClouds(Canvas canvas) {
    final p = palette;
    final paint =
        Paint()
          ..color = p.isDark ? const Color(0x593A2475) : const Color(0x80FFFFFF)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 * _s);
    final t = _t0;
    for (var i = 0; i < 5; i++) {
      final cx = ((i * 97 + t * 18 * (1 + i % 2)) % (_dw + 200)) - 100;
      final cy = 180.0 + i * 70;
      canvas.drawOval(
        Rect.fromCenter(center: _t(cx, cy), width: 180 * _s, height: 32 * _s),
        paint,
      );
    }
  }

  // ---- Far ridge, castle, mist ---------------------------------------------

  void _paintCastle(Canvas canvas, Size size) {
    final p = palette;
    canvas.drawPath(_poly(_kRidgeFar, _t), Paint()..color = p.ridgeFar);

    final sc = spec.castleScale;
    Offset ct(double x, double y) =>
        _t(x * sc + spec.castleDx + (1 - sc) * 300, y * sc + (1 - sc) * 560);

    final body =
        Paint()..color = p.ridgeMid.withValues(alpha: spec.castleOpacity);
    final castle =
        Path()..addPath(
          _poly(const [
            [200, 500],
            [420, 500],
            [420, 700],
            [200, 700],
          ], ct),
          Offset.zero,
        );
    for (final tw in _kTowers) {
      final x = tw[0], w = tw[1], top = tw[2], spire = tw[3];
      castle
        ..addPath(
          _poly([
            [x, top],
            [x + w, top],
            [x + w, 700],
            [x, 700],
          ], ct),
          Offset.zero,
        )
        ..addPath(
          _poly([
            [x - 3, top],
            [x + w / 2, top - spire],
            [x + w + 3, top],
          ], ct),
          Offset.zero,
        );
    }
    for (var x = 200.0; x < 420; x += 12) {
      castle.addPath(
        _poly([
          [x, 492],
          [x + 6, 492],
          [x + 6, 500],
          [x, 500],
        ], ct),
        Offset.zero,
      );
    }
    canvas.drawPath(castle, body);

    // Lit windows.
    final windowColor =
        p.isDark
            ? p.highlight.withValues(alpha: 0.85 * spec.castleOpacity)
            : Colors.white.withValues(alpha: 0.9 * spec.castleOpacity);
    final windowGlow =
        Paint()
          ..color = p.glow.withValues(alpha: 0.9 * spec.castleOpacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * _s);
    final windowFill = Paint()..color = windowColor;
    for (final tw in _kTowers) {
      final cx = tw[0] + tw[1] / 2;
      for (var k = 0; k < 2; k++) {
        final wy = tw[2] + 18 + k * 34;
        final rect = Rect.fromPoints(ct(cx - 2, wy), ct(cx + 2, wy + 8));
        canvas
          ..drawRect(rect, windowGlow)
          ..drawRect(rect, windowFill);
      }
    }

    // Mist settling between the castle and the cliffs.
    final top = _t(0, 560).dy;
    final bottom = _t(0, 720).dy;
    final mist = Rect.fromLTRB(0, top, size.width, bottom);
    canvas.drawRect(
      mist,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            p.skyHorizon.withValues(alpha: 0),
            p.skyHorizon.withValues(alpha: p.isDark ? 0.35 : 0.6),
          ],
        ).createShader(mist),
    );
  }

  // ---- Aura (animated) -----------------------------------------------------

  void _paintAura(Canvas canvas) {
    final fig = spec.figure;
    if (fig == null || spec.aura <= 0) return;
    final p = palette;
    final k = spec.aura;
    final f = _t(fig.$1, fig.$2);
    final fx = f.dx, fy = f.dy, fh = fig.$3 * _s;
    final strength = p.isDark ? 1.0 : 0.75;
    final blend = p.isDark ? BlendMode.plus : BlendMode.srcOver;
    final t = _t0;

    // Halo behind the upper body.
    final halo = Offset(fx, fy + fh * 0.42);
    final haloR = fh * 0.75 * k;
    canvas.drawCircle(
      halo,
      haloR,
      Paint()
        ..blendMode = blend
        ..shader = RadialGradient(
          colors: [
            p.glow.withValues(alpha: 0.42 * strength),
            p.accent.withValues(alpha: 0.16 * strength),
            p.glow.withValues(alpha: 0),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(Rect.fromCircle(center: halo, radius: haloR)),
    );

    // Glow pooling at the feet.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(fx + fh * 0.04, fy + fh * 0.995),
        width: fh * 0.64 * k,
        height: fh * 0.07,
      ),
      Paint()
        ..blendMode = blend
        ..color = p.glow.withValues(alpha: 0.55 * strength)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, fh * 0.03),
    );

    // Wisps curling off both sides of the silhouette.
    final wispBlur = MaskFilter.blur(
      BlurStyle.normal,
      math.max(1.5, fh * 0.008),
    );
    const n = 14;
    for (var i = 0; i < n; i++) {
      final side = i.isEven ? -1.0 : 1.0;
      final j = (i ~/ 2) / (n / 2 - 1);
      final phase = i * 2.3 + t * (1.6 + (i % 4) * 0.35);
      final life = (t * 0.35 + i * 0.137) % 1;
      final baseY = fy + fh * (0.32 + j * 0.62);
      final baseX =
          fx +
          side * fh * (0.15 + j * 0.06) +
          (side > 0 ? j * j * fh * 0.12 : 0);
      final len =
          fh * (0.28 + 0.22 * (1 - j)) * k * (0.75 + 0.25 * math.sin(phase));
      final out = side * fh * (0.06 + 0.1 * j) * k;
      final tipX = baseX + out + math.sin(phase) * fh * 0.03;
      final tipY = baseY - len;
      final w = fh * (0.03 + 0.02 * (1 - j));
      final alpha = (0.35 + 0.65 * math.sin(life * math.pi)) * strength;

      final path =
          Path()
            ..moveTo(baseX - w * side * 0.2, baseY + w)
            ..cubicTo(
              baseX + out * 0.2,
              baseY - len * 0.35,
              tipX - out * 0.6 - side * w,
              tipY + len * 0.45,
              tipX,
              tipY,
            )
            ..cubicTo(
              tipX - out * 0.3 + side * w * 1.2,
              tipY + len * 0.5,
              baseX + out * 0.9 + side * w,
              baseY - len * 0.25,
              baseX + side * w * 1.6,
              baseY + w * 0.5,
            )
            ..close();

      canvas.drawPath(
        path,
        Paint()
          ..blendMode = blend
          ..maskFilter = wispBlur
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              p.accent.withValues(alpha: (0.7 * alpha).clamp(0.0, 1.0)),
              p.glow.withValues(alpha: (0.35 * alpha).clamp(0.0, 1.0)),
              p.glow.withValues(alpha: 0),
            ],
            stops: const [0, 0.55, 1],
          ).createShader(Rect.fromLTRB(baseX - fh, tipY, baseX + fh, baseY)),
      );
    }
  }

  // ---- Cliff + hunter ------------------------------------------------------

  Color get _figureColor =>
      palette.isDark
          ? palette.ridgeNear
          : Color.lerp(palette.ridgeNear, palette.text, 0.45)!;

  void _paintForeground(Canvas canvas) {
    final p = palette;
    canvas.drawPath(_poly(spec.cliff, _t), Paint()..color = p.ridgeNear);

    final fig = spec.figure;
    if (fig == null) return;
    final f = _t(fig.$1, fig.$2);
    final fh = fig.$3 * _s;
    Offset ft(double x, double y) => Offset(f.dx + x * fh, f.dy + y * fh);

    final body = _cmds(_kFigure, ft);

    // Rim light bloom, then the solid silhouette on top.
    canvas
      ..drawPath(
        body,
        Paint()
          ..color = p.glow.withValues(alpha: 0.9 * p.glowStrength + 0.1)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, fh * 0.025),
      )
      ..drawPath(body, Paint()..color = _figureColor)
      ..drawPath(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, fh * 0.006)
          ..color = (p.isDark ? p.highlight : Colors.white).withValues(
            alpha: 0.55,
          ),
      );

    // Moonlight catching the right side of the coat, and the coat seams.
    canvas
      ..save()
      ..clipPath(body);
    final shade = Rect.fromLTRB(
      f.dx - fh * 0.3,
      f.dy,
      f.dx + fh * 0.5,
      f.dy + fh,
    );
    canvas
      ..drawRect(
        shade,
        Paint()
          ..shader = LinearGradient(
            colors: [
              p.accent.withValues(alpha: 0),
              p.accent.withValues(alpha: 0.18),
            ],
          ).createShader(shade),
      )
      ..drawPath(
        _cmds(_kCoatSeam, ft),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = fh * 0.004
          ..color = p.glow.withValues(alpha: 0.25),
      )
      ..restore();

    // Shadowed face inside the hood.
    canvas.drawPath(
      _cmds(_kHoodFace, ft),
      Paint()..color = const Color(0xFF030107),
    );
  }

  // ---- Eyes (animated flicker) ---------------------------------------------

  void _paintEyes(Canvas canvas) {
    final fig = spec.figure;
    if (fig == null) return;
    final f = _t(fig.$1, fig.$2);
    final fh = fig.$3 * _s;
    final flicker = 0.75 + 0.25 * math.sin(_t0 * 3.1);
    final glow =
        Paint()
          ..color = (palette.isDark ? const Color(0xFFB48CFF) : palette.glow)
              .withValues(alpha: flicker)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, fh * 0.015);
    final core =
        Paint()..color = const Color(0xFFE6D9FF).withValues(alpha: flicker);
    for (final ex in const [-0.019, 0.019]) {
      final eye = Rect.fromCenter(
        center: Offset(f.dx + ex * fh, f.dy + 0.1 * fh),
        width: fh * 0.017,
        height: fh * 0.0084,
      );
      canvas
        ..drawOval(eye.inflate(fh * 0.004), glow)
        ..drawOval(eye, core);
    }
  }

  // ---- Path helpers --------------------------------------------------------

  static Path _poly(
    List<List<double>> pts,
    Offset Function(double, double) tx,
  ) {
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final o = tx(pts[i][0], pts[i][1]);
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    return path..close();
  }

  /// Interprets [cmds]: [0,x,y] moveTo, [1,x,y] lineTo,
  /// [2,x1,y1,x2,y2,x,y] cubicTo, [3] close.
  static Path _cmds(
    List<List<double>> cmds,
    Offset Function(double, double) tx,
  ) {
    final path = Path();
    for (final c in cmds) {
      switch (c[0].toInt()) {
        case 0:
          final o = tx(c[1], c[2]);
          path.moveTo(o.dx, o.dy);
        case 1:
          final o = tx(c[1], c[2]);
          path.lineTo(o.dx, o.dy);
        case 2:
          final a = tx(c[1], c[2]);
          final b = tx(c[3], c[4]);
          final d = tx(c[5], c[6]);
          path.cubicTo(a.dx, a.dy, b.dx, b.dy, d.dx, d.dy);
        default:
          path.close();
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _RealmPainter old) =>
      old.palette != palette || old.spec != spec || old.layer != layer;
}

/// Static hunter silhouette with a soft aura, for cards and banners.
/// Fits the box height; the figure is anchored to the bottom centre.
class HunterFigure extends StatelessWidget {
  const HunterFigure({super.key, this.aura = 1});

  /// 0 = no halo.
  final double aura;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _HunterFigurePainter(palette: context.palette, aura: aura),
    );
  }
}

class _HunterFigurePainter extends CustomPainter {
  _HunterFigurePainter({required this.palette, required this.aura});

  final EonPalette palette;
  final double aura;

  @override
  void paint(Canvas canvas, Size size) {
    final p = palette;
    // Figure spans x in [-0.17, 0.36] of its height; fit the box.
    final fh = math.min(size.height * 0.94, size.width / 0.6);
    final origin = Offset(size.width / 2 - fh * 0.08, size.height - fh);
    Offset ft(double x, double y) =>
        Offset(origin.dx + x * fh, origin.dy + y * fh);

    if (aura > 0) {
      final halo = ft(0.02, 0.4);
      canvas.drawCircle(
        halo,
        fh * 0.6 * aura,
        Paint()
          ..shader = RadialGradient(
            colors: [
              p.glow.withValues(alpha: 0.5 * (p.isDark ? 1 : 0.6)),
              p.glow.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(center: halo, radius: fh * 0.6 * aura),
          ),
      );
    }

    final body = _RealmPainter._cmds(_kFigure, ft);
    final fill =
        p.isDark ? p.ridgeNear : Color.lerp(p.ridgeNear, p.text, 0.45)!;
    canvas
      ..drawPath(
        body,
        Paint()
          ..color = p.glow.withValues(alpha: 0.9 * p.glowStrength + 0.1)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, fh * 0.03),
      )
      ..drawPath(body, Paint()..color = fill)
      ..drawPath(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, fh * 0.008)
          ..color = (p.isDark ? p.highlight : Colors.white).withValues(
            alpha: 0.6,
          ),
      )
      ..drawPath(
        _RealmPainter._cmds(_kHoodFace, ft),
        Paint()..color = const Color(0xFF030107),
      );

    final eye =
        Paint()
          ..color = const Color(0xFFE6D9FF)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            math.max(0.5, fh * 0.004),
          );
    for (final ex in const [-0.019, 0.019]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: ft(ex, 0.1),
          width: fh * 0.02,
          height: fh * 0.01,
        ),
        eye,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HunterFigurePainter old) =>
      old.palette != palette || old.aura != aura;
}

// ---------------------------------------------------------------------------
// Geometry (400 x 860 design space; figure in unit space, hood top = 0,
// feet = 1). Generated from the canvas prototype used to design the art.
// ---------------------------------------------------------------------------

const List<List<double>> _kCliffAmbient = [
  [0.0, 760.0],
  [100.0, 750.0],
  [200.0, 765.0],
  [300.0, 745.0],
  [400.0, 760.0],
  [400.0, 860.0],
  [0.0, 860.0],
];

const List<List<double>> _kFigure = [
  [0.0, 0.0, 0.0],
  [2.0, 0.05, 0.0, 0.082, 0.035, 0.085, 0.085],
  [2.0, 0.088, 0.12, 0.08, 0.15, 0.09, 0.17],
  [2.0, 0.12, 0.18, 0.15, 0.195, 0.162, 0.23],
  [2.0, 0.172, 0.26, 0.168, 0.3, 0.17, 0.34],
  [2.0, 0.172, 0.44, 0.18, 0.55, 0.21, 0.66],
  [2.0, 0.24, 0.74, 0.29, 0.8, 0.36, 0.86],
  [1.0, 0.29, 0.865],
  [1.0, 0.25, 0.895],
  [1.0, 0.2, 0.875],
  [1.0, 0.15, 0.905],
  [1.0, 0.11, 0.89],
  [1.0, 0.085, 0.88],
  [1.0, 0.078, 1.0],
  [1.0, 0.018, 1.0],
  [1.0, 0.012, 0.9],
  [1.0, -0.012, 0.9],
  [1.0, -0.018, 1.0],
  [1.0, -0.078, 1.0],
  [1.0, -0.085, 0.88],
  [1.0, -0.12, 0.895],
  [1.0, -0.16, 0.875],
  [2.0, -0.17, 0.76, -0.17, 0.6, -0.16, 0.45],
  [2.0, -0.158, 0.38, -0.165, 0.3, -0.162, 0.23],
  [2.0, -0.15, 0.195, -0.12, 0.18, -0.09, 0.17],
  [2.0, -0.08, 0.15, -0.088, 0.12, -0.085, 0.085],
  [2.0, -0.082, 0.035, -0.05, 0.0, 0.0, 0.0],
  [3.0],
];

const List<List<double>> _kCoatSeam = [
  [0.0, -0.035, 0.2],
  [2.0, -0.03, 0.45, -0.04, 0.7, -0.02, 0.89],
  [0.0, 0.035, 0.2],
  [2.0, 0.03, 0.45, 0.05, 0.7, 0.07, 0.885],
];

const List<List<double>> _kHoodFace = [
  [0.0, 0.0, 0.042],
  [2.0, 0.038, 0.042, 0.056, 0.072, 0.053, 0.104],
  [2.0, 0.05, 0.136, 0.026, 0.152, 0.0, 0.152],
  [2.0, -0.026, 0.152, -0.05, 0.136, -0.053, 0.104],
  [2.0, -0.056, 0.072, -0.038, 0.042, 0.0, 0.042],
  [3.0],
];

const List<List<double>> _kTowers = [
  [212.0, 22.0, 470.0, 46.0],
  [236.0, 30.0, 415.0, 70.0],
  [268.0, 20.0, 450.0, 40.0],
  [290.0, 36.0, 330.0, 110.0],
  [330.0, 24.0, 400.0, 64.0],
  [356.0, 30.0, 365.0, 82.0],
  [388.0, 22.0, 440.0, 44.0],
];

const List<List<double>> _kRidgeFar = [
  [0.0, 560.0],
  [30.0, 540.0],
  [62.0, 552.0],
  [95.0, 520.0],
  [128.0, 536.0],
  [160.0, 500.0],
  [190.0, 522.0],
  [222.0, 505.0],
  [255.0, 530.0],
  [290.0, 512.0],
  [325.0, 540.0],
  [360.0, 520.0],
  [400.0, 545.0],
  [400.0, 860.0],
  [0.0, 860.0],
];

const List<List<double>> _kCliffWelcome = [
  [0.0, 700.0],
  [60.0, 690.0],
  [120.0, 705.0],
  [170.0, 780.0],
  [230.0, 775.0],
  [280.0, 700.0],
  [340.0, 690.0],
  [400.0, 705.0],
  [400.0, 860.0],
  [0.0, 860.0],
];

const List<List<double>> _kCliffHome = [
  [0.0, 690.0],
  [70.0, 700.0],
  [150.0, 690.0],
  [230.0, 700.0],
  [290.0, 670.0],
  [315.0, 660.0],
  [372.0, 662.0],
  [400.0, 650.0],
  [400.0, 860.0],
  [0.0, 860.0],
];

const List<List<double>> _kCliffLevelUp = [
  [0.0, 720.0],
  [60.0, 705.0],
  [120.0, 700.0],
  [160.0, 668.0],
  [185.0, 662.0],
  [218.0, 662.0],
  [245.0, 672.0],
  [290.0, 705.0],
  [340.0, 712.0],
  [400.0, 700.0],
  [400.0, 860.0],
  [0.0, 860.0],
];
