// lib/domain/entities/playlist.dart


import 'package:hive_ce_flutter/adapters.dart';

part 'playlist.g.dart';

@HiveType(typeId: 1)
class Playlist extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  List<int> songIds;         // stores Song IDs, not Song objects
  // avoids deep nesting in Hive boxes

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  String? coverUri;          // optional — first song's art, or custom

  Playlist({
    required this.name,
    required this.songIds,
    required this.createdAt,
    this.coverUri,
  });

  // Convenience
  int get songCount => songIds.length;
  bool get isEmpty => songIds.isEmpty;
  bool containsSong(int songId) => songIds.contains(songId);
}