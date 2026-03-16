// lib/data/repositories/eq_repository_impl.dart

import 'package:hive_ce/hive.dart';
import '../../core/services/equalizer_service.dart';
import '../../domain/entities/eq_preset.dart';
import '../../domain/repositories/eq_repository.dart';

class EQRepositoryImpl implements EQRepository {
  final Box<EQPreset> _box = Hive.box<EQPreset>('eq_presets');
  final Box _settings = Hive.box('settings');
  static const String _activePresetKey = 'active_eq_preset_index';

  @override
  Future<List<EQPreset>> fetchAllPresets() async {
    return _box.values.toList();
  }

  @override
  Future<EQPreset> saveCustomPreset(EQPreset preset) async {
    await _box.add(preset);
    return preset;
  }

  @override
  Future<void> deletePreset(EQPreset preset) async {
    if (preset.isBuiltIn) return;
    await preset.delete();
  }

  @override
  Future<void> applyPreset(EQPreset preset) async {
    for (int i = 0; i < preset.bandLevels.length; i++) {
      await EqualizerService.instance.setBandLevel(i, preset.bandLevels[i]);
    }
  }

  @override
  Future<EQPreset?> getActivePreset() async {
    final int? index = _settings.get(_activePresetKey) as int?;
    if (index == null) return null;
    final list = _box.values.toList();
    return (index >= 0 && index < list.length) ? list[index] : null;
  }

  @override
  Future<void> setActivePreset(EQPreset preset) async {
    final index = _box.values.toList().indexOf(preset);
    if (index == -1) return;
    await _settings.put(_activePresetKey, index);
  }

  // Placeholder — will wire up MethodChannel in a later step
  Future<void> openSystemEqualizer(int audioSessionId) async {
    // TODO: implement via MethodChannel
  }
}