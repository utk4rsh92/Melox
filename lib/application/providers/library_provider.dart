// lib/application/providers/library_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final searchQueryProvider = NotifierProvider<_SearchNotifier, String>(
  _SearchNotifier.new,
);

final showFavoritesProvider = NotifierProvider<_ShowFavNotifier, bool>(
  _ShowFavNotifier.new,
);

// ← ADD THIS — moved from library_screen.dart and made public
final selectedSortProvider = NotifierProvider<_SelectedSortNotifier, int>(
  _SelectedSortNotifier.new,
);

class _SearchNotifier extends Notifier<String> {
  @override String build() => '';
}

class _ShowFavNotifier extends Notifier<bool> {
  @override bool build() => false;
}

class _SelectedSortNotifier extends Notifier<int> {
  @override int build() => 0;
}

final filteredSongsProvider = Provider<AsyncValue<List<Song>>>((ref) {
  final songsAsync = ref.watch(libraryProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final showFavorites = ref.watch(showFavoritesProvider);
  final favoriteIds = ref.watch(favoritesNotifierProvider);
  final sortIndex = ref.watch(selectedSortProvider); // ← watch sort

  return songsAsync.whenData((songs) {
    var filtered = List<Song>.from(songs);

    // Apply favorites filter
    if (showFavorites) {
      filtered = filtered
          .where((s) => favoriteIds.contains(s.id))
          .toList();
    }

    // Apply search query
    if (query.isNotEmpty) {
      filtered = filtered.where((s) =>
      s.title.toLowerCase().contains(query) ||
          s.artist.toLowerCase().contains(query) ||
          s.album.toLowerCase().contains(query)
      ).toList();
    }

    // Apply sort ← THIS WAS MISSING
    switch (sortIndex) {
      case 0: // Title
        filtered.sort((a, b) =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case 1: // Artist
        filtered.sort((a, b) =>
            a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
      case 2: // Album
        filtered.sort((a, b) =>
            a.album.toLowerCase().compareTo(b.album.toLowerCase()));
      case 3: // Date added — sort by id (higher id = newer)
        filtered.sort((a, b) => b.id.compareTo(a.id));
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

  Future<void> deleteSong(Song song) async {
    final repo = ref.read(libraryRepositoryProvider);
    final success = await repo.deleteSong(song);

    if (success) {
      state = {...state}..remove(song.id);
      // ← Delay refresh to avoid QueryArtworkWidget crash
      await Future.delayed(const Duration(milliseconds: 500));
      ref.invalidate(libraryProvider);
    }
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