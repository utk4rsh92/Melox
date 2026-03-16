import '../entities/eq_preset.dart';

abstract class EQRepository {
  Future<List<EQPreset>> fetchAllPresets();
  Future<EQPreset> saveCustomPreset(EQPreset preset);
  Future<void> deletePreset(EQPreset preset);
  Future<void> applyPreset(EQPreset preset);
  Future<EQPreset?> getActivePreset();
  Future<void> setActivePreset(EQPreset preset);
}