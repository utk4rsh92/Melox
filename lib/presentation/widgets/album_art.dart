import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../core/theme/app_theme.dart';

class AlbumArtWidget extends StatelessWidget {
  final int songId;
  final double size;
  final double borderRadius;

  const AlbumArtWidget({
    super.key,
    required this.songId,
    this.size = 48,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary; // ← add

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
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
          color: AppTheme.surfaceHigh,           // ← use constant
          child: Icon(
            Icons.music_note_rounded,
            color: accent,                        // ← themed
            size: size * 0.45,
          ),
        ),
      ),
    );
  }
}