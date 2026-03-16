// lib/application/providers/library_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
// ❌ REMOVE: import 'package:flutter_riverpod/legacy.dart';

import '../../domain/entities/song.dart';
import 'repository_providers.dart';

final libraryProvider = FutureProvider<List<Song>>((ref) async {
  final repo = ref.watch(libraryRepositoryProvider);
  final granted = await repo.requestPermission();
  if (!granted) return [];
  return repo.fetchAllSongs();
});

final favoritesProvider = FutureProvider<List<Song>>((ref) async {
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.fetchFavorites();
});

class _SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
}

class _ShowFavoritesNotifier extends Notifier<bool> {
  @override
  bool build() => false;
}

final searchQueryProvider = NotifierProvider<_SearchQueryNotifier, String>(
  _SearchQueryNotifier.new,
);

final showFavoritesProvider = NotifierProvider<_ShowFavoritesNotifier, bool>(
  _ShowFavoritesNotifier.new,
);

final filteredSongsProvider = Provider<AsyncValue<List<Song>>>((ref) {
  final songsAsync = ref.watch(libraryProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final showFavorites = ref.watch(showFavoritesProvider); // ← fixed name
  final favoriteIds = ref.watch(favoritesNotifierProvider);

  return songsAsync.whenData((songs) {
    var filtered = songs;

    if (showFavorites) {
      filtered = filtered
          .where((s) => favoriteIds.contains(s.id))
          .toList();
    }

    if (query.isNotEmpty) {
      filtered = filtered.where((s) =>
      s.title.toLowerCase().contains(query) ||
          s.artist.toLowerCase().contains(query) ||
          s.album.toLowerCase().contains(query)
      ).toList();
    }

    return filtered;
  });
});

class FavoritesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    _loadFavorites();
    return {};
  }

  Future<void> _loadFavorites() async {
    final repo = ref.read(libraryRepositoryProvider);
    final favorites = await repo.fetchFavorites();
    state = favorites.map((s) => s.id).toSet();
  }

  Future<void> toggleFavorite(Song song) async {
    final repo = ref.read(libraryRepositoryProvider);
    await repo.toggleFavorite(song);
    if (state.contains(song.id)) {
      state = {...state}..remove(song.id);
    } else {
      state = {...state, song.id};
    }
    ref.invalidate(libraryProvider);
  }

  bool isFavorite(int songId) => state.contains(songId);
}

final favoritesNotifierProvider =
NotifierProvider<FavoritesNotifier, Set<int>>(
  FavoritesNotifier.new,
);