import '../entities/song.dart';
abstract class LibraryRepository {
  Future<bool> requestPermission();
  Future<List<Song>> fetchAllSongs();
  Future<Song> toggleFavorite(Song song);
  Future<List<Song>> fetchFavorites();
  Future<bool> deleteSong(Song song); // ← returns bool
}