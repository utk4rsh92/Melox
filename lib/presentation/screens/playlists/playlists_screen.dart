// lib/presentation/screens/playlists/playlists_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/playlist_provider.dart';
import '../../../application/providers/library_provider.dart';
import '../../../application/providers/player_provider.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/song.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/album_art.dart';
import '../../widgets/song_tile.dart';

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistProvider);
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        backgroundColor: accent,
        child: const Icon(Icons.add_rounded, color: Colors.black),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          playlists.isEmpty
              ? const SliverFillRemaining(child: _EmptyPlaylists())
              : SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _PlaylistCard(
                  playlist: playlists[index],
                  onTap: () =>
                      _openPlaylist(context, ref, playlists[index]),
                ),
                childCount: playlists.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('New playlist',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: const TextStyle(color: AppTheme.textHint),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(playlistProvider.notifier).create(name);
                Navigator.pop(ctx);
              }
            },
            child: Text('Create', style: TextStyle(color: accent)),
          ),
        ],
      ),
    );
  }

  void _openPlaylist(BuildContext context, WidgetRef ref, Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }
}

// ── Playlist card ──────────────────────────────────────────────

class _PlaylistCard extends ConsumerWidget {
  final Playlist playlist;
  final VoidCallback onTap;

  const _PlaylistCard({required this.playlist, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showOptions(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: playlist.songIds.isNotEmpty
                    ? AlbumArtWidget(
                  songId: playlist.songIds.first,
                  size: double.infinity,
                  borderRadius: 0,
                )
                    : Container(
                  color: AppTheme.surfaceHigh,
                  child: Center(
                    child: Icon(
                      Icons.queue_music_rounded,
                      color: accent, // ← themed
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${playlist.songCount} songs',
                    style: const TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PlaylistOptions(playlist: playlist),
    );
  }
}

// ── Playlist options bottom sheet ──────────────────────────────

class _PlaylistOptions extends ConsumerWidget {
  final Playlist playlist;
  const _PlaylistOptions({required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              playlist.name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(color: AppTheme.divider, height: 1),
          ListTile(
            leading: const Icon(Icons.edit_rounded,
                color: AppTheme.textSecondary),
            title: const Text('Rename',
                style: TextStyle(color: AppTheme.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              _showRenameDialog(context, ref, accent);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded,
                color: AppTheme.error),
            title: const Text('Delete playlist',
                style: TextStyle(color: AppTheme.error)),
            onTap: () {
              ref.read(playlistProvider.notifier).delete(playlist);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, Color accent) {
    final controller = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Rename playlist',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(playlistProvider.notifier).rename(playlist, name);
                Navigator.pop(ctx);
              }
            },
            child: Text('Save', style: TextStyle(color: accent)),
          ),
        ],
      ),
    );
  }
}

// ── Playlist detail screen ─────────────────────────────────────

class PlaylistDetailScreen extends ConsumerWidget {
  final Playlist playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final songsAsync = ref.watch(libraryProvider);
    final playerState = ref.watch(playerProvider);

    return Scaffold(
      body: songsAsync.when(
        data: (allSongs) {
          final songs = playlist.songIds
              .map((id) => allSongs.firstWhere(
                (s) => s.id == id,
            orElse: () => allSongs.first,
          ))
              .where((s) => playlist.songIds.contains(s.id))
              .toList();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    playlist.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  background: songs.isNotEmpty
                      ? AlbumArtWidget(
                    songId: songs.first.id,
                    size: double.infinity,
                    borderRadius: 0,
                  )
                      : Container(color: AppTheme.surfaceHigh),
                ),
              ),
              if (songs.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref
                            .read(playerProvider.notifier)
                            .playSong(songs.first, queue: songs);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.play_arrow_rounded,
                          color: Colors.black),
                      label: const Text(
                        'Play all',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent, // ← themed
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              songs.isEmpty
                  ? const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No songs in this playlist yet',
                    style: TextStyle(color: AppTheme.textHint),
                  ),
                ),
              )
                  : SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final song = songs[index];
                    final isPlaying =
                        playerState.currentSong?.id == song.id &&
                            playerState.isPlaying;
                    return Dismissible(
                      key: Key('${playlist.key}_${song.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: AppTheme.error,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (_) {
                        ref
                            .read(playlistProvider.notifier)
                            .removeSong(playlist, song.id);
                      },
                      child: SongTile(
                        song: song,
                        isPlaying: isPlaying,
                        onTap: () => ref
                            .read(playerProvider.notifier)
                            .playSong(song, queue: songs),
                      ),
                    );
                  },
                  childCount: songs.length,
                ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: accent), // ← themed
        ),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────

class _EmptyPlaylists extends StatelessWidget {
  const _EmptyPlaylists();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.queue_music_rounded, size: 72, color: AppTheme.textHint),
          SizedBox(height: 16),
          Text(
            'No playlists yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap + to create your first playlist',
            style: TextStyle(color: AppTheme.textHint, fontSize: 14),
          ),
        ],
      ),
    );
  }
}