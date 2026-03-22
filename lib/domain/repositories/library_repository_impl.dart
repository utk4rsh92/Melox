// lib/data/repositories/library_repository_impl.dart

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:hive_ce/hive.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/media_store_service.dart';
import '../../domain/entities/song.dart';
import 'library_repository.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final Box<Song> _songsBox = Hive.box<Song>('songs');

  @override
  Future<bool> requestPermission() async {
    return await _audioQuery.permissionsRequest();
  }

  @override
  Future<List<Song>> fetchAllSongs() async {
    final List<SongModel> deviceSongs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    final filtered = deviceSongs
        .where((s) => (s.duration ?? 0) > 30000)
        .toList();
    return filtered.map((deviceSong) {
      final song = Song.fromAudioQuery(deviceSong);
      final stored = _songsBox.values
          .where((s) => s.id == song.id)
          .firstOrNull;
      return stored != null
          ? song.copyWith(isFavorite: stored.isFavorite)
          : song;
    }).toList();
  }

  @override
  @override
  Future<bool> deleteSong(Song song) async {
    try {
      // Use MediaStore via MethodChannel — works with content:// URIs
      final deleted = await MediaStoreService.instance.deleteSong(song.id);

      if (!deleted) {
        debugPrint('MediaStore could not delete song id: ${song.id}');
        return false;
      }

      // Remove from Hive favorites if present
      final key = _songsBox.keys.firstWhere(
            (k) => _songsBox.get(k)?.id == song.id,
        orElse: () => null,
      );
      if (key != null) await _songsBox.delete(key);

      debugPrint('Song deleted: ${song.title}');
      return true;
    } catch (e) {
      debugPrint('Failed to delete song: $e');
      return false;
    }
  }
  // Future<bool> deleteSong(Song song) async {
  //   try {
  //     // Step 1 — request permission based on Android version
  //     bool permissionGranted = false;
  //
  //     if (Platform.isAndroid) {
  //       // Try audio permission first (Android 13+)
  //       var status = await Permission.audio.status;
  //       if (!status.isGranted) {
  //         status = await Permission.audio.request();
  //       }
  //
  //       if (status.isGranted) {
  //         permissionGranted = true;
  //       } else {
  //         // Fallback for older Android
  //         var storageStatus = await Permission.storage.status;
  //         if (!storageStatus.isGranted) {
  //           storageStatus = await Permission.storage.request();
  //         }
  //         permissionGranted = storageStatus.isGranted;
  //       }
  //     } else {
  //       permissionGranted = true;
  //     }
  //
  //     if (!permissionGranted) {
  //       debugPrint('Storage permission denied');
  //       return false;
  //     }
  //
  //     // Step 2 — delete file directly
  //     final file = File(song.uri);
  //     if (await file.exists()) {
  //       await file.delete();
  //       debugPrint('File deleted: ${song.uri}');
  //     } else {
  //       debugPrint('File not found: ${song.uri}');
  //       return false;
  //     }
  //
  //     // Step 3 — remove from Hive if stored as favorite
  //     final key = _songsBox.keys.firstWhere(
  //           (k) => _songsBox.get(k)?.id == song.id,
  //       orElse: () => null,
  //     );
  //     if (key != null) {
  //       await _songsBox.delete(key);
  //       debugPrint('Removed from Hive');
  //     }
  //
  //     return true;
  //   } catch (e) {
  //     debugPrint('Failed to delete song: $e');
  //     return false;
  //   }
  // }

  @override
  Future<Song> toggleFavorite(Song song) async {
    final updated = song.copyWith(isFavorite: !song.isFavorite);
    await _songsBox.put(song.id, updated);
    return updated;
  }

  @override
  Future<List<Song>> fetchFavorites() async {
    return _songsBox.values.where((s) => s.isFavorite).toList();
  }
}