import 'package:hive/hive.dart';

@HiveType(typeId: 3)
class ResultModel extends HiveObject {
  @HiveField(0)
  final String paramName;

  @HiveField(1)
  final String resultValue;

  @HiveField(2)
  final String normalRange;

  @HiveField(3)
  final String unit;

  ResultModel({
    required this.paramName,
    required this.resultValue,
    required this.normalRange,
    required this.unit,
  });

  Map<String, dynamic> toMap() {
    return {
      'paramName': paramName,
      'resultValue': resultValue,
      'normalRange': normalRange,
      'unit': unit,
    };
  }

  factory ResultModel.fromMap(Map<String, dynamic> map) {
    return ResultModel(
      paramName: map['paramName'] ?? '',
      resultValue: map['resultValue'] ?? '',
      normalRange: map['normalRange'] ?? '',
      unit: map['unit'] ?? '',
    );
  }
}

class ResultModelAdapter extends TypeAdapter<ResultModel> {
  @override
  final int typeId = 3;

  @override
  ResultModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ResultModel(
      paramName: fields[0] as String,
      resultValue: fields[1] as String,
      normalRange: fields[2] as String,
      unit: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ResultModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.paramName)
      ..writeByte(1)
      ..write(obj.resultValue)
      ..writeByte(2)
      ..write(obj.normalRange)
      ..writeByte(3)
      ..write(obj.unit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResultModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
