// lib/presentation/screens/now_playing/now_playing_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../../application/providers/library_provider.dart';
import '../../../application/providers/player_provider.dart';
import '../../../application/providers/player_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/album_art.dart';
import '../lyrics/lyrics_screen.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen>
    with TickerProviderStateMixin {

  late final AnimationController _albumArtController;
  late final AnimationController _slideController;
  late final AnimationController _glowController;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _albumArtController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    );
    _slideController.forward();

    // Ambient glow pulse
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  void _syncRotation(bool isPlaying) {
    if (isPlaying) {
      _albumArtController.repeat();
    } else {
      _albumArtController.stop();
    }
  }

  @override
  void dispose() {
    _albumArtController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);
    final accent = Theme.of(context).colorScheme.primary;
    final song = state.currentSong;
    final size = MediaQuery.of(context).size;

    if (song == null) return const SizedBox.shrink();
    _syncRotation(state.isPlaying);

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(_slideAnimation),
        child: Stack(
          children: [
            // ── Ambient radial glow background ────────────
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (_, __) => CustomPaint(
                size: Size(size.width, size.height),
                painter: _AmbientGlowPainter(
                  accent: accent,
                  intensity: _glowAnimation.value,
                ),
              ),
            ),

            // ── Main content ──────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // Top bar
                  _TopBar(accent: accent),

                  const SizedBox(height: 12),

                  // Album art with swipe
                  Expanded(
                    flex: 5,
                    child: GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity != null) {
                          if (details.primaryVelocity! < -300) {
                            notifier.skipToNext();
                          } else if (details.primaryVelocity! > 300) {
                            notifier.skipToPrevious();
                          }
                        }
                      },
                      child: Center(
                        child: _PremiumAlbumArt(
                          controller: _albumArtController,
                          glowAnimation: _glowAnimation,
                          accent: accent,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Glass card — song info + progress + controls
                  _GlassControlCard(
                    state: state,
                    notifier: notifier,
                    accent: accent,
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ambient glow painter ───────────────────────────────────────

class _AmbientGlowPainter extends CustomPainter {
  final Color accent;
  final double intensity;

  _AmbientGlowPainter({required this.accent, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    // Top center glow
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withOpacity(0.12 * intensity),
          accent.withOpacity(0.04 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height * 0.3),
        radius: size.width * 0.7,
      ));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Bottom subtle glow
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withOpacity(0.06 * intensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height * 0.85),
        radius: size.width * 0.5,
      ));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint2);
  }

  @override
  bool shouldRepaint(_AmbientGlowPainter old) =>
      old.intensity != intensity || old.accent != accent;
}

