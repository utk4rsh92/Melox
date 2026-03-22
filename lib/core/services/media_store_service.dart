import 'package:flutter/services.dart';

class MediaStoreService {
  static const _channel = MethodChannel('com.musicplay.melox/equalizer');

  static final MediaStoreService instance = MediaStoreService._();
  MediaStoreService._();

  Future<bool> deleteSong(int songId) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'deleteSong',
        {'songId': songId},
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}