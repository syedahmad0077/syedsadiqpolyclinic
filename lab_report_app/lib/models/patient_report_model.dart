import 'package:hive/hive.dart';
import 'result_model.dart';

@HiveType(typeId: 2)
class PatientReportModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int serialNumber;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String patientName;

  @HiveField(4)
  final String patientAge;

  @HiveField(5)
  final String patientGender;

  @HiveField(6)
  final String testName;

  @HiveField(7)
  final List<ResultModel> results;

  PatientReportModel({
    required this.id,
    required this.serialNumber,
    required this.date,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.testName,
    required this.results,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serialNumber': serialNumber,
      'date': date.toIso8601String(),
      'patientName': patientName,
      'patientAge': patientAge,
      'patientGender': patientGender,
      'testName': testName,
      'results': results.map((r) => r.toMap()).toList(),
    };
  }

  factory PatientReportModel.fromMap(Map<String, dynamic> map) {
    final rawResults = map['results'] as List<dynamic>? ?? [];
    return PatientReportModel(
      id: map['id'] ?? '',
      serialNumber: map['serialNumber'] is int ? map['serialNumber'] : int.tryParse(map['serialNumber']?.toString() ?? '1001') ?? 1001,
      date: map['date'] != null ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now() : DateTime.now(),
      patientName: map['patientName'] ?? '',
      patientAge: map['patientAge'] ?? '',
      patientGender: map['patientGender'] ?? '',
      testName: map['testName'] ?? '',
      results: rawResults
          .map((r) => ResultModel.fromMap(Map<String, dynamic>.from(r)))
          .toList(),
    );
  }
}

class PatientReportModelAdapter extends TypeAdapter<PatientReportModel> {
  @override
  final int typeId = 2;

  @override
  PatientReportModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PatientReportModel(
      id: fields[0] as String,
      serialNumber: fields[1] as int,
      date: fields[2] as DateTime,
      patientName: fields[3] as String,
      patientAge: fields[4] as String,
      patientGender: fields[5] as String,
      testName: fields[6] as String,
      results: (fields[7] as List).cast<ResultModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, PatientReportModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.serialNumber)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.patientName)
      ..writeByte(4)
      ..write(obj.patientAge)
      ..writeByte(5)
      ..write(obj.patientGender)
      ..writeByte(6)
      ..write(obj.testName)
      ..writeByte(7)
      ..write(obj.results);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientReportModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
