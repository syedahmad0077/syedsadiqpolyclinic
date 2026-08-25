import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class ParameterModel extends HiveObject {
  @HiveField(0)
  final String paramName;

  @HiveField(1)
  final String normalRange;

  @HiveField(2)
  final String unit;

  ParameterModel({
    required this.paramName,
    required this.normalRange,
    required this.unit,
  });

  Map<String, dynamic> toMap() {
    return {
      'paramName': paramName,
      'normalRange': normalRange,
      'unit': unit,
    };
  }

  factory ParameterModel.fromMap(Map<String, dynamic> map) {
    return ParameterModel(
      paramName: map['paramName'] ?? '',
      normalRange: map['normalRange'] ?? '',
      unit: map['unit'] ?? '',
    );
  }
}

class ParameterModelAdapter extends TypeAdapter<ParameterModel> {
  @override
  final int typeId = 1;

  @override
  ParameterModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ParameterModel(
      paramName: fields[0] as String,
      normalRange: fields[1] as String,
      unit: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ParameterModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.paramName)
      ..writeByte(1)
      ..write(obj.normalRange)
      ..writeByte(2)
      ..write(obj.unit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParameterModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
