// lib/domain/entities/radio_station.dart

import 'package:hive_ce/hive.dart';

part 'radio_station.g.dart';

@HiveType(typeId: 3)
class RadioStation extends HiveObject {
  @HiveField(0)
  final String stationUuid;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String streamUrl;

  @HiveField(3)
  final String country;

  @HiveField(4)
  final String genre;

  @HiveField(5)
  final String logoUrl;

  @HiveField(6)
  final int votes;

  @HiveField(7)
  bool isFavorite;

  RadioStation({
    required this.stationUuid,
    required this.name,
    required this.streamUrl,
    required this.country,
    required this.genre,
    required this.logoUrl,
    required this.votes,
    this.isFavorite = false,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    // Prefer url_resolved — direct stream URL
    var streamUrl = (json['url_resolved'] as String? ?? '').isNotEmpty
        ? json['url_resolved'] as String
        : json['url'] as String? ?? '';

    // Force HTTPS
    if (streamUrl.startsWith('http://')) {
      streamUrl = streamUrl.replaceFirst('http://', 'https://');
    }

    return RadioStation(
      stationUuid: json['stationuuid'] as String? ?? '',
      name: (json['name'] as String? ?? 'Unknown Station').trim(),
      streamUrl: streamUrl,
      country: json['country'] as String? ?? '',
      genre: (json['tags'] as String? ?? '').split(',').first.trim(),
      logoUrl: json['favicon'] as String? ?? '',
      votes: json['votes'] as int? ?? 0,
    );
  }
}