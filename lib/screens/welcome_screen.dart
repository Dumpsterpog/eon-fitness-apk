import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/eon_theme.dart';
import '../widgets/widgets.dart';
import 'auth_screen.dart';

/// Eon Fitness landing screen: crown logo, title, painted hunter, Login / Sign Up.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  late final Animation<double> _sceneZoom = Tween<double>(
    begin: 1.08,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic));

  late final Animation<double> _headerFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.15, 0.6, curve: Curves.easeOut),
  );

  late final Animation<double> _footerFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _openAuth() =>
      Navigator.of(context).push(eonRoute<void>(const AuthScreen()));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final size = MediaQuery.sizeOf(context);
    final titleSize = (size.width * 0.11).clamp(34.0, 52.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: p.overlayStyle,
      child: Scaffold(
        backgroundColor: p.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            ScaleTransition(
              scale: _sceneZoom,
              child: const RealmScene(variant: RealmVariant.welcome),
            ),
            _Scrim(palette: p),
            const IgnorePointer(child: RepaintBoundary(child: EmberField())),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: FadeTransition(
                        opacity: _headerFade,
                        child: const ThemeToggleButton(),
                      ),
                    ),
                    SizedBox(height: size.height * 0.005),
                    FadeTransition(
                      opacity: _headerFade,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.2),
                          end: Offset.zero,
                        ).animate(_headerFade),
                        child: _Header(titleSize: titleSize, pulse: _pulse),
                      ),
                    ),
                    const Spacer(),
                    FadeTransition(
                      opacity: _footerFade,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(_footerFade),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GlowButton(
                              label: 'Login / Sign Up',
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 26,
                              ),
                              onPressed: _openAuth,
                            ),
                            const SizedBox(height: 22),
                            Text(
                              '"Another quest awaits..."',
                              textAlign: TextAlign.center,
                              style: eonText(
                                14,
                                italic: true,
                                weight: FontWeight.w400,
                                letterSpacing: 0.3,
                                color: p.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.04),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.titleSize, required this.pulse});

  final double titleSize;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: pulse,
          builder:
              (context, _) => CrownIcon(
                size: titleSize * 0.95,
                glow: 0.55 + 0.45 * pulse.value,
              ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Eon',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: EonFonts.display,
              fontSize: titleSize * 1.25,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              height: 1.1,
              color: p.text,
              shadows: [
                Shadow(
                  color: p.glow.withValues(alpha: 0.8 * p.glowStrength),
                  blurRadius: 16,
                ),
                Shadow(
                  color: p.accent.withValues(alpha: 0.6 * p.glowStrength),
                  blurRadius: 36,
                ),
              ],
            ),
          ),
        ),
        Text(
          'FITNESS',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: EonFonts.display,
            fontSize: titleSize * 0.42,
            fontWeight: FontWeight.w700,
            letterSpacing: titleSize * 0.28,
            color: p.highlight,
            shadows: p.textGlow(0.8),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'LEVEL UP YOUR FITNESS',
          textAlign: TextAlign.center,
          style: eonText(
            13,
            letterSpacing: 3,
            weight: FontWeight.w600,
            color: p.text.withValues(alpha: 0.88),
          ),
        ),
      ],
    );
  }
}

/// Fades the scene into the background colour behind the title and the
/// button so text stays readable in both themes.
class _Scrim extends StatelessWidget {
  const _Scrim({required this.palette});

  final EonPalette palette;

  @override
  Widget build(BuildContext context) {
    final c = palette.scrim;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.3, 0.55, 0.8, 1.0],
            colors: [
              c.withValues(alpha: 0.9),
              c.withValues(alpha: 0.2),
              c.withValues(alpha: 0),
              c.withValues(alpha: 0.7),
              c.withValues(alpha: 0.98),
            ],
          ),
        ),
      ),
    );
  }
}
