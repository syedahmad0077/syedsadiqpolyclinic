import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/template_model.dart';
import '../models/parameter_model.dart';
import '../models/patient_report_model.dart';
import '../models/result_model.dart';

class HiveDatabaseService {
  static final HiveDatabaseService instance = HiveDatabaseService._internal();
  HiveDatabaseService._internal();

  static const String templatesBoxName = 'templatesBox';
  static const String reportsBoxName = 'reportsBox';
  static const String settingsBoxName = 'settingsBox';

  Box<TemplateModel>? _templatesBox;
  Box<PatientReportModel>? _reportsBox;
  Box? _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();

    // Register TypeAdapters if not registered
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TemplateModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ParameterModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(PatientReportModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ResultModelAdapter());

    _templatesBox = await Hive.openBox<TemplateModel>(templatesBoxName);
    _reportsBox = await Hive.openBox<PatientReportModel>(reportsBoxName);
    _settingsBox = await Hive.openBox(settingsBoxName);

    // Initial Serial Number seed (1000)
    if (!_settingsBox!.containsKey('last_serial')) {
      await _settingsBox!.put('last_serial', 1000);
    }

    // Seed default test templates if empty
    if (_templatesBox!.isEmpty) {
      await _seedDefaultTemplates();
    }
  }

  /// Auto-increment Serial Number logic
  int getNextSerialNumber() {
    if (_reportsBox != null && _reportsBox!.isNotEmpty) {
      int maxSerial = 1000;
      for (var report in _reportsBox!.values) {
        if (report.serialNumber > maxSerial) {
          maxSerial = report.serialNumber;
        }
      }
      return maxSerial + 1;
    }
    final lastSerial = _settingsBox?.get('last_serial', defaultValue: 1000) ?? 1000;
    return lastSerial + 1;
  }

  // --- REPORT CRUD OPERATIONS ---

  Future<void> saveReport(PatientReportModel report) async {
    await _reportsBox?.put(report.id, report);
    if (report.serialNumber >= getNextSerialNumber() - 1) {
      await _settingsBox?.put('last_serial', report.serialNumber);
    }
  }

  List<PatientReportModel> getAllReports() {
    if (_reportsBox == null) return [];
    final reports = _reportsBox!.values.toList();
    reports.sort((a, b) => b.date.compareTo(a.date));
    return reports;
  }

  Future<void> deleteReport(String id) async {
    await _reportsBox?.delete(id);
  }

  // --- TEMPLATE CRUD OPERATIONS ---

  List<TemplateModel> getAllTemplates() {
    if (_templatesBox == null) return [];
    return _templatesBox!.values.toList();
  }

  Future<void> saveTemplate(TemplateModel template) async {
    await _templatesBox?.put(template.id, template);
  }

  Future<void> deleteTemplate(String id) async {
    await _templatesBox?.delete(id);
  }

  // --- DEFAULT SEEDING ---

  Future<void> _seedDefaultTemplates() async {
    const uuid = Uuid();
    final defaults = [
      TemplateModel(
        id: uuid.v4(),
        testName: 'CBC (Complete Blood Count)',
        parameters: [
          ParameterModel(paramName: 'Hemoglobin (Hb)', normalRange: '13.5 - 17.5 g/dL', unit: 'g/dL'),
          ParameterModel(paramName: 'Total Leukocyte Count (TLC)', normalRange: '4,000 - 11,000 /cmm', unit: '/cmm'),
          ParameterModel(paramName: 'RBC Count', normalRange: '4.5 - 5.5 million/cmm', unit: 'm/cmm'),
          ParameterModel(paramName: 'Platelet Count', normalRange: '150,000 - 450,000 /cmm', unit: '/cmm'),
          ParameterModel(paramName: 'Packed Cell Volume (PCV)', normalRange: '40 - 50 %', unit: '%'),
          ParameterModel(paramName: 'MCV', normalRange: '80 - 96 fL', unit: 'fL'),
          ParameterModel(paramName: 'MCH', normalRange: '27 - 33 pg', unit: 'pg'),
          ParameterModel(paramName: 'MCHC', normalRange: '32 - 36 g/dL', unit: 'g/dL'),
        ],
      ),
      TemplateModel(
        id: uuid.v4(),
        testName: 'LFT (Liver Function Test)',
        parameters: [
          ParameterModel(paramName: 'Bilirubin Total', normalRange: '0.2 - 1.2 mg/dL', unit: 'mg/dL'),
          ParameterModel(paramName: 'Bilirubin Direct', normalRange: '0.0 - 0.3 mg/dL', unit: 'mg/dL'),
          ParameterModel(paramName: 'SGPT (ALT)', normalRange: 'Up to 45 U/L', unit: 'U/L'),
          ParameterModel(paramName: 'SGOT (AST)', normalRange: 'Up to 35 U/L', unit: 'U/L'),
          ParameterModel(paramName: 'Alkaline Phosphatase (ALP)', normalRange: '44 - 147 U/L', unit: 'U/L'),
          ParameterModel(paramName: 'Serum Albumin', normalRange: '3.5 - 5.0 g/dL', unit: 'g/dL'),
        ],
      ),
      TemplateModel(
        id: uuid.v4(),
        testName: 'Typhoid Profile',
        parameters: [
          ParameterModel(paramName: 'Typhidot IgM', normalRange: 'Negative', unit: 'Result'),
          ParameterModel(paramName: 'Typhidot IgG', normalRange: 'Negative', unit: 'Result'),
          ParameterModel(paramName: 'Widal S. Typhi O', normalRange: '< 1:80', unit: 'Titre'),
          ParameterModel(paramName: 'Widal S. Typhi H', normalRange: '< 1:80', unit: 'Titre'),
        ],
      ),
      TemplateModel(
        id: uuid.v4(),
        testName: 'Dengue Serology',
        parameters: [
          ParameterModel(paramName: 'Dengue NS1 Antigen', normalRange: 'Negative', unit: 'Result'),
          ParameterModel(paramName: 'Dengue IgM Antibodies', normalRange: 'Negative', unit: 'Result'),
          ParameterModel(paramName: 'Dengue IgG Antibodies', normalRange: 'Negative', unit: 'Result'),
        ],
      ),
    ];

    for (var t in defaults) {
      await saveTemplate(t);
    }
  }
}
