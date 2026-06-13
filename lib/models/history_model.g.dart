// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HistoryModelAdapter extends TypeAdapter<HistoryModel> {
  @override
  final int typeId = 0;

  @override
  HistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryModel(
      label: fields[0] as String,
      confidence: fields[1] as double,
      date: fields[2] as DateTime,
      imagePath: fields[3] as String?,
      isSynced: fields[4] as bool,
      remoteId: fields[5] as String?,
      maturity: fields[6] as String?,
      condition: fields[7] as String?,
      localUpdatedAt: fields[8] as DateTime?,
      syncedAt: fields[9] as DateTime?,
      id: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.label)
      ..writeByte(1)
      ..write(obj.confidence)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.imagePath)
      ..writeByte(4)
      ..write(obj.isSynced)
      ..writeByte(5)
      ..write(obj.remoteId)
      ..writeByte(6)
      ..write(obj.maturity)
      ..writeByte(7)
      ..write(obj.condition)
      ..writeByte(8)
      ..write(obj.localUpdatedAt)
      ..writeByte(9)
      ..write(obj.syncedAt)
      ..writeByte(10)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
