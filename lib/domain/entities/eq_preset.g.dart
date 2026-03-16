// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eq_preset.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EQPresetAdapter extends TypeAdapter<EQPreset> {
  @override
  final typeId = 2;

  @override
  EQPreset read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EQPreset(
      name: fields[0] as String,
      bandLevels: (fields[1] as List).cast<int>(),
      isBuiltIn: fields[2] == null ? false : fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, EQPreset obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.bandLevels)
      ..writeByte(2)
      ..write(obj.isBuiltIn);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EQPresetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
