import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../domain/entities/radio_station.dart';
import '../../domain/repositories/radio_repository.dart';
import '../../domain/repositories/radio_repository_impl.dart';

final radioRepositoryProvider = Provider<RadioRepository>(
      (ref) => RadioRepositoryImpl(),
);

class RadioPlayerState {
  final RadioStation? currentStation;
  final bool isPlaying;
  final bool isBuffering;
  final bool hasError;

  const RadioPlayerState({
    this.currentStation,
    this.isPlaying = false,
    this.isBuffering = false,
    this.hasError = false,
  });

  RadioPlayerState copyWith({
    RadioStation? currentStation,
    bool? isPlaying,
    bool? isBuffering,
    bool? hasError,
  }) =>
      RadioPlayerState(
        currentStation: currentStation ?? this.currentStation,
        isPlaying: isPlaying ?? this.isPlaying,
        isBuffering: isBuffering ?? this.isBuffering,
        hasError: hasError ?? this.hasError,
      );
}

class RadioPlayerNotifier extends Notifier<RadioPlayerState> {
  late final AudioPlayer _player;

  @override
  RadioPlayerState build() {
    // ← Create a PLAIN AudioPlayer — NOT wrapped by just_audio_background
    // This avoids the 127.0.0.1 proxy issue entirely
    _player = AudioPlayer();
    _listenToStreams();
    ref.onDispose(() => _player.dispose());
    return const RadioPlayerState();
  }

  void _listenToStreams() {
    _player.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });

    _player.processingStateStream.listen((ps) {
      debugPrint('Radio processing state: $ps');
      state = state.copyWith(
        isBuffering: ps == ProcessingState.buffering ||
            ps == ProcessingState.loading,
      );
      // Only set error if we were actually trying to play
      if (ps == ProcessingState.idle &&
          state.currentStation != null &&
          state.isBuffering) {
        state = state.copyWith(isBuffering: false, hasError: true);
      }
    });

    _player.playerStateStream.listen((ps) {
      debugPrint('Radio player state: $ps');
    });
  }

  Future<void> playStation(RadioStation station) async {
    try {
      state = state.copyWith(
        currentStation: station,
        isBuffering: true,
        hasError: false,
        isPlaying: false,
      );

      await _player.stop();

      var url = station.streamUrl;
      if (url.isEmpty) {
        state = state.copyWith(isBuffering: false, hasError: true);
        return;
      }

      // Force HTTPS
      if (url.startsWith('http://')) {
        url = url.replaceFirst('http://', 'https://');
      }

      debugPrint('Playing radio stream: $url');

      // ← Must use AudioSource.uri with MediaItem tag
      // just_audio_background intercepts ALL AudioPlayer instances
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: station.stationUuid,
            title: station.name,
            artist: station.genre.isNotEmpty
                ? station.genre
                : station.country,
            artUri: station.logoUrl.isNotEmpty &&
                station.logoUrl.startsWith('https')
                ? Uri.parse(station.logoUrl)
                : null,
            displayTitle: station.name,
            displaySubtitle: '🔴 LIVE',
          ),
        ),
      );

      await _player.play();
      state = state.copyWith(isBuffering: false, isPlaying: true);
    } catch (e) {
      debugPrint('Radio play error: $e');
      state = state.copyWith(isBuffering: false, hasError: true);
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    state = const RadioPlayerState();
  }
}

final radioPlayerProvider =
NotifierProvider<RadioPlayerNotifier, RadioPlayerState>(
  RadioPlayerNotifier.new,
);

class _RadioTabNotifier extends Notifier<int> {
  @override
  int build() => 0;
}

class _RadioSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
}

final radioTabProvider = NotifierProvider<_RadioTabNotifier, int>(
  _RadioTabNotifier.new,
);

final radioSearchQueryProvider =
NotifierProvider<_RadioSearchNotifier, String>(
  _RadioSearchNotifier.new,
);

final topStationsProvider = FutureProvider<List<RadioStation>>((ref) async {
  final repo = ref.watch(radioRepositoryProvider);
  return repo.fetchTopStations();
});

final indianStationsProvider =
FutureProvider<List<RadioStation>>((ref) async {
  final repo = ref.watch(radioRepositoryProvider);
  return repo.fetchByCountry('India');
});

final radioFavoritesProvider =
FutureProvider<List<RadioStation>>((ref) async {
  final repo = ref.watch(radioRepositoryProvider);
  return repo.fetchFavorites();
});

final genreStationsProvider =
FutureProvider.family<List<RadioStation>, String>((ref, genre) async {
  final repo = ref.watch(radioRepositoryProvider);
  return repo.fetchByGenre(genre);
});

final radioSearchProvider =
FutureProvider.family<List<RadioStation>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repo = ref.watch(radioRepositoryProvider);
  return repo.search(query);
});