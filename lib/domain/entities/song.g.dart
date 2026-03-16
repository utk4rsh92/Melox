// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SongAdapter extends TypeAdapter<Song> {
  @override
  final typeId = 0;

  @override
  Song read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Song(
      id: (fields[0] as num).toInt(),
      title: fields[1] as String,
      artist: fields[2] as String,
      album: fields[3] as String,
      uri: fields[4] as String,
      duration: (fields[5] as num).toInt(),
      size: (fields[6] as num?)?.toInt(),
      dateAdded: (fields[7] as num?)?.toInt(),
      isFavorite: fields[8] == null ? false : fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Song obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.album)
      ..writeByte(4)
      ..write(obj.uri)
      ..writeByte(5)
      ..write(obj.duration)
      ..writeByte(6)
      ..write(obj.size)
      ..writeByte(7)
      ..write(obj.dateAdded)
      ..writeByte(8)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
