// lib/domain/repositories/radio_repository.dart

import '../entities/radio_station.dart';

abstract class RadioRepository {
  Future<List<RadioStation>> fetchTopStations({int limit = 30});
  Future<List<RadioStation>> fetchByCountry(String country, {int limit = 30});
  Future<List<RadioStation>> fetchByGenre(String genre, {int limit = 30});
  Future<List<RadioStation>> search(String query);
  Future<List<RadioStation>> fetchFavorites();
  Future<void> toggleFavorite(RadioStation station);
}