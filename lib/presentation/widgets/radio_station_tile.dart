// lib/presentation/widgets/radio_station_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/radio_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/radio_station.dart';

class RadioStationTile extends ConsumerWidget {
  final RadioStation station;
  const RadioStationTile({super.key, required this.station});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final radioState = ref.watch(radioPlayerProvider);
    final isPlaying = radioState.currentStation?.stationUuid ==
        station.stationUuid &&
        radioState.isPlaying;
    final isCurrent = radioState.currentStation?.stationUuid ==
        station.stationUuid;

    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _StationLogo(
        logoUrl: station.logoUrl,
        size: 48,
        accent: accent,
      ),
      title: Text(
        station.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isCurrent ? accent : AppTheme.textPrimary,
          fontWeight:
          isCurrent ? FontWeight.w600 : FontWeight.w400,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        station.genre.isNotEmpty ? station.genre : station.country,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppTheme.textHint,
          fontSize: 12,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Favorite button
          IconButton(
            icon: Icon(
              station.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color:
              station.isFavorite ? accent : AppTheme.textHint,
              size: 20,
            ),
            onPressed: () async {
              await ref
                  .read(radioRepositoryProvider)
                  .toggleFavorite(station);
              ref.invalidate(radioFavoritesProvider);
            },
          ),

          // Play button
          GestureDetector(
            onTap: () => ref
                .read(radioPlayerProvider.notifier)
                .playStation(station),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent
                    ? accent
                    : AppTheme.surfaceHigh,
              ),
              child: radioState.isBuffering && isCurrent
                  ? Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  color: isCurrent
                      ? Colors.black
                      : accent,
                  strokeWidth: 2,
                ),
              )
                  : Icon(
                isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: isCurrent
                    ? Colors.black
                    : AppTheme.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      onTap: () => ref
          .read(radioPlayerProvider.notifier)
          .playStation(station),
    );
  }
}

// ── Station logo ───────────────────────────────────────────────

class _StationLogo extends StatelessWidget {
  final String logoUrl;
  final double size;
  final Color accent;

  const _StationLogo({
    required this.logoUrl,
    required this.size,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: logoUrl.isNotEmpty
          ? Image.network(
        logoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(accent),
      )
          : _placeholder(accent),
    );
  }

  Widget _placeholder(Color accent) {
    return Container(
      width: size,
      height: size,
      color: AppTheme.surfaceHigh,
      child: Icon(Icons.radio, color: accent, size: size * 0.5),
    );
  }
}