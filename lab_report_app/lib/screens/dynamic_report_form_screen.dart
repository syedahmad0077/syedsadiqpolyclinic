import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import '../models/template_model.dart';
import '../models/patient_report_model.dart';
import '../models/result_model.dart';
import '../services/hive_database_service.dart';
import '../services/pdf_generation_service.dart';
import '../widgets/custom_text_field.dart';
import '../utils/constants.dart';

class DynamicReportFormScreen extends StatefulWidget {
  final TemplateModel selectedTemplate;
  final PatientReportModel? existingReport;

  const DynamicReportFormScreen({
    super.key,
    required this.selectedTemplate,
    this.existingReport,
  });

  @override
  State<DynamicReportFormScreen> createState() => _DynamicReportFormScreenState();
}

class _DynamicReportFormScreenState extends State<DynamicReportFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late int _serialNumber;
  late DateTime _currentDate;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _selectedGender = 'Male';

  final Map<String, TextEditingController> _resultControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.existingReport != null) {
      final rep = widget.existingReport!;
      _serialNumber = rep.serialNumber;
      _currentDate = rep.date;
      _nameController.text = rep.patientName;
      _ageController.text = rep.patientAge;
      _selectedGender = rep.patientGender;

      for (var p in widget.selectedTemplate.parameters) {
        final existingRes = rep.results.firstWhere(
          (r) => r.paramName == p.paramName,
          orElse: () => ResultModel(paramName: p.paramName, resultValue: '', normalRange: p.normalRange, unit: p.unit),
        );
        _resultControllers[p.paramName] = TextEditingController(text: existingRes.resultValue);
      }
    } else {
      _serialNumber = HiveDatabaseService.instance.getNextSerialNumber();
      _currentDate = DateTime.now();

      for (var p in widget.selectedTemplate.parameters) {
        _resultControllers[p.paramName] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _resultControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _saveReportAndOpenPdf() async {
    if (!_formKey.currentState!.validate()) return;

    final List<ResultModel> results = [];
    for (var param in widget.selectedTemplate.parameters) {
      final val = _resultControllers[param.paramName]?.text.trim() ?? '';
      results.add(ResultModel(
        paramName: param.paramName,
        resultValue: val,
        normalRange: param.normalRange,
        unit: param.unit,
      ));
    }

    final report = PatientReportModel(
      id: widget.existingReport?.id ?? const Uuid().v4(),
      serialNumber: _serialNumber,
      date: _currentDate,
      patientName: _nameController.text.trim(),
      patientAge: _ageController.text.trim(),
      patientGender: _selectedGender,
      testName: widget.selectedTemplate.testName,
      results: results,
    );

    // Save to Hive
    await HiveDatabaseService.instance.saveReport(report);

    final pdfBytes = await PdfGenerationService.instance.generateReportPdf(report);

    if (!mounted) return;

    // Show PDF Preview modal dialog with Print, Save, Share
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Report PDF - ${report.patientName} (SSP-${report.serialNumber})'),
        content: SizedBox(
          width: 800,
          height: 600,
          child: PdfPreview(
            build: (format) => pdfBytes,
            allowPrinting: true,
            allowSharing: true,
            initialPageFormat: PdfPageFormat.a4,
            pdfFileName: 'Report_SSP_${report.serialNumber}.pdf',
            actions: [
              PdfPreviewAction(
                icon: const Icon(Icons.share),
                onPressed: (context, build, pageFormat) async {
                  await Share.shareXFiles(
                    [
                      XFile.fromData(
                        pdfBytes,
                        name: 'Report_SSP_${report.serialNumber}.pdf',
                        mimeType: 'application/pdf',
                      ),
                    ],
                    text: 'Laboratory Report for ${report.patientName} - Syed Sadiq Poly Clinic',
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // close modal
              Navigator.pop(context, true); // return to dashboard
            },
            child: const Text('Close & Back to Dashboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MMM-yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.selectedTemplate.testName} Form'),
        backgroundColor: AppConstants.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PATIENT & METADATA SECTION
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Patient Information & Auto-Fields',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.secondaryNavy),
                      ),
                      const Divider(),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: TextEditingController(text: 'SSP-$_serialNumber'),
                              labelText: 'Serial No (Auto-Incremented)',
                              prefixIcon: Icons.confirmation_number,
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              controller: TextEditingController(text: dateFormat.format(_currentDate)),
                              labelText: 'Date (Auto-Current Date)',
                              prefixIcon: Icons.calendar_today,
                              readOnly: true,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: _nameController,
                        labelText: 'Patient Full Name *',
                        prefixIcon: Icons.person,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter patient name' : null,
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _ageController,
                              labelText: 'Patient Age (Years) *',
                              prefixIcon: Icons.cake,
                              keyboardType: TextInputType.number,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter age' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedGender,
                              decoration: const InputDecoration(
                                labelText: 'Gender',
                                prefixIcon: Icon(Icons.wc, color: AppConstants.primaryTeal),
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Male', child: Text('Male')),
                                DropdownMenuItem(value: 'Female', child: Text('Female')),
                                DropdownMenuItem(value: 'Other', child: Text('Other')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedGender = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // DYNAMIC PARAMETERS SECTION
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.selectedTemplate.testName} Parameters',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.secondaryNavy),
                      ),
                      const Divider(),
                      const SizedBox(height: 12),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.selectedTemplate.parameters.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final p = widget.selectedTemplate.parameters[index];
                          final controller = _resultControllers[p.paramName];

                          return Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.paramName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      'Normal Range: ${p.normalRange} (${p.unit})',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: CustomTextField(
                                  controller: controller!,
                                  labelText: 'Result',
                                  suffixText: p.unit,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // SAVE & GENERATE PDF BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saveReportAndOpenPdf,
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: const Text(
                    'Save Patient Report & View PDF',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
