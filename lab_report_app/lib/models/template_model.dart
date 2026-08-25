import 'package:hive/hive.dart';
import 'parameter_model.dart';

@HiveType(typeId: 0)
class TemplateModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String testName;

  @HiveField(2)
  final List<ParameterModel> parameters;

  TemplateModel({
    required this.id,
    required this.testName,
    required this.parameters,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'testName': testName,
      'parameters': parameters.map((p) => p.toMap()).toList(),
    };
  }

  factory TemplateModel.fromMap(Map<String, dynamic> map) {
    final rawParams = map['parameters'] as List<dynamic>? ?? [];
    return TemplateModel(
      id: map['id'] ?? '',
      testName: map['testName'] ?? '',
      parameters: rawParams
          .map((p) => ParameterModel.fromMap(Map<String, dynamic>.from(p)))
          .toList(),
    );
  }
}

class TemplateModelAdapter extends TypeAdapter<TemplateModel> {
  @override
  final int typeId = 0;

  @override
  TemplateModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TemplateModel(
      id: fields[0] as String,
      testName: fields[1] as String,
      parameters: (fields[2] as List).cast<ParameterModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, TemplateModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.testName)
      ..writeByte(2)
      ..write(obj.parameters);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
