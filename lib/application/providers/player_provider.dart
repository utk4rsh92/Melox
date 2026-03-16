// lib/application/providers/player_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';

import '../../core/services/equalizer_service.dart';
import '../../domain/entities/song.dart';
import 'player_state.dart';

class PlayerNotifier extends Notifier<MeloxPlayerState> {
  late final AudioPlayer _player;

  @override
  MeloxPlayerState build() {
    _player = AudioPlayer();
    _listenToPlayerStreams();
    ref.onDispose(() {
      EqualizerService.instance.release();
      _player.dispose();
    });
    return const MeloxPlayerState();
  }

  void _listenToPlayerStreams() {
    _player.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });

    _player.processingStateStream.listen((processingState) {
      state = state.copyWith(
        isBuffering: processingState == ProcessingState.buffering ||
            processingState == ProcessingState.loading,
      );
      if (processingState == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });

    _player.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    _player.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });

    _player.androidAudioSessionIdStream.listen((sessionId) async {
      if (sessionId != null) {
        await EqualizerService.instance.init(sessionId);
      }
    });

    _player.currentIndexStream.listen((index) {
      if (index != null && index < state.queue.length) {
        state = state.copyWith(
          currentIndex: index,
          currentSong: state.queue[index],
        );
      }
    });
  }

  Future<void> playSong(Song song, {List<Song>? queue}) async {
    final playQueue = queue ?? [song];
    final index = playQueue.indexWhere((s) => s.id == song.id);
    final safeIndex = index == -1 ? 0 : index;

    final audioSource = ConcatenatingAudioSource(
      children: playQueue.map((s) => AudioSource.uri(
        Uri.parse(s.uri),
        tag: MediaItem(
          id: s.id.toString(),
          title: s.title,
          artist: s.artist,
          album: s.album,
          duration: Duration(milliseconds: s.duration),
        ),
      )).toList(),
    );

    await _player.setAudioSource(
      audioSource,
      initialIndex: safeIndex,
      initialPosition: Duration.zero,
    );

    state = state.copyWith(
      queue: playQueue,
      currentIndex: safeIndex,
      currentSong: song,
      position: Duration.zero,
    );

    await _player.play();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> seekToFraction(double fraction) async {
    final ms = (state.duration.inMilliseconds * fraction).round();
    await seekTo(Duration(milliseconds: ms));
  }

  Future<void> skipToNext() async {
    if (state.hasNext) {
      await _player.seekToNext();
    } else if (state.repeatMode == RepeatMode.all) {
      await _player.seek(Duration.zero, index: 0);
      await _player.play();
    }
  }

  Future<void> skipToPrevious() async {
    if (state.position.inSeconds > 3) {
      await seekTo(Duration.zero);
    } else if (state.hasPrevious) {
      await _player.seekToPrevious();
    }
  }

  Future<void> toggleRepeat() async {
    final next = switch (state.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    await _player.setLoopMode(switch (next) {
      RepeatMode.off => LoopMode.off,
      RepeatMode.all => LoopMode.all,
      RepeatMode.one => LoopMode.one,
    });
    state = state.copyWith(repeatMode: next);
  }

  Future<void> toggleShuffle() async {
    final shuffled = !state.isShuffled;
    await _player.setShuffleModeEnabled(shuffled);
    if (shuffled) await _player.shuffle();
    state = state.copyWith(isShuffled: shuffled);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
    state = state.copyWith(volume: volume.clamp(0.0, 1.0));
  }

  void _onTrackCompleted() {
    switch (state.repeatMode) {
      case RepeatMode.one:
        _player.seek(Duration.zero);
        _player.play();
      case RepeatMode.all:
        skipToNext();
      case RepeatMode.off:
        if (state.hasNext) skipToNext();
    }
  }

  AudioPlayer get player => _player;
}

final playerProvider = NotifierProvider<PlayerNotifier, MeloxPlayerState>(
  PlayerNotifier.new,
);

final currentSongIdProvider = Provider<int?>((ref) {
  return ref.watch(playerProvider.select((s) => s.currentSong?.id));
});