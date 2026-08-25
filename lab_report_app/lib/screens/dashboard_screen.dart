import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/template_model.dart';
import '../models/patient_report_model.dart';
import '../services/hive_database_service.dart';
import '../services/pdf_generation_service.dart';
import '../utils/constants.dart';
import 'dynamic_report_form_screen.dart';
import 'template_manager_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<TemplateModel> _templates = [];
  List<PatientReportModel> _allReports = [];
  List<PatientReportModel> _filteredReports = [];

  TemplateModel? _selectedTemplate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _templates = HiveDatabaseService.instance.getAllTemplates();
      _allReports = HiveDatabaseService.instance.getAllReports();
      _filterReports(_searchController.text);
      if (_templates.isNotEmpty && _selectedTemplate == null) {
        _selectedTemplate = _templates.first;
      }
    });
  }

  void _filterReports(String query) {
    if (query.trim().isEmpty) {
      _filteredReports = List.from(_allReports);
    } else {
      final q = query.toLowerCase().trim();
      _filteredReports = _allReports.where((r) {
        return r.patientName.toLowerCase().contains(q) ||
            r.serialNumber.toString().contains(q) ||
            r.testName.toLowerCase().contains(q);
      }).toList();
    }
  }

  Future<void> _openPdfPreview(PatientReportModel report) async {
    final pdfBytes = await PdfGenerationService.instance.generateReportPdf(report);

    if (!mounted) return;

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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
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
        title: const Row(
          children: [
            Icon(Icons.local_hospital, color: Colors.white),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConstants.clinicName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(AppConstants.clinicSubtitle, style: TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ],
        ),
        backgroundColor: AppConstants.primaryTeal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Manage Test Templates',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TemplateManagerScreen()),
              );
              _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Database',
            onPressed: _loadData,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // TOP CONTROLS: SELECT TEST TEMPLATE & START NEW REPORT
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<TemplateModel>(
                        initialValue: _selectedTemplate,
                        decoration: const InputDecoration(
                          labelText: 'Select Test Template (e.g. CBC, LFT, Typhoid)',
                          prefixIcon: Icon(Icons.medical_services, color: AppConstants.primaryTeal),
                          border: OutlineInputBorder(),
                        ),
                        items: _templates.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t.testName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedTemplate = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _selectedTemplate == null
                          ? null
                          : () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DynamicReportFormScreen(selectedTemplate: _selectedTemplate!),
                                ),
                              );
                              _loadData();
                            },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Create Report Form', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryTeal,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // SEARCH BAR
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _filterReports(v)),
              decoration: InputDecoration(
                hintText: 'Search patient reports by name, serial no, or test...',
                prefixIcon: const Icon(Icons.search, color: AppConstants.primaryTeal),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),

            const SizedBox(height: 12),

            // RECENT REPORTS LIST
            Expanded(
              child: _filteredReports.isEmpty
                  ? Center(
                      child: Text(
                        _allReports.isEmpty ? 'No patient reports generated yet.' : 'No matching reports found.',
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredReports.length,
                      itemBuilder: (context, index) {
                        final report = _filteredReports[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppConstants.primaryTeal.withValues(alpha: 0.15),
                              child: Text(
                                '${report.serialNumber}',
                                style: const TextStyle(color: AppConstants.primaryTeal, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                            title: Text(report.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              '${report.testName} • ${report.patientAge} Y / ${report.patientGender} • ${dateFormat.format(report.date)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.picture_as_pdf, color: AppConstants.primaryTeal),
                                  onPressed: () => _openPdfPreview(report),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await HiveDatabaseService.instance.deleteReport(report.id);
                                    _loadData();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
