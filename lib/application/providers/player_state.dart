// lib/application/providers/player_state.dart

import 'package:just_audio/just_audio.dart';
import '../../domain/entities/song.dart';

enum RepeatMode { off, one, all }

class MeloxPlayerState {
  final Song? currentSong;
  final List<Song> queue;           // current playback queue
  final int currentIndex;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final RepeatMode repeatMode;
  final bool isShuffled;
  final double volume;              // 0.0 to 1.0

  const MeloxPlayerState({
    this.currentSong,
    this.queue = const [],
    this.currentIndex = 0,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.repeatMode = RepeatMode.off,
    this.isShuffled = false,
    this.volume = 1.0,
  });

  // Convenient helpers used in the UI
  bool get hasPrevious => currentIndex > 0;
  bool get hasNext => currentIndex < queue.length - 1;

  double get progressFraction {
    if (duration.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  String get formattedPosition => _format(position);
  String get formattedDuration => _format(duration);

  String _format(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  MeloxPlayerState copyWith({
    Song? currentSong,
    List<Song>? queue,
    int? currentIndex,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    RepeatMode? repeatMode,
    bool? isShuffled,
    double? volume,
  }) {
    return MeloxPlayerState(
      currentSong:  currentSong  ?? this.currentSong,
      queue:        queue        ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying:    isPlaying    ?? this.isPlaying,
      isBuffering:  isBuffering  ?? this.isBuffering,
      position:     position     ?? this.position,
      duration:     duration     ?? this.duration,
      repeatMode:   repeatMode   ?? this.repeatMode,
      isShuffled:   isShuffled   ?? this.isShuffled,
      volume:       volume       ?? this.volume,
    );
  }
}