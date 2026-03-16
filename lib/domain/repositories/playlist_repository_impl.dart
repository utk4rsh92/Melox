// lib/data/repositories/playlist_repository_impl.dart

import 'package:hive_ce/hive.dart';

import '../../domain/entities/playlist.dart';
import '../../domain/repositories/playlist_repository.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  final Box<Playlist> _box = Hive.box<Playlist>('playlists');

  @override
  Future<List<Playlist>> fetchAllPlaylists() async {
    return _box.values.toList();
  }

  @override
  Future<Playlist> createPlaylist(String name) async {
    final playlist = Playlist(
      name: name,
      songIds: [],
      createdAt: DateTime.now(),
    );
    await _box.add(playlist);  // auto-increments key
    return playlist;
  }

  @override
  Future<Playlist> addSongToPlaylist(Playlist playlist, int songId) async {
    if (playlist.containsSong(songId)) return playlist; // no duplicates

    playlist.songIds.add(songId);
    await playlist.save();  // HiveObject .save() updates in place
    return playlist;
  }

  @override
  Future<Playlist> removeSongFromPlaylist(Playlist playlist, int songId) async {
    playlist.songIds.remove(songId);
    await playlist.save();
    return playlist;
  }

  @override
  Future<void> deletePlaylist(Playlist playlist) async {
    await playlist.delete();  // HiveObject .delete() removes from box
  }

  @override
  Future<Playlist> renamePlaylist(Playlist playlist, String newName) async {
    playlist.name = newName;
    await playlist.save();
    return playlist;
  }
}