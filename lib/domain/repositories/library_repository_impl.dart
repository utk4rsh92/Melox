// lib/data/repositories/library_repository_impl.dart

import 'package:hive_ce/hive.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../domain/entities/song.dart';
import 'library_repository.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final Box<Song> _songsBox = Hive.box<Song>('songs');

  @override
  Future<bool> requestPermission() async {
    // on_audio_query handles the permission dialog automatically
    // Returns true if granted, false if denied
    return await _audioQuery.permissionsRequest();
  }

  @override
  Future<List<Song>> fetchAllSongs() async {
    // 1. Query device media store for all audio files
    final List<SongModel> deviceSongs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,   // only external storage, not ringtones
      ignoreCase: true,
    );

    // 2. Filter out very short files (ringtones, notifications < 30s)
    final filtered = deviceSongs
        .where((s) => (s.duration ?? 0) > 30000)
        .toList();

    // 3. Map to our domain Song objects, preserving favorites from Hive
    return filtered.map((deviceSong) {
      final song = Song.fromAudioQuery(deviceSong);

      // Check if we already have this song stored with a favorite flag
      final stored = _songsBox.values
          .where((s) => s.id == song.id)
          .firstOrNull;

      // Carry over the favorite state if song was previously stored
      return stored != null
          ? song.copyWith(isFavorite: stored.isFavorite)
          : song;
    }).toList();
  }

  @override
  Future<Song> toggleFavorite(Song song) async {
    final updated = song.copyWith(isFavorite: !song.isFavorite);

    // Persist the updated favorite state to Hive
    // Use song.id as the key so we can look it up later
    await _songsBox.put(song.id, updated);

    return updated;
  }

  @override
  Future<List<Song>> fetchFavorites() async {
    // Only return songs that are explicitly favorited in Hive
    return _songsBox.values
        .where((s) => s.isFavorite)
        .toList();
  }
}