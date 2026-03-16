// lib/presentation/widgets/mini_player.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/player_provider.dart';
import '../../core/theme/app_theme.dart';
import '../screens/now_playing/now_playing_screen.dart';
import 'album_art.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final state = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);
    final song = state.currentSong;

    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const NowPlayingScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          border: Border(
            top: BorderSide(
              color: accent.withOpacity(0.3), // ← themed
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: state.progressFraction, // ← was playerState, now state
              backgroundColor: AppTheme.divider,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
              minHeight: 2,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: AlbumArtWidget(songId: song.id, size: 40),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            song.artist,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      color: AppTheme.textPrimary,
                      iconSize: 28,
                      onPressed: () => notifier.skipToPrevious(),
                    ),
                    IconButton(
                      icon: Icon(
                        state.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      color: AppTheme.textPrimary,
                      iconSize: 32,
                      onPressed: () => notifier.togglePlayPause(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      color: AppTheme.textPrimary,
                      iconSize: 28,
                      onPressed: () => notifier.skipToNext(),
                    ),
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