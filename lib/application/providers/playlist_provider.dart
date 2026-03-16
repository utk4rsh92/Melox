// lib/application/providers/playlist_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/playlist.dart';
import 'repository_providers.dart';

class PlaylistNotifier extends Notifier<List<Playlist>> {
  @override
  List<Playlist> build() {
    _load();
    return []; // initial state
  }

  Future<void> _load() async {
    final repo = ref.read(playlistRepositoryProvider);
    state = await repo.fetchAllPlaylists();
  }

  Future<void> create(String name) async {
    final repo = ref.read(playlistRepositoryProvider);
    final playlist = await repo.createPlaylist(name);
    state = [...state, playlist];
  }

  Future<void> addSong(Playlist playlist, int songId) async {
    final repo = ref.read(playlistRepositoryProvider);
    final updated = await repo.addSongToPlaylist(playlist, songId);
    state = state.map((p) => p.key == updated.key ? updated : p).toList();
  }

  Future<void> removeSong(Playlist playlist, int songId) async {
    final repo = ref.read(playlistRepositoryProvider);
    final updated = await repo.removeSongFromPlaylist(playlist, songId);
    state = state.map((p) => p.key == updated.key ? updated : p).toList();
  }

  Future<void> delete(Playlist playlist) async {
    final repo = ref.read(playlistRepositoryProvider);
    await repo.deletePlaylist(playlist);
    state = state.where((p) => p.key != playlist.key).toList();
  }

  Future<void> rename(Playlist playlist, String newName) async {
    final repo = ref.read(playlistRepositoryProvider);
    final updated = await repo.renamePlaylist(playlist, newName);
    state = state.map((p) => p.key == updated.key ? updated : p).toList();
  }
}

final playlistProvider = NotifierProvider<PlaylistNotifier, List<Playlist>>(
  PlaylistNotifier.new,
);