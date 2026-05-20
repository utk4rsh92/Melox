import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:melox/application/providers/player_provider.dart';
import '../../domain/entities/radio_station.dart';
import '../../domain/repositories/radio_repository.dart';
import '../../domain/repositories/radio_repository_impl.dart';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:melox/application/providers/player_provider.dart';
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

// class RadioPlayerNotifier extends Notifier<RadioPlayerState> {
//   late final AudioPlayer _player;
//   bool _isChangingStation = false; // ← track when we're switching stations
//
//   @override
//   RadioPlayerState build() {
//     _player = AudioPlayer();
//     _listenToStreams();
//     ref.onDispose(() => _player.dispose());
//     return const RadioPlayerState();
//   }
//
//   void _listenToStreams() {
//     // 1. Playing state
//     _player.playingStream.listen((playing) {
//       state = state.copyWith(isPlaying: playing);
//     });
//
//     // 2. Processing state — only update buffering, never set error here
//     _player.processingStateStream.listen((ps) {
//       debugPrint('Radio processing state: $ps');
//
//       if (ps == ProcessingState.loading ||
//           ps == ProcessingState.buffering) {
//         state = state.copyWith(isBuffering: true, hasError: false);
//       } else if (ps == ProcessingState.ready) {
//         state = state.copyWith(isBuffering: false, hasError: false);
//       }
//       // ← idle fires on stop/reset — ignore it completely
//       // error is handled only by playbackEventStream below
//     });
//
//     // 3. Only set error from actual playback errors
//     _player.playbackEventStream.listen(
//           (_) {},
//       onError: (Object e, StackTrace st) {
//         // ← Only show error if we're NOT in the middle of switching stations
//         if (!_isChangingStation) {
//           debugPrint('Radio playback error: $e');
//           state = state.copyWith(
//             isBuffering: false,
//             hasError: true,
//             isPlaying: false,
//           );
//         }
//       },
//     );
//   }
//
//   Future<void> playStation(RadioStation station) async {
//     try {
//       _isChangingStation = true; // ← suppress errors during switch
//
//       state = state.copyWith(
//         currentStation: station,
//         isBuffering: true,
//         hasError: false,
//         isPlaying: false,
//       );
//
//       // Stop music player
//       final musicState = ref.read(playerProvider);
//       final musicPlayer = ref.read(playerProvider.notifier);
//       if (musicState.isPlaying) {
//         await musicPlayer.togglePlayPause();
//       }
//
//       await _player.stop();
//
//       var url = station.streamUrl;
//       if (url.isEmpty) {
//         _isChangingStation = false;
//         state = state.copyWith(isBuffering: false, hasError: true);
//         return;
//       }
//
//       if (url.startsWith('http://')) {
//         url = url.replaceFirst('http://', 'https://');
//       }
//
//       debugPrint('Playing radio stream: $url');
//
//       await _player.setAudioSource(
//         AudioSource.uri(
//           Uri.parse(url),
//           tag: MediaItem(
//             id: station.stationUuid,
//             title: station.name,
//             artist: station.genre.isNotEmpty
//                 ? station.genre
//                 : station.country,
//             artUri: station.logoUrl.isNotEmpty &&
//                 station.logoUrl.startsWith('https')
//                 ? Uri.parse(station.logoUrl)
//                 : null,
//             displayTitle: station.name,
//             displaySubtitle: '🔴 LIVE',
//           ),
//         ),
//       );
//
//       _isChangingStation = false; // ← done switching, re-enable error detection
//       await _player.play();
//     } catch (e) {
//       _isChangingStation = false;
//       debugPrint('Radio play error: $e');
//       state = state.copyWith(isBuffering: false, hasError: true);
//     }
//   }
//
//   Future<void> stop() async {
//     _isChangingStation = true; // ← suppress idle error on stop
//     await _player.stop();
//     _isChangingStation = false;
//     state = const RadioPlayerState();
//   }
//
//   Future<void> togglePlayPause() async {
//     if (_player.playing) {
//       await _player.pause();
//     } else {
//       final musicState = ref.read(playerProvider);
//       final musicPlayer = ref.read(playerProvider.notifier);
//       if (musicState.isPlaying) {
//         await musicPlayer.togglePlayPause();
//       }
//       await _player.play();
//     }
//   }
// }

class RadioPlayerNotifier extends Notifier<RadioPlayerState> {
  // ← NO separate AudioPlayer — reuse music player's instance
  AudioPlayer get _player =>
      ref.read(playerProvider.notifier).player;

  @override
  RadioPlayerState build() {
    // ← No player creation here — we use the shared one
    _listenToStreams();
    return const RadioPlayerState();
  }

  void clearStation() {
    state = const RadioPlayerState();
  }
  void _listenToStreams() {
    _player.playingStream.listen((playing) {
      // Only update radio state if radio is active
      if (state.currentStation != null) {
        state = state.copyWith(isPlaying: playing);
      }
    });

    _player.processingStateStream.listen((ps) {
      if (state.currentStation == null) return;
      debugPrint('Radio processing state: $ps');

      if (ps == ProcessingState.loading ||
          ps == ProcessingState.buffering) {
        state = state.copyWith(isBuffering: true, hasError: false);
      } else if (ps == ProcessingState.ready) {
        state = state.copyWith(isBuffering: false, hasError: false);
      }
    });

    _player.playbackEventStream.listen(
          (_) {},
      onError: (Object e, StackTrace st) {
        if (state.currentStation != null) {
          debugPrint('Radio playback error: $e');
          state = state.copyWith(
            isBuffering: false,
            hasError: true,
            isPlaying: false,
          );
        }
      },
    );
  }

  Future<void> playStation(RadioStation station) async {
    try {
      state = state.copyWith(
        currentStation: station,
        isBuffering: true,
        hasError: false,
        isPlaying: false,
      );

      // Stop current music playback
      await _player.stop();

      var url = station.streamUrl;
      if (url.isEmpty) {
        state = state.copyWith(isBuffering: false, hasError: true);
        return;
      }

      if (url.startsWith('http://')) {
        url = url.replaceFirst('http://', 'https://');
      }

      debugPrint('Playing radio stream: $url');

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
    } catch (e) {
      debugPrint('Radio play error: $e');
      state = state.copyWith(isBuffering: false, hasError: true);
    }
  }

  Future<void> stop() async {
    await _player.stop();
    state = const RadioPlayerState();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
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