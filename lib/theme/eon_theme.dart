import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bundled font families (see pubspec.yaml). Shipping the fonts in the APK
/// keeps the app fully offline and avoids a first-launch font swap.
abstract final class EonFonts {
  static const body = 'Inter';
  static const display = 'CinzelDecorative';
}

/// Every colour the UI uses, for one brightness.
///
/// Registered as a [ThemeExtension] so that switching between dark and light
/// animates: [MaterialApp] lerps the whole [ThemeData] (including this) over
/// `themeAnimationDuration`, and every widget/painter that reads the palette
/// from the theme repaints with the in-between colours.
@immutable
class EonPalette extends ThemeExtension<EonPalette> {
  const EonPalette({
    required this.brightness,
    required this.background,
    required this.backgroundAlt,
    required this.surfaceTop,
    required this.surfaceBottom,
    required this.cardTop,
    required this.cardBottom,
    required this.accent,
    required this.accentDeep,
    required this.glow,
    required this.highlight,
    required this.water,
    required this.waterDeep,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.onAccent,
    required this.border,
    required this.borderStrong,
    required this.track,
    required this.scrim,
    required this.skyTop,
    required this.skyMid,
    required this.skyHorizon,
    required this.ridgeFar,
    required this.ridgeMid,
    required this.ridgeNear,
    required this.moon,
    required this.glowStrength,
  });

  final Brightness brightness;

  // Surfaces
  final Color background;
  final Color backgroundAlt;
  final Color surfaceTop;
  final Color surfaceBottom;
  final Color cardTop;
  final Color cardBottom;

  // Brand
  final Color accent; // primary violet
  final Color accentDeep; // darker violet for gradients
  final Color glow; // light used for bloom / shadows
  final Color highlight; // icons, active borders ("lavender" in dark mode)
  final Color water;
  final Color waterDeep;

  // Text
  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color onAccent; // text/icons on a filled accent surface

  // Lines
  final Color border;
  final Color borderStrong;
  final Color track; // empty part of progress bars / rings

  /// Colour the scenery fades into behind content (top/bottom scrims).
  final Color scrim;

  // Painted scenery
  final Color skyTop;
  final Color skyMid;
  final Color skyHorizon;
  final Color ridgeFar;
  final Color ridgeMid;
  final Color ridgeNear;
  final Color moon;

  /// Multiplier for every glow/bloom. Light mode keeps glows subtle so the UI
  /// doesn't look smudged on a bright background.
  final double glowStrength;

  bool get isDark => brightness == Brightness.dark;

