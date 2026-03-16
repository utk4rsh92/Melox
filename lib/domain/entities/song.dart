

import 'package:hive_ce_flutter/adapters.dart';

part 'song.g.dart';

@HiveType(typeId: 0)
class Song extends HiveObject {
  @HiveField(0)
  final int id;              // from on_audio_query (device media ID)

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String artist;

  @HiveField(3)
  final String album;

  @HiveField(4)
  final String uri;          // file:///storage/... — actual file path

  @HiveField(5)
  final int duration;        // milliseconds

  @HiveField(6)
  final int? size;           // bytes — useful for display

  @HiveField(7)
  final int? dateAdded;      // unix timestamp

  @HiveField(8)
  bool isFavorite;           // mutable — user can toggle

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.uri,
    required this.duration,
    this.size,
    this.dateAdded,
    this.isFavorite = false,
  });

  // Factory: converts on_audio_query's SongModel → our domain Song
  factory Song.fromAudioQuery(dynamic songModel) {
    return Song(
      id: songModel.id,
      title: songModel.title ?? 'Unknown title',
      artist: songModel.artist ?? 'Unknown artist',
      album: songModel.album ?? 'Unknown album',
      uri: songModel.uri ?? '',
      duration: songModel.duration ?? 0,
      size: songModel.size,
      dateAdded: songModel.dateAdded,
    );
  }

  // Formatted duration — e.g. "3:45"
  String get formattedDuration {
    final d = Duration(milliseconds: duration);
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Song copyWith({bool? isFavorite}) {
    return Song(
      id: id,
      title: title,
      artist: artist,
      album: album,
      uri: uri,
      duration: duration,
      size: size,
      dateAdded: dateAdded,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}