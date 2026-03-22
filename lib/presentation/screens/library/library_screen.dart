import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ❌ REMOVE: import 'package:flutter_riverpod/legacy.dart';

import '../../../application/providers/library_provider.dart';
import '../../../application/providers/player_provider.dart';
import '../../../application/providers/playlist_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/song.dart';
import '../../widgets/album_art.dart';
import '../../widgets/song_tile.dart';

final _sortOptions = ['Title', 'Artist', 'Album', 'Date added'];
//final _selectedSortProvider = NotifierProvider<_SortNotifier, int>(_SortNotifier.new);
//final _showFavoritesProvider = NotifierProvider<_FavNotifier, bool>(_FavNotifier.new);

// class _SortNotifier extends Notifier<int> {
//   @override int build() => 0;
// }
// class _FavNotifier extends Notifier<bool> {
//   @override bool build() => false;
// }

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final songsAsync = ref.watch(filteredSongsProvider);
    final playerState = ref.watch(playerProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ❌ SliverAppBar fully deleted — title & search live in HomeScreen now

          const SliverToBoxAdapter(child: SizedBox(height: 8)), // small top gap
          SliverToBoxAdapter(child: _SortBar()),

          songsAsync.when(
            data: (songs) => songs.isEmpty
                ? const SliverFillRemaining(child: _EmptyLibrary())
                : SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final song = songs[index];
                  final isPlaying =
                      playerState.currentSong?.id == song.id &&
                          playerState.isPlaying;
                  return SongTile(
                    song: song,
                    isPlaying: isPlaying,
                    onTap: () => ref
                        .read(playerProvider.notifier)
                        .playSong(song, queue: songs),
                    onLongPress: () =>
                        _showSongOptions(context, ref, song),
                  );
                },
                childCount: songs.length,
              ),
            ),
            loading: () => SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: accent),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text(
                  'Could not load library.\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

// ── Song options bottom sheet ─────────────────────────────────

void _showSongOptions(BuildContext context, WidgetRef ref, Song song) {
  final accent = Theme.of(context).colorScheme.primary;
  final playlists = ref.read(playlistProvider);
  final isFavorite = ref.read(favoritesNotifierProvider).contains(song.id);

  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Song title header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                AlbumArtWidget(songId: song.id, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        song.artist,
                        maxLines: 1,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppTheme.divider, height: 1),

          // Favorite toggle
          ListTile(
            leading: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isFavorite ? accent : AppTheme.textSecondary,
            ),
            title: Text(
              isFavorite ? 'Remove from favorites' : 'Add to favorites',
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
            onTap: () {
              ref
                  .read(favoritesNotifierProvider.notifier)
                  .toggleFavorite(song);
              Navigator.pop(context);
            },
          ),

          const Divider(color: AppTheme.divider, height: 1),

          // Add to playlist
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add to playlist',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          if (playlists.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'No playlists yet — create one first',
                style: TextStyle(color: AppTheme.textHint),
              ),
            )
          else
            ...playlists.map((playlist) => ListTile(
              leading: const Icon(Icons.queue_music_rounded,
                  color: AppTheme.textSecondary),
              title: Text(playlist.name,
                  style:
                  const TextStyle(color: AppTheme.textPrimary)),
              subtitle: Text('${playlist.songCount} songs',
                  style: const TextStyle(color: AppTheme.textHint)),
              onTap: () {
                ref
                    .read(playlistProvider.notifier)
                    .addSong(playlist, song.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added to ${playlist.name}'),
                    backgroundColor: AppTheme.surfaceHigh,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            )),

          const Divider(color: AppTheme.divider, height: 1),

          // ← DELETE OPTION
          ListTile(
            leading: const Icon(
              Icons.delete_outline_rounded,
              color: AppTheme.error,
            ),
            title: const Text(
              'Delete from device',
              style: TextStyle(color: AppTheme.error),
            ),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context, ref, song);
            },
          ),

          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

// ── Confirm delete dialog ─────────────────────────────────────

void _confirmDelete(BuildContext context, WidgetRef ref, Song song) {
  final accent = Theme.of(context).colorScheme.primary;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text(
        'Delete song?',
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      content: Text(
        '"${song.title}" will be permanently deleted from your device.',
        style: const TextStyle(color: AppTheme.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Cancel',
            style: TextStyle(color: accent),
          ),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await ref
                .read(favoritesNotifierProvider.notifier)
                .deleteSong(song);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${song.title}" deleted'),
                  backgroundColor: AppTheme.surfaceHigh,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: const Text(
            'Delete',
            style: TextStyle(
              color: AppTheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Sort bar ──────────────────────────────────────────────────

class _SortBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final selected = ref.watch(selectedSortProvider);       // ← public
    final showFavorites = ref.watch(showFavoritesProvider); // ← public

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          // Favorites chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(
                Icons.favorite_rounded,
                size: 14,
                color: showFavorites ? accent : AppTheme.textHint,
              ),
              label: const Text('Favorites'),
              selected: showFavorites,
              onSelected: (_) => ref
                  .read(showFavoritesProvider.notifier)  // ← public
                  .state = !showFavorites,
              selectedColor: accent.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: showFavorites ? accent : AppTheme.textSecondary,
                fontSize: 13,
              ),
              side: BorderSide(
                color: showFavorites ? accent : AppTheme.divider,
              ),
              backgroundColor: AppTheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),

          // Sort chips
          ...List.generate(_sortOptions.length, (i) {
            final isSelected = selected == i && !showFavorites;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_sortOptions[i]),
                selected: isSelected,
                onSelected: (_) {
                  ref.read(showFavoritesProvider.notifier).state = false; // ← public
                  ref.read(selectedSortProvider.notifier).state = i;      // ← public
                },
                selectedColor: accent.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? accent : AppTheme.textSecondary,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: isSelected ? accent : AppTheme.divider,
                ),
                backgroundColor: AppTheme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Search delegate ───────────────────────────────────────────

class SongSearchDelegate extends SearchDelegate<Song?> {
  final WidgetRef ref;
  SongSearchDelegate(this.ref);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: AppTheme.textHint),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () => query = '',
    ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back_rounded),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    // ✅ Defer provider update until after build completes
    Future.microtask(() {
      ref.read(searchQueryProvider.notifier).state = query;
    });
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final songsAsync = ref.watch(filteredSongsProvider);
    return songsAsync.when(
      data: (songs) => ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, i) => SongTile(
          song: songs[i],
          onTap: () {
            close(context, songs[i]);
            ref.read(playerProvider.notifier).playSong(
              songs[i],
              queue: songs,
            );
          },
        ),
      ),
      loading: () =>
          Center(child: CircularProgressIndicator(color: accent)),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_music_outlined,
            size: 72,
            color: AppTheme.textHint,
          ),
          SizedBox(height: 16),
          Text(
            'No music found',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add MP3 files to your device\nto see them here',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}