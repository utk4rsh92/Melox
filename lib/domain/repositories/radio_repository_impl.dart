// lib/data/repositories/radio_repository_impl.dart

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/radio_station.dart';
import '../../domain/repositories/radio_repository.dart';

class RadioRepositoryImpl implements RadioRepository {
  final Box<RadioStation> _favoritesBox = Hive.box<RadioStation>('radio_favorites');

  // Use multiple servers for reliability
  static const _servers = [
    'https://de1.api.radio-browser.info',
    'https://nl1.api.radio-browser.info',
    'https://at1.api.radio-browser.info',
  ];

  static const _headers = {
    'User-Agent': 'Melox/1.0.0 (Android)',
    'Content-Type': 'application/json',
  };

  String get _baseUrl => _servers.first;

  Future<List<RadioStation>> _fetch(String endpoint) async {
    for (final server in _servers) {
      try {
        final response = await http
            .get(Uri.parse('$server$endpoint'), headers: _headers)
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          return data
              .map((j) => RadioStation.fromJson(j as Map<String, dynamic>))
              .where((s) => s.streamUrl.isNotEmpty)
              .toList();
        }
      } catch (e) {
        debugPrint('Radio server $server failed: $e');
        continue;
      }
    }
    return [];
  }

  @override
  Future<List<RadioStation>> fetchTopStations({int limit = 30}) async {
    final stations = await _fetch(
      '/json/stations/search'
          '?order=votes'
          '&reverse=true'
          '&limit=$limit'
          '&hidebroken=true'
          '&codec=MP3'
          '&bitrateMin=64'
          '&has_extended_info=true'
          '&url_filter=https', // ← only HTTPS streams
    );
    return _mergeFavorites(stations);
  }

  @override
  Future<List<RadioStation>> fetchByCountry(String country,
      {int limit = 30}) async {
    final encoded = Uri.encodeComponent(country);
    final stations = await _fetch(
      '/json/stations/bycountry/$encoded'
          '?order=votes'
          '&reverse=true'
          '&limit=$limit'
          '&hidebroken=true'
          '&codec=MP3'
          '&bitrateMin=64'
          '&url_filter=https', // ← only HTTPS streams
    );
    return _mergeFavorites(stations);
  }

  @override
  Future<List<RadioStation>> fetchByGenre(String genre,
      {int limit = 30}) async {
    final encoded = Uri.encodeComponent(genre);
    final stations = await _fetch(
      '/json/stations/bytag/$encoded'
          '?order=votes'
          '&reverse=true'
          '&limit=$limit'
          '&hidebroken=true'
          '&codec=MP3'
          '&bitrateMin=64'
          '&url_filter=https', // ← only HTTPS streams
    );
    return _mergeFavorites(stations);
  }

  @override
  Future<List<RadioStation>> search(String query) async {
    final encoded = Uri.encodeComponent(query);
    final stations = await _fetch(
      '/json/stations/search'
          '?name=$encoded'
          '&order=votes'
          '&reverse=true'
          '&limit=30'
          '&hidebroken=true'
          '&url_filter=https', // ← only HTTPS streams
    );
    return _mergeFavorites(stations);
  }

  @override
  Future<List<RadioStation>> fetchFavorites() async {
    return _favoritesBox.values.toList();
  }

  @override
  Future<void> toggleFavorite(RadioStation station) async {
    final existing = _favoritesBox.values
        .where((s) => s.stationUuid == station.stationUuid)
        .firstOrNull;

    if (existing != null) {
      await existing.delete();
    } else {
      station.isFavorite = true;
      await _favoritesBox.add(station);
    }
  }

  // Merge favorite status from Hive into fetched stations
  List<RadioStation> _mergeFavorites(List<RadioStation> stations) {
    final favoriteIds =
    _favoritesBox.values.map((s) => s.stationUuid).toSet();
    for (final s in stations) {
      s.isFavorite = favoriteIds.contains(s.stationUuid);
    }
    return stations;
  }
}