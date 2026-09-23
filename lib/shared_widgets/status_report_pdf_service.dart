import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../modules/reports/models/status_report_model.dart';

/// Generates and prints/downloads a Samskar-branded PDF for a status report.
class StatusReportPdfService {
  StatusReportPdfService._();

  static String _typeLabelFull(String type) {
    switch (type.toLowerCase()) {
      case 'wsr':
        return 'Weekly (WSR)';
      case 'msr':
        return 'Monthly (MSR)';
      default:
        return 'Daily (DSR)';
    }
  }

  static String _formatDate(String? iso, {String pattern = 'd MMM yyyy'}) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      return DateFormat(pattern).format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  static String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      return DateFormat('dd/MM/yyyy, HH:mm').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  /// Generates a Samskar-branded PDF and opens the system print/download dialog.
  static Future<void> generateAndPrint(
    BuildContext context,
    StatusReportItemModel report,
  ) async {
    // Load banner image from assets
    final ByteData bannerData =
        await rootBundle.load('assets/images/banner.png');
    final Uint8List bannerBytes = bannerData.buffer.asUint8List();
    final pw.MemoryImage bannerImage = pw.MemoryImage(bannerBytes);

    final now = DateTime.now();
    final exportedStr = DateFormat('dd/MM/yyyy, HH:mm').format(now);
    final exportedLongStr = DateFormat('dd/MM/yyyy, HH:mm:ss').format(now);
    final typeFull = _typeLabelFull(report.type);
    final periodStr = _formatDate(report.periodDate);
    final statusStr = report.status.toUpperCase();
    final submittedStr = _formatDateTime(report.submittedAt);

    // -------------------------------------------------------------------------
    // Build PDF document
    // -------------------------------------------------------------------------
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Top header row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    exportedStr,
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.orange700,
                    ),
                  ),
                  pw.Text(
                    '$typeFull · $periodStr',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.blue700,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Samskar banner image — centered
              pw.Center(
                child: pw.Container(
                  width: 320,
                  child: pw.Image(bannerImage, fit: pw.BoxFit.contain),
                ),
              ),
              pw.SizedBox(height: 20),

              // Report Title
              pw.Center(
                child: pw.Text(
                  '$typeFull Status Report',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),

              // Period + Status sub-line
              pw.Center(
                child: pw.Text(
                  'Period Date: $periodStr  •  Status: $statusStr  •  Samskar Task Manager',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ),
              pw.SizedBox(height: 8),

              // Horizontal rule
              pw.Divider(color: PdfColors.black, thickness: 1.5),
              pw.SizedBox(height: 12),

              // Section boxes
              _buildSection(
                number: '1',
                label: 'Work Completed',
                content: report.workCompleted ?? '—',
              ),
              pw.SizedBox(height: 10),
              _buildSection(
                number: '2',
                label: 'Work In Progress',
                content: report.workInProgress ?? '—',
              ),
              pw.SizedBox(height: 10),
              _buildSection(
                number: '3',
                label: 'Pending Tasks',
                content: report.pendingTasks ?? '—',
              ),
              pw.SizedBox(height: 10),
              _buildSection(
                number: '4',
                label: 'Challenges / Blockers',
                content: report.challenges ?? '—',
              ),

              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColors.grey400, thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Submitted At: $submittedStr',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Exported on $exportedLongStr  •  Samskar Task Manager',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // -------------------------------------------------------------------------
    // Open system print / download dialog
    // -------------------------------------------------------------------------
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'StatusReport_${report.type.toUpperCase()}_$periodStr.pdf',
    );
  }

  // ---------------------------------------------------------------------------
  // Helper: numbered section box
  // ---------------------------------------------------------------------------
  static pw.Widget _buildSection({
    required String number,
    required String label,
    required String content,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$number. $label',
            style: pw.TextStyle(
              fontSize: 9.5,
              color: PdfColors.grey600,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            content,
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.black),
          ),
        ],
      ),
    );
  }
}
