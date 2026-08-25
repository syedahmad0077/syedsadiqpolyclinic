import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/patient_report_model.dart';
import '../utils/constants.dart';

class PdfGenerationService {
  static final PdfGenerationService instance = PdfGenerationService._internal();
  PdfGenerationService._internal();

  Future<Uint8List> generateReportPdf(PatientReportModel report) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd-MMM-yyyy hh:mm a');
    final formattedDate = dateFormat.format(report.date);

    const primaryColor = PdfColor.fromInt(0xFF006666);
    const secondaryColor = PdfColor.fromInt(0xFF003366);
    const lightBgColor = PdfColor.fromInt(0xFFF4F9F9);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            cross: pw.CrossAxisAlignment.start,
            children: [
              // CLINIC BRAND HEADER
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: const pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      cross: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          AppConstants.clinicName,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          AppConstants.clinicSubtitle,
                          style: pw.TextStyle(
                            color: PdfColors.teal50,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${AppConstants.clinicAddress} | Tel: ${AppConstants.clinicPhone}',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        'LAB REPORT',
                        style: pw.TextStyle(
                          color: primaryColor,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // PATIENT DEMOGRAPHICS CARD
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: lightBgColor,
                  border: pw.Border.all(color: PdfColors.grey300, width: 1),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  cross: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        cross: pw.CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Patient Name:', report.patientName, isBold: true),
                          pw.SizedBox(height: 4),
                          _buildDetailRow('Age / Gender:', '${report.patientAge} Y / ${report.patientGender}'),
                        ],
                      ),
                    ),
                    pw.Container(width: 1, height: 40, color: PdfColors.grey300),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Column(
                        cross: pw.CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Serial Number:', 'SSP-${report.serialNumber}', isBold: true),
                          pw.SizedBox(height: 4),
                          _buildDetailRow('Report Date:', formattedDate),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // TEST NAME BANNER
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                color: secondaryColor,
                child: pw.Text(
                  report.testName.toUpperCase(),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.SizedBox(height: 8),

              // RESULTS TABLE
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3.5),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(1.5),
                  3: pw.FlexColumnWidth(2.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: primaryColor),
                    children: [
                      _buildTableCell('Test Parameter', isHeader: true),
                      _buildTableCell('Observed Result', isHeader: true),
                      _buildTableCell('Unit', isHeader: true),
                      _buildTableCell('Normal Range', isHeader: true),
                    ],
                  ),
                  ...report.results.asMap().entries.map((entry) {
                    final index = entry.key;
                    final res = entry.value;
                    final isEven = index % 2 == 0;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: isEven ? PdfColors.white : lightBgColor,
                      ),
                      children: [
                        _buildTableCell(res.paramName),
                        _buildTableCell(res.resultValue, isBold: true),
                        _buildTableCell(res.unit),
                        _buildTableCell(res.normalRange),
                      ],
                    );
                  }),
                ],
              ),

              pw.Spacer(),

              // SIGNATURE & FOOTER
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    cross: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 130, height: 1, color: PdfColors.grey400),
                      pw.SizedBox(height: 4),
                      pw.Text('Lab Technologist', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text(AppConstants.clinicName, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    cross: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 130, height: 1, color: PdfColors.grey400),
                      pw.SizedBox(height: 4),
                      pw.Text('Dr. Syed Sadiq', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text('MBBS, FCPS (Pathology)', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 12),

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                ),
                child: pw.Text(
                  'Automated Windows Laboratory Report System • ${AppConstants.clinicName}',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return pw.Row(
      children: [
        pw.Text(
          '$label ',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8.5,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }
}
