// lib/application/providers/eq_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/equalizer_service.dart';
import '../../domain/entities/eq_preset.dart';
import 'repository_providers.dart';

class EQNotifier extends Notifier<EQPreset?> {
  @override
  EQPreset? build() {
    _load();
    return null; // initial state
  }

  Future<void> _load() async {
    final repo = ref.read(eqRepositoryProvider);
    state = await repo.getActivePreset();
  }

  Future<void> selectPreset(EQPreset preset) async {
    final repo = ref.read(eqRepositoryProvider);
    await repo.setActivePreset(preset);
    state = preset;
    for (int i = 0; i < preset.bandLevels.length; i++) {
      await EqualizerService.instance.setBandLevel(i, preset.bandLevels[i]);
    }
  }

  Future<void> saveCustomPreset(EQPreset preset) async {
    final repo = ref.read(eqRepositoryProvider);
    await repo.saveCustomPreset(preset);
  }

  Future<void> deletePreset(EQPreset preset) async {
    final repo = ref.read(eqRepositoryProvider);
    await repo.deletePreset(preset);
    if (state?.name == preset.name) state = null;
  }

  Future<void> updateBandLevel(int bandIndex, int millibels) async {
    if (state == null) return;
    state = state!.copyWith(
      bandLevels: List<int>.from(state!.bandLevels)..[bandIndex] = millibels,
    );
    await EqualizerService.instance.setBandLevel(bandIndex, millibels);
  }
}

final eqProvider = NotifierProvider<EQNotifier, EQPreset?>(
  EQNotifier.new,
);

final eqPresetsProvider = FutureProvider<List<EQPreset>>((ref) async {
  final repo = ref.watch(eqRepositoryProvider);
  return repo.fetchAllPresets();
});