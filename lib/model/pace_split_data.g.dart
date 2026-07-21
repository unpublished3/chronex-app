// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pace_split_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaceSplitDataAdapter extends TypeAdapter<PaceSplitData> {
  @override
  final int typeId = 2;

  @override
  PaceSplitData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaceSplitData(
      runKey: fields[0] as int,
      splits: (fields[1] as List).cast<double>(),
      percentile: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PaceSplitData obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.runKey)
      ..writeByte(1)
      ..write(obj.splits)
      ..writeByte(2)
      ..write(obj.percentile);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaceSplitDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
