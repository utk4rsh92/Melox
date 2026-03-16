// lib/presentation/widgets/song_tile.dart

import 'package:flutter/material.dart';
import '../../../domain/entities/song.dart';
import '../../core/theme/app_theme.dart';
import 'album_art.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.isPlaying = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    // ❌ REMOVE the two stray color: lines that were here

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      leading: AlbumArtWidget(songId: song.id, size: 48),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isPlaying ? accent : AppTheme.textPrimary, // ← themed
          fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w400,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        '${song.artist} • ${song.formattedDuration}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppTheme.textSecondary, // ← use constant
          fontSize: 13,
        ),
      ),
      trailing: isPlaying
          ? _PlayingIndicator(accent: accent) // ← pass accent
          : const Icon(
        Icons.more_vert_rounded,
        color: AppTheme.textHint,
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

// Animated bars shown on the currently playing song
class _PlayingIndicator extends StatefulWidget {
  final Color accent;
  const _PlayingIndicator({required this.accent});

  @override
  State<_PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<_PlayingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
          (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 80),
      )..repeat(reverse: true),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 3, end: 16).animate(
      CurvedAnimation(parent: c, curve: Curves.easeInOut),
    ))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: AnimatedBuilder(
        animation: Listenable.merge(_controllers),
        builder: (_, __) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (i) {
            return Container(
              width: 3,
              height: _animations[i].value,
              decoration: BoxDecoration(
                color: widget.accent, // ← themed
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ),
    );
  }
}