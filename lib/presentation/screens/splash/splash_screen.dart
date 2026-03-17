import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/providers/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../home/home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {

  // Read accent ONCE at build time so painters get the right color
  Color get _accent => ref.read(themeProvider).primary;

  late final AnimationController _ringController;
  late final AnimationController _waveController;
  late final AnimationController _revealController;
  late final AnimationController _exitController;

  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;
  late final Animation<double> _glowPulse;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _dotsOpacity;
  late final Animation<double> _exitFade;
  late final Animation<double> _exitScale;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
      ),
    );
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );
    _glowPulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.4, 0.65, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _revealController,
      curve: const Interval(0.4, 0.65, curve: Curves.easeOutCubic),
    ));
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.55, 0.78, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _revealController,
      curve: const Interval(0.55, 0.78, curve: Curves.easeOutCubic),
    ));
    _dotsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
      ),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );

    _start();
  }

  Future<void> _start() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _revealController.forward();
    await Future.delayed(const Duration(milliseconds: 2800));
    await _exitController.forward();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  void dispose() {
    _ringController.dispose();
    _waveController.dispose();
    _revealController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent; // ← read once per build

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF080808),
        body: AnimatedBuilder(
          animation: Listenable.merge([_exitController, _revealController]),
          builder: (context, _) {
            return FadeTransition(
              opacity: _exitFade,
              child: ScaleTransition(
                scale: _exitScale,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background grid
                    CustomPaint(
                      painter: _GridPainter(accent: accent),
                    ),

                    // Rotating rings
                    AnimatedBuilder(
                      animation: _ringController,
                      builder: (_, __) => CustomPaint(
                        painter: _RingsPainter(
                          progress: _ringController.value,
                          glowOpacity: _glowPulse.value,
                          accent: accent, // ← themed
                        ),
                      ),
                    ),

                    // Center content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon
                          FadeTransition(
                            opacity: _iconFade,
                            child: ScaleTransition(
                              scale: _iconScale,
                              child: AnimatedBuilder(
                                animation: _waveController,
                                builder: (_, __) => _GlowIcon(
                                  glowRadius: 40 +
                                      (_waveController.value * 20) *
                                          _glowPulse.value,
                                  glowOpacity: 0.35 *
                                      _glowPulse.value *
                                      (0.7 + _waveController.value * 0.3),
                                  accent: accent, // ← themed
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Waveform bars
                          FadeTransition(
                            opacity: _glowPulse,
                            child: AnimatedBuilder(
                              animation: _waveController,
                              builder: (_, __) => _WaveformWidget(
                                progress: _waveController.value,
                                accent: accent, // ← themed
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // App name
                          ClipRect(
                            child: SlideTransition(
                              position: _titleSlide,
                              child: FadeTransition(
                                opacity: _titleFade,
                                child: const Text(
                                  'MELOX',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Tagline
                          ClipRect(
                            child: SlideTransition(
                              position: _taglineSlide,
                              child: FadeTransition(
                                opacity: _taglineFade,
                                child: const Text(
                                  'Music for your soul',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 3.0,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 56),

                          // Loading dots
                          FadeTransition(
                            opacity: _dotsOpacity,
                            child: AnimatedBuilder(
                              animation: _waveController,
                              builder: (_, __) => _LoadingDots(
                                progress: _waveController.value,
                                accent: accent, // ← themed
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Glow icon ──────────────────────────────────────────────────

class _GlowIcon extends StatelessWidget {
  final double glowRadius;
  final double glowOpacity;
  final Color accent;

  const _GlowIcon({
    required this.glowRadius,
    required this.glowOpacity,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF111111),
        border: Border.all(
          color: accent.withValues(alpha: 0.3), // ← themed
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: glowOpacity), // ← themed
            blurRadius: glowRadius,
            spreadRadius: glowRadius * 0.3,
          ),
          BoxShadow(
            color: accent.withValues(alpha: glowOpacity * 0.4), // ← themed
            blurRadius: glowRadius * 2.5,
            spreadRadius: glowRadius * 0.1,
          ),
        ],
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: accent, // ← themed
        size: 52,
      ),
    );
  }
}

// ── Waveform bars ──────────────────────────────────────────────

class _WaveformWidget extends StatelessWidget {
  final double progress;
  final Color accent;

  const _WaveformWidget({
    required this.progress,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    const barCount = 28;
    const maxHeight = 28.0;
    const minHeight = 4.0;

    return SizedBox(
      height: maxHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (i) {
          final phase = (i / barCount) * 2 * pi;
          final wave = sin(phase + progress * 2 * pi);
          final secondWave = sin(phase * 1.7 + progress * 2 * pi * 0.8);
          final height = minHeight +
              (maxHeight - minHeight) * ((wave + secondWave + 2) / 4);

          // Lerp between dimmed and full accent
          final t = i / barCount;
          final color = Color.lerp(
            accent.withValues(alpha: 0.5),
            accent,
            t,
          )!;

          return Container(
            width: 3,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: (0.7 + wave * 0.3).clamp(0.0, 1.0),
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

// ── Loading dots ───────────────────────────────────────────────

class _LoadingDots extends StatelessWidget {
  final double progress;
  final Color accent;

  const _LoadingDots({
    required this.progress,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final dotProgress = ((progress + i * 0.33) % 1.0);
        final scale = 0.6 + sin(dotProgress * pi) * 0.4;
        final opacity = (0.3 + sin(dotProgress * pi) * 0.7).clamp(0.0, 1.0);

        return Container(
          width: 6 * scale,
          height: 6 * scale,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: opacity), // ← themed
          ),
        );
      }),
    );
  }
}

// ── Rotating rings painter ─────────────────────────────────────

class _RingsPainter extends CustomPainter {
  final double progress;
  final double glowOpacity;
  final Color accent;

  _RingsPainter({
    required this.progress,
    required this.glowOpacity,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    _drawRing(canvas, center, 130, progress * 2 * pi, 8, 0.08);
    _drawRing(canvas, center, 180, -progress * 2 * pi * 0.7, 5, 0.05);
    _drawRing(canvas, center, 230, progress * 2 * pi * 0.5, 4, 0.04);
  }

  void _drawRing(
      Canvas canvas,
      Offset center,
      double radius,
      double rotation,
      int dotCount,
      double baseOpacity,
      ) {
    final paint = Paint()
      ..color = accent.withValues(
        alpha: (baseOpacity * glowOpacity).clamp(0.0, 1.0),
      ) // ← themed
      ..style = PaintingStyle.fill;

    for (int i = 0; i < dotCount; i++) {
      final angle = rotation + (i / dotCount) * 2 * pi;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      final dotSize = 2.0 + (i % 3) * 0.8;
      canvas.drawCircle(Offset(x, y), dotSize, paint);
    }

    final arcPaint = Paint()
      ..color = accent.withValues(
        alpha: (baseOpacity * 0.4 * glowOpacity).clamp(0.0, 1.0),
      ) // ← themed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawCircle(center, radius, arcPaint);
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.progress != progress ||
          old.glowOpacity != glowOpacity ||
          old.accent != accent;
}

// ── Background grid painter ────────────────────────────────────

class _GridPainter extends CustomPainter {
  final Color accent;
  const _GridPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.025) // ← themed
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.accent != accent;
}