  static const dark = EonPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0A0614),
    backgroundAlt: Color(0xFF140A2C),
    surfaceTop: Color(0xFF2A1A52),
    surfaceBottom: Color(0xFF120A26),
    cardTop: Color(0xCC231546),
    cardBottom: Color(0xB3120A26),
    accent: Color(0xFF7B4DFF),
    accentDeep: Color(0xFF3A1F86),
    glow: Color(0xFF9C6BFF),
    highlight: Color(0xFFD4C4FF),
    water: Color(0xFF8EC5FF),
    waterDeep: Color(0xFF4E63E6),
    text: Color(0xFFFFFFFF),
    textMuted: Color(0xFFC2B8E0),
    textFaint: Color(0xFF8F84B3),
    onAccent: Color(0xFFFFFFFF),
    border: Color(0x55A98BFF),
    borderStrong: Color(0xB3D4C4FF),
    track: Color(0x17FFFFFF),
    scrim: Color(0xFF0A0614),
    skyTop: Color(0xFF07040F),
    skyMid: Color(0xFF1B0F3D),
    skyHorizon: Color(0xFF4A2A9C),
    ridgeFar: Color(0xFF231543),
    ridgeMid: Color(0xFF150C2C),
    ridgeNear: Color(0xFF07040E),
    moon: Color(0xFFE9E0FF),
    glowStrength: 1,
  );

  static const light = EonPalette(
    brightness: Brightness.light,
    background: Color(0xFFF4F0FF),
    backgroundAlt: Color(0xFFE9E1FF),
    surfaceTop: Color(0xFFFFFFFF),
    surfaceBottom: Color(0xFFEDE6FF),
    cardTop: Color(0xEBFFFFFF),
    cardBottom: Color(0xD9F1EBFF),
    accent: Color(0xFF6B3CF5),
    accentDeep: Color(0xFF4521B8),
    glow: Color(0xFF8B63FF),
    highlight: Color(0xFF5A2FD9),
    water: Color(0xFF2E7FE6),
    waterDeep: Color(0xFF3C4FD6),
    text: Color(0xFF1A1033),
    textMuted: Color(0xFF574C7D),
    textFaint: Color(0xFF8A80A8),
    onAccent: Color(0xFFFFFFFF),
    border: Color(0x4D6B3CF5),
    borderStrong: Color(0xA66B3CF5),
    track: Color(0x1A3B2A80),
    scrim: Color(0xFFF4F0FF),
    skyTop: Color(0xFFB9A3FF),
    skyMid: Color(0xFFE3D6FF),
    skyHorizon: Color(0xFFFFE6F1),
    ridgeFar: Color(0xFFC3B3EE),
    ridgeMid: Color(0xFF9E89DA),
    ridgeNear: Color(0xFF5B479C),
    moon: Color(0xFFFFFFFF),
    glowStrength: 0.5,
  );

  /// Soft violet bloom for boxes.
  List<BoxShadow> boxGlow({double strength = 1}) {
    final s = strength * glowStrength;
    return [
      BoxShadow(
        color: glow.withValues(alpha: (0.35 * s).clamp(0.0, 1.0)),
        blurRadius: 18 * strength,
        spreadRadius: -2,
      ),
    ];
  }

  /// Soft violet bloom for text and icons.
  List<Shadow> textGlow([double strength = 1]) {
    final s = strength * glowStrength;
    return [
      Shadow(
        color: glow.withValues(alpha: (0.85 * s).clamp(0.0, 1.0)),
        blurRadius: 12 * strength,
      ),
    ];
  }

  /// System bar icon colours that stay readable on this palette.
  SystemUiOverlayStyle get overlayStyle =>
      (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: background,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          );

  @override
  EonPalette copyWith({Color? accent, Color? highlight}) => EonPalette(
    brightness: brightness,
    background: background,
    backgroundAlt: backgroundAlt,
    surfaceTop: surfaceTop,
    surfaceBottom: surfaceBottom,
    cardTop: cardTop,
    cardBottom: cardBottom,
    accent: accent ?? this.accent,
    accentDeep: accentDeep,
    glow: glow,
    highlight: highlight ?? this.highlight,
    water: water,
    waterDeep: waterDeep,
    text: text,
    textMuted: textMuted,
    textFaint: textFaint,
    onAccent: onAccent,
    border: border,
    borderStrong: borderStrong,
    track: track,
    scrim: scrim,
    skyTop: skyTop,
    skyMid: skyMid,
    skyHorizon: skyHorizon,
    ridgeFar: ridgeFar,
    ridgeMid: ridgeMid,
    ridgeNear: ridgeNear,
    moon: moon,
    glowStrength: glowStrength,
  );

  @override
  EonPalette lerp(covariant EonPalette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return EonPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: c(background, other.background),
      backgroundAlt: c(backgroundAlt, other.backgroundAlt),
      surfaceTop: c(surfaceTop, other.surfaceTop),
      surfaceBottom: c(surfaceBottom, other.surfaceBottom),
      cardTop: c(cardTop, other.cardTop),
      cardBottom: c(cardBottom, other.cardBottom),
      accent: c(accent, other.accent),
      accentDeep: c(accentDeep, other.accentDeep),
      glow: c(glow, other.glow),
      highlight: c(highlight, other.highlight),
      water: c(water, other.water),
      waterDeep: c(waterDeep, other.waterDeep),
      text: c(text, other.text),
      textMuted: c(textMuted, other.textMuted),
      textFaint: c(textFaint, other.textFaint),
      onAccent: c(onAccent, other.onAccent),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      track: c(track, other.track),
      scrim: c(scrim, other.scrim),
      skyTop: c(skyTop, other.skyTop),
      skyMid: c(skyMid, other.skyMid),
      skyHorizon: c(skyHorizon, other.skyHorizon),
      ridgeFar: c(ridgeFar, other.ridgeFar),
      ridgeMid: c(ridgeMid, other.ridgeMid),
      ridgeNear: c(ridgeNear, other.ridgeNear),
      moon: c(moon, other.moon),
      glowStrength: glowStrength + (other.glowStrength - glowStrength) * t,
    );
  }
}

