
import '../entities/playlist.dart';

abstract class PlaylistRepository {
  Future<List<Playlist>> fetchAllPlaylists();
  Future<Playlist> createPlaylist(String name);
  Future<Playlist> addSongToPlaylist(Playlist playlist, int songId);
  Future<Playlist> removeSongFromPlaylist(Playlist playlist, int songId);
  Future<void> deletePlaylist(Playlist playlist);
  Future<Playlist> renamePlaylist(Playlist playlist, String newName);
}