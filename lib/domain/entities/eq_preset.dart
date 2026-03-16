// lib/domain/entities/eq_preset.dart

import 'package:hive_ce/hive.dart';

part 'eq_preset.g.dart';

@HiveType(typeId: 2)
class EQPreset extends HiveObject {
  @HiveField(0)
  String name;               // "Bass Boost", "Flat", custom name

  @HiveField(1)
  List<int> bandLevels;      // one int per EQ band, in millibels
  // e.g. [300, 0, -200, 400, 100]

  @HiveField(2)
  final bool isBuiltIn;      // built-in presets can't be deleted

  EQPreset({
    required this.name,
    required this.bandLevels,
    this.isBuiltIn = false,
  });

  // Factory: flat preset — all bands at 0
  factory EQPreset.flat() => EQPreset(
    name: 'Flat',
    bandLevels: [0, 0, 0, 0, 0],
    isBuiltIn: true,
  );

  factory EQPreset.bassBoost() => EQPreset(
    name: 'Bass boost',
    bandLevels: [600, 400, 0, -100, -200],
    isBuiltIn: true,
  );

  factory EQPreset.vocal() => EQPreset(
    name: 'Vocal',
    bandLevels: [-200, 0, 400, 300, 0],
    isBuiltIn: true,
  );

  EQPreset copyWith({String? name, List<int>? bandLevels}) {
    return EQPreset(
      name: name ?? this.name,
      bandLevels: bandLevels ?? this.bandLevels,
      isBuiltIn: isBuiltIn,
    );
  }
}