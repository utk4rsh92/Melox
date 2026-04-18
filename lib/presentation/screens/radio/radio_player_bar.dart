// lib/presentation/screens/radio/radio_player_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/providers/radio_provider.dart';
import '../../../core/theme/app_theme.dart';

class RadioPlayerBar extends ConsumerWidget {
  final RadioPlayerState state;
  const RadioPlayerBar({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final station = state.currentStation!;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        border: Border(
          top: BorderSide(
            color: accent.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Live badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.4),
                ),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Station info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (state.isBuffering)
                    const Text(
                      'Connecting...',
                      style: TextStyle(
                        color: AppTheme.textHint,
                        fontSize: 12,
                      ),
                    )
                  else if (state.hasError)
                    const Text(
                      'Stream unavailable',
                      style: TextStyle(
                        color: AppTheme.error,
                        fontSize: 12,
                      ),
                    )
                  else
                    Text(
                      station.genre.isNotEmpty
                          ? station.genre
                          : station.country,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            // Play/pause
            IconButton(
              icon: state.isBuffering
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: accent,
                  strokeWidth: 2,
                ),
              )
                  : Icon(
                state.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: AppTheme.textPrimary,
                size: 28,
              ),
              onPressed: () => ref
                  .read(radioPlayerProvider.notifier)
                  .togglePlayPause(),
            ),

            // Stop
            IconButton(
              icon: const Icon(
                Icons.stop_rounded,
                color: AppTheme.textSecondary,
                size: 24,
              ),
              onPressed: () =>
                  ref.read(radioPlayerProvider.notifier).stop(),
            ),
          ],
        ),
      ),
    );
  }
}