// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anonymous_letter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnonymousLetterAdapter extends TypeAdapter<AnonymousLetter> {
  @override
  final int typeId = 2;

  @override
  AnonymousLetter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnonymousLetter(
      text: fields[0] as String,
    )..createdAt = fields[1] as DateTime;
  }

  @override
  void write(BinaryWriter writer, AnonymousLetter obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnonymousLetterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
