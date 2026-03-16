// lib/core/services/equalizer_service.dart

import 'package:flutter/services.dart';

class EqualizerService {
  static const _channel = MethodChannel('com.musicplay.melox/equalizer');

  // Singleton
  static final EqualizerService instance = EqualizerService._();
  EqualizerService._();

  Future<bool> init(int audioSessionId) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'init',
        {'audioSessionId': audioSessionId},
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> setBandLevel(int band, int levelMillibels) async {
    try {
      await _channel.invokeMethod(
        'setBandLevel',
        {'band': band, 'level': levelMillibels},
      );
    } catch (_) {}
  }

  Future<int> getNumberOfBands() async {
    try {
      final result = await _channel.invokeMethod<int>('getNumberOfBands');
      return result ?? 5;
    } catch (_) {
      return 5;
    }
  }

  Future<List<int>> getBandLevelRange() async {
    try {
      final result = await _channel.invokeMethod<List>('getBandLevelRange');
      return result?.map((e) => e as int).toList() ?? [-1500, 1500];
    } catch (_) {
      return [-1500, 1500];
    }
  }

  Future<List<int>> getCenterFrequencies() async {
    try {
      final result =
      await _channel.invokeMethod<List>('getCenterFrequencies');
      return result?.map((e) => e as int).toList() ??
          [60, 230, 910, 4000, 14000];
    } catch (_) {
      return [60, 230, 910, 4000, 14000];
    }
  }

  Future<void> setEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setEnabled', {'enabled': enabled});
    } catch (_) {}
  }

  Future<void> release() async {
    try {
      await _channel.invokeMethod('release');
    } catch (_) {}
  }
}