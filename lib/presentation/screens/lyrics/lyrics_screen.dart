import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../application/providers/lyrics_provider.dart';
import '../../../application/providers/player_provider.dart';
import '../../../core/theme/app_theme.dart';

class LyricsScreen extends ConsumerStatefulWidget {
  const LyricsScreen({super.key});

  @override
  ConsumerState<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends ConsumerState<LyricsScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  int _lastIndex = -1;

  // Screen entrance animation
  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  // Active line glow pulse
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _entranceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _scrollToLine(int index) {
    if (!_scrollController.hasClients) return;
    if (index == _lastIndex || index < 0) return;
    _lastIndex = index;

    final screenHeight = _scrollController.position.viewportDimension;
    const itemHeight = 68.0;
    final offset =
        (index * itemHeight) - (screenHeight / 2) + (itemHeight / 2);

    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final lyricsState = ref.watch(lyricsProvider);
    final playerState = ref.watch(playerProvider);
    final position = playerState.position;
    final notifier = ref.read(lyricsProvider.notifier);

    final currentIndex = notifier.getCurrentLineIndex(position);
    final hasSynced = lyricsState.lines.isNotEmpty &&
        lyricsState.lines.first.timestamp != Duration.zero;

    if (hasSynced && currentIndex >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToLine(currentIndex);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: FadeTransition(
          opacity: _entranceFade,
          child: Column(
            children: [
              Text(
                playerState.currentSong?.title ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                playerState.currentSong?.artist ?? '',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          if (hasSynced)
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (_, __) => Container(
                margin: const EdgeInsets.only(right: 16),
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accent.withValues(
                        alpha: 0.2 + 0.3 * _glowAnimation.value),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(
                          alpha: 0.1 * _glowAnimation.value),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  'SYNCED',
                  style: GoogleFonts.plusJakartaSans(
                    color: accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SlideTransition(
        position: _entranceSlide,
        child: FadeTransition(
          opacity: _entranceFade,
          child: _buildBody(
            context,
            lyricsState,
            currentIndex,
            hasSynced,
            accent,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context,
      LyricsState lyricsState,
      int currentIndex,
      bool hasSynced,
      Color accent,
      ) {
    if (lyricsState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated music note while loading
            AnimatedBuilder(
              animation: _glowController,
              builder: (_, __) => Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceHigh,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(
                          alpha: 0.2 * _glowAnimation.value),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.music_note_rounded,
                  color: accent,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Fetching lyrics...',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textHint,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    if (lyricsState.notFound) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceHigh,
              ),
              child: const Icon(
                Icons.lyrics_outlined,
                size: 36,
                color: AppTheme.textHint,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No lyrics found',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lyrics not available for this song',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textHint,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (lyricsState.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceHigh,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 36,
                color: AppTheme.textHint,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Could not load lyrics',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your internet connection',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textHint,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (lyricsState.lines.isEmpty) return const SizedBox.shrink();

    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.white,
          Colors.white,
          Colors.transparent,
        ],
        stops: [0.0, 0.12, 0.88, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(
          vertical: 300,
          horizontal: 28,
        ),
        itemCount: lyricsState.lines.length,
        itemBuilder: (context, index) {
          final line = lyricsState.lines[index];
          final isCurrent = index == currentIndex && hasSynced;
          final isPast = index < currentIndex && hasSynced;
          final isNext = index == currentIndex + 1 && hasSynced;
          final isNearby = (index - currentIndex).abs() <= 2 && hasSynced;

          return GestureDetector(
            onTap: hasSynced
                ? () => ref
                .read(playerProvider.notifier)
                .seekTo(line.timestamp)
                : null,
            child: _LyricLine(
              text: line.text,
              isCurrent: isCurrent,
              isPast: isPast,
              isNext: isNext,
              isNearby: isNearby,
              accent: accent,
              glowAnimation: _glowAnimation,
            ),
          );
        },
      ),
    );
  }
}

// ── Animated lyric line widget ─────────────────────────────────

class _LyricLine extends StatefulWidget {
  final String text;
  final bool isCurrent;
  final bool isPast;
  final bool isNext;
  final bool isNearby;
  final Color accent;
  final Animation<double> glowAnimation;

  const _LyricLine({
    required this.text,
    required this.isCurrent,
    required this.isPast,
    required this.isNext,
    required this.isNearby,
    required this.accent,
    required this.glowAnimation,
  });

  @override
  State<_LyricLine> createState() => _LyricLineState();
}

class _LyricLineState extends State<_LyricLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _activateController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  bool _wasActive = false;

  @override
  void initState() {
    super.initState();
    _activateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _activateController,
        curve: Curves.easeOutBack,
      ),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _activateController,
        curve: Curves.easeOut,
      ),
    );

    if (widget.isCurrent) {
      _activateController.forward();
      _wasActive = true;
    }
  }

  @override
  void didUpdateWidget(_LyricLine old) {
    super.didUpdateWidget(old);
    // Trigger scale+fade animation when line becomes active
    if (widget.isCurrent && !_wasActive) {
      _activateController.forward(from: 0);
      _wasActive = true;
    } else if (!widget.isCurrent) {
      _wasActive = false;
    }
  }

  @override
  void dispose() {
    _activateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetColor = widget.isCurrent
        ? widget.accent
        : widget.isPast
        ? Colors.white.withValues(alpha: 0.28)
        : widget.isNext
        ? Colors.white.withValues(alpha: 0.55)
        : widget.isNearby
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.15);

    final targetSize =
    widget.isCurrent ? 23.0 : widget.isNext ? 17.0 : 15.0;

    final targetWeight = widget.isCurrent
        ? FontWeight.w800
        : widget.isNext
        ? FontWeight.w600
        : FontWeight.w400;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(
        vertical: widget.isCurrent ? 16 : 10,
        horizontal: widget.isCurrent ? 0 : 4,
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([_activateController, widget.glowAnimation]),
        builder: (_, __) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Glow behind active line
              if (widget.isCurrent)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accent.withValues(
                            alpha: 0.08 * widget.glowAnimation.value,
                          ),
                          blurRadius: 20,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),

              // Scale animation on activation
              ScaleTransition(
                scale: widget.isCurrent ? _scaleAnim : const AlwaysStoppedAnimation(1.0),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: targetSize,
                    fontWeight: targetWeight,
                    color: targetColor,
                    height: 1.4,
                    shadows: widget.isCurrent
                        ? [
                      Shadow(
                        color: widget.accent.withValues(
                          alpha: 0.4 * widget.glowAnimation.value,
                        ),
                        blurRadius: 12,
                      ),
                    ]
                        : null,
                  ),
                  child: Text(
                    widget.text,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}