// ── Top bar ────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  final Color accent;
  const _TopBar({required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: // In _TopBar build method — update the Row:
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
            color: Colors.white.withValues(alpha: 0.8),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  'NOW PLAYING',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
          // Lyrics button
          IconButton(
            icon: const Icon(Icons.lyrics_outlined, size: 22),
            color: Colors.white.withValues(alpha: 0.8),
            onPressed: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const LyricsScreen(),
                transitionsBuilder: (_, animation, __, child) =>
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.queue_music_rounded, size: 24),
            color: Colors.white.withValues(alpha: 0.8),
            onPressed: () => _showQueue(context, ref),
          ),
        ],
      ),
    );
  }

  void _showQueue(BuildContext context, WidgetRef ref) {
    final state = ref.read(playerProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  const Text(
                    'Up next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${state.queue.length}',
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF222222), height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: state.queue.length,
                itemBuilder: (context, index) {
                  final song = state.queue[index];
                  final isCurrent = index == state.currentIndex;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 2),
                    leading: Stack(
                      children: [
                        AlbumArtWidget(songId: song.id, size: 44),
                        if (isCurrent)
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.equalizer_rounded,
                              color: accent,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrent ? accent : Colors.white,
                        fontWeight: isCurrent
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      song.artist,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      ref.read(playerProvider.notifier).playSong(
                        song,
                        queue: state.queue,
                      );
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Premium album art ──────────────────────────────────────────

class _PremiumAlbumArt extends ConsumerWidget {
  final AnimationController controller;
  final Animation<double> glowAnimation;
  final Color accent;

  const _PremiumAlbumArt({
    required this.controller,
    required this.glowAnimation,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songId = ref.watch(
      playerProvider.select((s) => s.currentSong?.id),
    );
    final screenWidth = MediaQuery.of(context).size.width;
    final size = screenWidth * 0.75;

    if (songId == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: glowAnimation,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          // Outer diffused glow ring
          Container(
            width: size + 60,
            height: size + 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.15 * glowAnimation.value),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),

          // Inner tight glow
          Container(
            width: size + 16,
            height: size + 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.25 * glowAnimation.value),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

          // Vinyl grooves ring (decorative)
          Container(
            width: size + 8,
            height: size + 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withOpacity(0.15),
                width: 1,
              ),
            ),
          ),

          // Rotating album art
          RotationTransition(
            turns: controller,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: RepaintBoundary(
                  child: QueryArtworkWidget(
                    id: songId,
                    type: ArtworkType.AUDIO,
                    artworkWidth: size,
                    artworkHeight: size,
                    artworkFit: BoxFit.cover,
                    artworkBorder: BorderRadius.zero,
                    keepOldArtwork: true,
                    nullArtworkWidget: Container(
                      width: size,
                      height: size,
                      color: const Color(0xFF1A1A1A),
                      child: Icon(
                        Icons.music_note_rounded,
                        color: accent,
                        size: size * 0.38,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Center spindle dot
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF080808),
              border: Border.all(
                color: accent.withOpacity(0.6),
                width: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glass control card ─────────────────────────────────────────

class _GlassControlCard extends ConsumerWidget {
  final MeloxPlayerState state;
  final PlayerNotifier notifier;
  final Color accent;

  const _GlassControlCard({
    required this.state,
    required this.notifier,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = state.currentSong!;
    final favorites = ref.watch(favoritesNotifierProvider);
    final isFavorite = favorites.contains(song.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414).withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Song info row ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Favorite button
              GestureDetector(
                onTap: () => ref
                    .read(favoritesNotifierProvider.notifier)
                    .toggleFavorite(song),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFavorite
                        ? accent.withOpacity(0.15)
                        : Colors.white.withOpacity(0.05),
                    border: Border.all(
                      color: isFavorite
                          ? accent.withOpacity(0.4)
                          : Colors.white.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      key: ValueKey(isFavorite),
                      color: isFavorite
                          ? accent
                          : Colors.white.withOpacity(0.4),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Progress bar ───────────────────────────────
          _PremiumProgressBar(state: state, notifier: notifier, accent: accent),

          const SizedBox(height: 20),

          // ── Main controls ──────────────────────────────
          _PremiumControls(state: state, notifier: notifier, accent: accent),

          const SizedBox(height: 18),

          // ── Volume + secondary controls ────────────────
          _BottomRow(state: state, notifier: notifier, accent: accent),
        ],
      ),
    );
  }
}

// ── Premium progress bar ───────────────────────────────────────

// Replace _PremiumProgressBar with this:
// Replace _PremiumProgressBar with this:

class _PremiumProgressBar extends StatefulWidget {
  final MeloxPlayerState state;
  final PlayerNotifier notifier;
  final Color accent;

  const _PremiumProgressBar({
    required this.state,
    required this.notifier,
    required this.accent,
  });

  @override
  State<_PremiumProgressBar> createState() => _PremiumProgressBarState();
}

class _PremiumProgressBarState extends State<_PremiumProgressBar>
    with SingleTickerProviderStateMixin {
  double? _dragValue;
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        _dragValue ?? widget.state.progressFraction.clamp(0.0, 1.0);

    return Column(
      children: [
        GestureDetector(
          onHorizontalDragStart: (_) {
            setState(() => _dragValue = progress);
          },
          onHorizontalDragUpdate: (details) {
            final box = context.findRenderObject() as RenderBox;
            final localX =
            details.localPosition.dx.clamp(0.0, box.size.width);
            setState(() {
              _dragValue = (localX / box.size.width).clamp(0.0, 1.0);
            });
          },
          onHorizontalDragEnd: (_) {
            if (_dragValue != null) {
              widget.notifier.seekToFraction(_dragValue!);
              setState(() => _dragValue = null);
            }
          },
          onTapUp: (details) {
            final box = context.findRenderObject() as RenderBox;
            final localX =
            details.localPosition.dx.clamp(0.0, box.size.width);
            final value = (localX / box.size.width).clamp(0.0, 1.0);
            widget.notifier.seekToFraction(value);
          },
          child: SizedBox(
            height: 64,
            child: CustomPaint(
              painter: _WaveProgressPainter(
                progress: progress,
                accent: widget.accent,
              ),
              size: const Size(double.infinity, 64),
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Time labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.state.formattedPosition,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '-${_remaining(widget.state)}',
                style: TextStyle(
                  color: widget.accent.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                widget.state.formattedDuration,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _remaining(MeloxPlayerState state) {
    final remaining = state.duration - state.position;
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// ── Static wave progress painter ───────────────────────────────

class _WaveProgressPainter extends CustomPainter {
  final double progress;
  final Color accent;

  _WaveProgressPainter({
    required this.progress,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final midY = h / 2;
    const amplitude = 9.0;
    const frequency = 7.0; // number of full waves across track
    const steps = 400;

    final progressX = w * progress;

    // ── Full static wave — no phase, no animation ──────
    final playedPath = Path();
    final unplayedPath = Path();
    bool playedStarted = false;
    bool unplayedStarted = false;

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = w * t;

      // Same formula for both — static sine, no phase offset
      final y = midY + amplitude * sin(2 * pi * frequency * t);

      if (x <= progressX) {
        // Played portion — full amplitude
        if (!playedStarted) {
          playedPath.moveTo(x, y);
          playedStarted = true;
        } else {
          playedPath.lineTo(x, y);
        }
      } else {
        // Unplayed portion — smaller amplitude, dimmer
        final unplayedY = midY + amplitude * 0.45 * sin(2 * pi * frequency * t);
        if (!unplayedStarted) {
          unplayedPath.moveTo(x, unplayedY);
          unplayedStarted = true;
        } else {
          unplayedPath.lineTo(x, unplayedY);
        }
      }
    }

    // ── Draw unplayed track ────────────────────────────
    canvas.drawPath(
      unplayedPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Draw played glow ───────────────────────────────
    if (progress > 0) {
      canvas.drawPath(
        playedPath,
        Paint()
          ..color = accent.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // ── Draw played wave — sharp, bright ─────────────
      canvas.drawPath(
        playedPath,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // ── Glowing dot at progress tip ────────────────────
    if (progress > 0 && progress < 1) {
      final dotX = progressX;
      final dotY = midY + amplitude * sin(2 * pi * frequency * progress);

      // Outer glow ring
      canvas.drawCircle(
        Offset(dotX, dotY),
        10,
        Paint()..color = accent.withValues(alpha: 0.12),
      );
      // Mid ring
      canvas.drawCircle(
        Offset(dotX, dotY),
        6,
        Paint()..color = accent.withValues(alpha: 0.3),
      );
      // White core
      canvas.drawCircle(
        Offset(dotX, dotY),
        4,
        Paint()..color = Colors.white,
      );
      // Accent center
      canvas.drawCircle(
        Offset(dotX, dotY),
        2,
        Paint()..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveProgressPainter old) =>
      old.progress != progress || old.accent != accent;
}

// ── Premium controls ───────────────────────────────────────────

class _PremiumControls extends StatelessWidget {
  final MeloxPlayerState state;
  final PlayerNotifier notifier;
  final Color accent;

  const _PremiumControls({
    required this.state,
    required this.notifier,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Shuffle
        _ControlButton(
          icon: Icons.shuffle_rounded,
          size: 20,
          color: state.isShuffled
              ? accent
              : Colors.white.withOpacity(0.35),
          onTap: () => notifier.toggleShuffle(),
          isActive: state.isShuffled,
          activeDotColor: accent,
        ),

        // Previous
        GestureDetector(
          onTap: () => notifier.skipToPrevious(),
          child: Icon(
            Icons.skip_previous_rounded,
            color: Colors.white.withOpacity(0.9),
            size: 40,
          ),
        ),

        // Play/Pause — large glowing button
        GestureDetector(
          onTap: () => notifier.togglePlayPause(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(state.isPlaying ? 0.5 : 0.2),
                  blurRadius: state.isPlaying ? 28 : 12,
                  spreadRadius: state.isPlaying ? 2 : 0,
                ),
              ],
            ),
            child: state.isBuffering
                ? const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2,
              ),
            )
                : AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                state.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                key: ValueKey(state.isPlaying),
                color: Colors.black,
                size: 36,
              ),
            ),
          ),
        ),

        // Next
        GestureDetector(
          onTap: () => notifier.skipToNext(),
          child: Icon(
            Icons.skip_next_rounded,
            color: Colors.white.withOpacity(0.9),
            size: 40,
          ),
        ),

        // Repeat
        _ControlButton(
          icon: state.repeatMode == RepeatMode.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded,
          size: 20,
          color: state.repeatMode != RepeatMode.off
              ? accent
              : Colors.white.withOpacity(0.35),
          onTap: () => notifier.toggleRepeat(),
          isActive: state.repeatMode != RepeatMode.off,
          activeDotColor: accent,
        ),
      ],
    );
  }
}

// ── Control button with active dot indicator ───────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onTap;
  final bool isActive;
  final Color activeDotColor;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.color,
    required this.onTap,
    required this.isActive,
    required this.activeDotColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: size),
            const SizedBox(height: 4),
            // Active indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 4 : 0,
              height: isActive ? 4 : 0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeDotColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom row — volume ────────────────────────────────────────

class _BottomRow extends StatelessWidget {
  final MeloxPlayerState state;
  final PlayerNotifier notifier;
  final Color accent;

  const _BottomRow({
    required this.state,
    required this.notifier,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.volume_down_rounded,
          color: Colors.white.withOpacity(0.25),
          size: 18,
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              activeTrackColor: Colors.white.withOpacity(0.4),
              inactiveTrackColor: Colors.white.withOpacity(0.08),
              thumbColor: Colors.white.withOpacity(0.7),
              overlayColor: Colors.white.withOpacity(0.08),
            ),
            child: Slider(
              value: state.volume,
              onChanged: (value) => notifier.setVolume(value),
            ),
          ),
        ),
        Icon(
          Icons.volume_up_rounded,
          color: Colors.white.withOpacity(0.25),
          size: 18,
        ),
      ],
    );
  }
}