extension EonPaletteContext on BuildContext {
  /// The active Eon palette (dark or light, or a blend mid-animation).
  EonPalette get palette =>
      Theme.of(this).extension<EonPalette>() ?? EonPalette.dark;
}

/// Builds [ThemeData] for one palette.
abstract final class EonTheme {
  static ThemeData build(EonPalette p) {
    final scheme = ColorScheme.fromSeed(
      seedColor: p.accent,
      brightness: p.brightness,
    ).copyWith(
      primary: p.accent,
      onPrimary: p.onAccent,
      secondary: p.highlight,
      surface: p.surfaceBottom,
      onSurface: p.text,
      error: p.isDark ? const Color(0xFFFF8FA3) : const Color(0xFFC62848),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      fontFamily: EonFonts.body,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: p.border),
    );

    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      extensions: [p],
      textTheme: base.textTheme.apply(
        fontFamily: EonFonts.body,
        bodyColor: p.text,
        displayColor: p.text,
      ),
      iconTheme: IconThemeData(color: p.text),
      splashFactory: InkSparkle.splashFactory,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.highlight,
        selectionColor: p.accent.withValues(alpha: 0.35),
        selectionHandleColor: p.accent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceBottom.withValues(alpha: p.isDark ? 0.55 : 0.8),
        hintStyle: TextStyle(color: p.textFaint, fontFamily: EonFonts.body),
        labelStyle: TextStyle(color: p.textMuted, fontFamily: EonFonts.body),
        floatingLabelStyle: TextStyle(
          color: p.highlight,
          fontFamily: EonFonts.body,
        ),
        prefixIconColor: p.highlight,
        suffixIconColor: p.textMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: p.highlight, width: 1.6),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.isDark ? p.surfaceTop : p.text,
        actionTextColor: p.isDark ? p.highlight : p.skyMid,
        contentTextStyle: TextStyle(
          fontFamily: EonFonts.body,
          color: p.isDark ? p.text : p.background,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: p.border),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.highlight,
        inactiveTrackColor: p.track,
        thumbColor: p.isDark ? Colors.white : p.accent,
        overlayColor: p.glow.withValues(alpha: 0.2),
        valueIndicatorColor: p.accent,
        valueIndicatorTextStyle: TextStyle(
          color: p.onAccent,
          fontFamily: EonFonts.body,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surfaceBottom,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: p.border),
        ),
        titleTextStyle: TextStyle(
          fontFamily: EonFonts.body,
          color: p.text,
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          fontFamily: EonFonts.body,
          color: p.textMuted,
          fontSize: 14.5,
          height: 1.4,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.highlight),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.onAccent : p.textFaint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : p.track,
        ),
        trackOutlineColor: WidgetStatePropertyAll(p.border),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.highlight),
    );
  }
}

/// Shorthand for Inter text styles. A null [color] inherits the theme's text
/// colour, so most call sites never need to think about dark vs light.
TextStyle eonText(
  double size, {
  FontWeight weight = FontWeight.w500,
  Color? color,
  double? letterSpacing,
  double? height,
  bool italic = false,
  List<Shadow>? shadows,
  TextDecoration? decoration,
}) {
  return TextStyle(
    fontFamily: EonFonts.body,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    shadows: shadows,
    decoration: decoration,
    decorationColor: color,
  );
}

/// Fade + slight slide page transition used for every pushed screen.
Route<T> eonRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// 1500 -> "1.5L", 1250 -> "1.25L", 1000 -> "1.0L".
String fmtLitres(int ml) {
  var s = (ml / 1000).toStringAsFixed(2);
  if (s.endsWith('0')) s = s.substring(0, s.length - 1);
  return '${s}L';
}

/// 10000 -> "10,000".
String fmtThousands(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return n < 0 ? '-$buf' : buf.toString();
}

/// 10000 -> "10K", 12500 -> "12,500".
String fmtCompact(int n) =>
    n >= 1000 && n % 1000 == 0 ? '${n ~/ 1000}K' : fmtThousands(n);
