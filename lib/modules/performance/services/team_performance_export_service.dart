import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, Uint8List;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_strings.dart';
import '../models/team_performance_model.dart';

class TeamPerformanceExportService {
  static Future<void> exportPdf(
    BuildContext context,
    TeamPerformanceModel data,
    AppStrings s,
  ) async {
    try {
      final doc = pw.Document();

      // Load banner.png from assets
      pw.MemoryImage? bannerImage;
      try {
        final byteData = await rootBundle.load('assets/images/banner.png');
        bannerImage = pw.MemoryImage(byteData.buffer.asUint8List());
      } catch (e) {
        debugPrint('[TeamPerformanceExportService] Error loading banner image: $e');
      }

      final totals = data.totals;
      final members = data.members;
      final departments = data.departments;

      final now = DateTime.now();
      final exportedTimestamp = DateFormat('dd/MM/yyyy, HH:mm:ss').format(now);

      // Colors matching screenshot
      const primaryNavy = PdfColor.fromInt(0xFF0F254B);
      const textTeal = PdfColor.fromInt(0xFF0284C7);
      const greyText = PdfColor.fromInt(0xFF64748B);
      const lightBorder = PdfColor.fromInt(0xFFE2E8F0);
      const lightBg = PdfColor.fromInt(0xFFF8FAFC);
      const greenText = PdfColor.fromInt(0xFF16A34A);
      const redText = PdfColor.fromInt(0xFFDC2626);
      const blueText = PdfColor.fromInt(0xFF2563EB);

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          header: (pw.Context ctx) {
            if (ctx.pageNumber > 1) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: lightBorder, width: 0.5)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Team Performance Report — Samskar, The Life School',
                      style: pw.TextStyle(fontSize: 8, color: greyText, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                      style: const pw.TextStyle(fontSize: 8, color: greyText),
                    ),
                  ],
                ),
              );
            }
            return pw.SizedBox.shrink();
          },
          footer: (pw.Context ctx) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(top: 8),
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: lightBorder, width: 0.5)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Exported on $exportedTimestamp · Samskar Task Manager',
                    style: const pw.TextStyle(fontSize: 7.5, color: greyText),
                  ),
                  pw.Text(
                    'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                    style: const pw.TextStyle(fontSize: 7.5, color: greyText),
                  ),
                ],
              ),
            );
          },
          build: (pw.Context ctx) {
            return [
              // 1. Top Logo Banner (Matching Image Exactly)
              pw.Center(
                child: bannerImage != null
                    ? pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: const PdfColor.fromInt(0xFFBFDBFE), width: 1.2),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(14)),
                          color: PdfColors.white,
                        ),
                        child: pw.Image(bannerImage, height: 38),
                      )
                    : pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: const PdfColor.fromInt(0xFFBFDBFE), width: 1.2),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(14)),
                          color: PdfColors.white,
                        ),
                        child: pw.Column(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text(
                              'SAMSKAR',
                              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryNavy),
                            ),
                            pw.Text(
                              'THE LIFE SCHOOL',
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: redText),
                            ),
                            pw.Text(
                              'Education · Ethics · Ethnicity',
                              style: const pw.TextStyle(fontSize: 7, color: greyText),
                            ),
                          ],
                        ),
                      ),
              ),
              pw.SizedBox(height: 8),

              // 2. Report Title & Subtitles
              pw.Center(
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      'Team Performance Report',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryNavy),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '${totals.teamSize} members · ${totals.assigned} assignments · ${totals.done} completed · ${totals.overdue} overdue',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textTeal),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '${members.length} records listed · Exported $exportedTimestamp · Samskar, The Life School',
                      style: const pw.TextStyle(fontSize: 7.5, color: greyText),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // 3. EXECUTIVE SUMMARY • TEAM TOTALS
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: primaryNavy, width: 1.5),
                    bottom: pw.BorderSide(color: primaryNavy, width: 0.5),
                  ),
                ),
                child: pw.Text(
                  'EXECUTIVE SUMMARY • TEAM TOTALS',
                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: primaryNavy, letterSpacing: 0.8),
                ),
              ),
              pw.SizedBox(height: 6),

              // 6 Summary Metric Cards
              pw.Row(
                children: [
                  _buildPdfStatCard('${totals.teamSize}', 'TEAM SIZE', 'members in your scope', primaryNavy),
                  pw.SizedBox(width: 8),
                  _buildPdfStatCard('${totals.assigned}', 'ASSIGNMENTS', 'across all members', blueText),
                  pw.SizedBox(width: 8),
                  _buildPdfStatCard('${totals.done}', 'COMPLETED', '${totals.completion}% completion', greenText),
                  pw.SizedBox(width: 8),
                  _buildPdfStatCard('${totals.inProgress}', 'IN PROGRESS', 'work underway', blueText),
                  pw.SizedBox(width: 8),
                  _buildPdfStatCard('${totals.overdue}', 'OVERDUE', 'needs attention', redText),
                  pw.SizedBox(width: 8),
                  _buildPdfStatCard('${totals.onTime}%', 'ON-TIME %', 'of completed work', greenText),
                ],
              ),
              pw.SizedBox(height: 14),

              // 4. WORKLOAD & DELIVERY DETAILS Section Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: primaryNavy, width: 1.5),
                    bottom: pw.BorderSide(color: primaryNavy, width: 0.5),
                  ),
                ),
                child: pw.Text(
                  'WORKLOAD & DELIVERY DETAILS',
                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: primaryNavy, letterSpacing: 0.8),
                ),
              ),
              pw.SizedBox(height: 4),

              // Workload Table with Exact Columns
              pw.Table(
                border: pw.TableBorder.all(color: lightBorder, width: 0.5),
                columnWidths: const {
                  0: pw.FixedColumnWidth(16),  // #
                  1: pw.FlexColumnWidth(1.4),  // MEMBER
                  2: pw.FlexColumnWidth(1.2),  // ROLE
                  3: pw.FlexColumnWidth(1.3),  // DEPARTMENT
                  4: pw.FixedColumnWidth(34),  // BRANCH
                  5: pw.FixedColumnWidth(26),  // POINTS
                  6: pw.FixedColumnWidth(30),  // ASSIGNED
                  7: pw.FixedColumnWidth(26),  // DONE
                  8: pw.FixedColumnWidth(36),  // COMPLETION %
                  9: pw.FixedColumnWidth(34),  // IN PROGRESS
                  10: pw.FixedColumnWidth(30), // TO START
                  11: pw.FixedColumnWidth(30), // OVERDUE
                  12: pw.FixedColumnWidth(32), // DUE TODAY
                  13: pw.FixedColumnWidth(34), // EMG+HIGH
                  14: pw.FixedColumnWidth(30), // DROPPED
                  15: pw.FixedColumnWidth(34), // ON-TIME %
                  16: pw.FixedColumnWidth(30), // AVG DAYS
                  17: pw.FlexColumnWidth(1.1), // LAST LOGIN
                },
                children: [
                  // Table Header Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: primaryNavy),
                    children: [
                      _buildPdfTableCell('#', isHeader: true),
                      _buildPdfTableCell('MEMBER', isHeader: true),
                      _buildPdfTableCell('ROLE', isHeader: true),
                      _buildPdfTableCell('DEPARTMENT', isHeader: true),
                      _buildPdfTableCell('BRANCH', isHeader: true),
                      _buildPdfTableCell('POINTS', isHeader: true, alignRight: true),
                      _buildPdfTableCell('ASSIGNED', isHeader: true, alignRight: true),
                      _buildPdfTableCell('DONE', isHeader: true, alignRight: true),
                      _buildPdfTableCell('COMPLETION %', isHeader: true, alignRight: true),
                      _buildPdfTableCell('IN PROGRESS', isHeader: true, alignRight: true),
                      _buildPdfTableCell('TO START', isHeader: true, alignRight: true),
                      _buildPdfTableCell('OVERDUE', isHeader: true, alignRight: true),
                      _buildPdfTableCell('DUE TODAY', isHeader: true, alignRight: true),
                      _buildPdfTableCell('EMG+HIGH', isHeader: true, alignRight: true),
                      _buildPdfTableCell('DROPPED', isHeader: true, alignRight: true),
                      _buildPdfTableCell('ON-TIME %', isHeader: true, alignRight: true),
                      _buildPdfTableCell('AVG DAYS', isHeader: true, alignRight: true),
                      _buildPdfTableCell('LAST LOGIN', isHeader: true),
                    ],
                  ),
                  // Table Dynamic Rows
                  ...List.generate(members.length, (idx) {
                    final m = members[idx];
                    final isEven = idx % 2 == 0;
                    final rowBg = isEven ? PdfColors.white : lightBg;
                    final completion = m.assigned > 0 ? ((m.done / m.assigned) * 100).round() : 0;
                    final onTimeStr = m.done > 0 ? '${m.onTime}%' : '—';
                    final avgDaysStr = m.done > 0 ? (m.avgDays == m.avgDays.roundToDouble() ? '${m.avgDays.toInt()}' : m.avgDays.toStringAsFixed(1)) : '0';

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: rowBg),
                      children: [
                        _buildPdfTableCell('${idx + 1}'),
                        _buildPdfTableCell(m.name, bold: true),
                        _buildPdfTableCell(m.role ?? '—'),
                        _buildPdfTableCell(m.department.isNotEmpty ? m.department : '—'),
                        _buildPdfTableCell(m.branchCode ?? '—'),
                        _buildPdfTableCell('${m.points}', alignRight: true),
                        _buildPdfTableCell('${m.assigned}', alignRight: true),
                        _buildPdfTableCell('${m.done}', alignRight: true),
                        _buildPdfTableCell('$completion%', alignRight: true),
                        _buildPdfTableCell('${m.inProgress}', alignRight: true),
                        _buildPdfTableCell('${m.toBeStarted}', alignRight: true),
                        _buildPdfTableCell('${m.overdue}', alignRight: true, textColor: m.overdue > 0 ? redText : null),
                        _buildPdfTableCell('${m.dueToday}', alignRight: true),
                        _buildPdfTableCell('${m.emergencyHighOpen}', alignRight: true, textColor: m.emergencyHighOpen > 0 ? redText : null),
                        _buildPdfTableCell('${m.dropped}', alignRight: true),
                        _buildPdfTableCell(onTimeStr, alignRight: true),
                        _buildPdfTableCell(avgDaysStr, alignRight: true),
                        _buildPdfTableCell(m.lastLogin != null && m.lastLogin!.isNotEmpty ? m.lastLogin! : '—'),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 14),

              // 5. DEPARTMENT BREAKDOWN Section Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: primaryNavy, width: 1.5),
                    bottom: pw.BorderSide(color: primaryNavy, width: 0.5),
                  ),
                ),
                child: pw.Text(
                  'DEPARTMENT BREAKDOWN',
                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: primaryNavy, letterSpacing: 0.8),
                ),
              ),
              pw.SizedBox(height: 4),

              // Department Breakdown Table
              pw.Table(
                border: pw.TableBorder.all(color: lightBorder, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.5), // DEPARTMENT
                  1: pw.FlexColumnWidth(1.0), // MEMBERS
                  2: pw.FlexColumnWidth(1.0), // ASSIGNED
                  3: pw.FlexColumnWidth(1.0), // DONE
                  4: pw.FlexColumnWidth(1.2), // COMPLETION %
                  5: pw.FlexColumnWidth(1.0), // OVERDUE
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: primaryNavy),
                    children: [
                      _buildPdfTableCell('DEPARTMENT', isHeader: true),
                      _buildPdfTableCell('MEMBERS', isHeader: true, alignRight: true),
                      _buildPdfTableCell('ASSIGNED', isHeader: true, alignRight: true),
                      _buildPdfTableCell('DONE', isHeader: true, alignRight: true),
                      _buildPdfTableCell('COMPLETION %', isHeader: true, alignRight: true),
                      _buildPdfTableCell('OVERDUE', isHeader: true, alignRight: true),
                    ],
                  ),
                  ...List.generate(departments.length, (idx) {
                    final d = departments[idx];
                    final isEven = idx % 2 == 0;
                    final rowBg = isEven ? PdfColors.white : lightBg;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: rowBg),
                      children: [
                        _buildPdfTableCell(d.department.isNotEmpty ? d.department : 'Unassigned', bold: true),
                        _buildPdfTableCell('${d.members}', alignRight: true),
                        _buildPdfTableCell('${d.assigned}', alignRight: true),
                        _buildPdfTableCell('${d.done}', alignRight: true),
                        _buildPdfTableCell('${d.completion}%', alignRight: true),
                        _buildPdfTableCell('${d.overdue}', alignRight: true, textColor: d.overdue > 0 ? redText : null),
                      ],
                    );
                  }),
                ],
              ),
            ];
          },
        ),
      );

      // Print / Save PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'Team_Performance_Report_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf',
      );
    } catch (e, stack) {
      debugPrint('[TeamPerformanceExportService] Error exporting PDF: $e\n$stack');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static pw.Widget _buildPdfStatCard(String val, String title, String sub, PdfColor valColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0), width: 0.8),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          color: PdfColors.white,
        ),
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              val,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: valColor),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1E293B)),
            ),
            pw.SizedBox(height: 1),
            pw.Text(
              sub,
              style: const pw.TextStyle(fontSize: 5.5, color: PdfColor.fromInt(0xFF64748B)),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildPdfTableCell(
    String text, {
    bool isHeader = false,
    bool bold = false,
    bool alignRight = false,
    PdfColor? textColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
      alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 5.8 : 5.8,
          fontWeight: (isHeader || bold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : (textColor ?? const PdfColor.fromInt(0xFF0F172A)),
        ),
        maxLines: 1,
      ),
    );
  }

  static Future<void> exportCsv(
    BuildContext context,
    TeamPerformanceModel data,
    AppStrings s,
  ) async {
    try {
      final rows = <List<dynamic>>[];

      // Title & Totals
      rows.add(['Team Performance Report']);
      rows.add(['Exported', DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())]);
      rows.add(['Team Size', data.totals.teamSize]);
      rows.add(['Assignments', data.totals.assigned]);
      rows.add(['Completed', data.totals.done]);
      rows.add(['In Progress', data.totals.inProgress]);
      rows.add(['Overdue', data.totals.overdue]);
      rows.add(['On-Time %', '${data.totals.onTime}%']);
      rows.add([]);

      // Workload Header
      rows.add([
        '#',
        'Member',
        'Role',
        'Department',
        'Branch',
        'Points',
        'Assigned',
        'Done',
        'Completion %',
        'In Progress',
        'To Start',
        'Overdue',
        'Due Today',
        'EMG+High',
        'Dropped',
        'On-Time %',
        'Avg Days',
        'Last Login',
      ]);

      for (int i = 0; i < data.members.length; i++) {
        final m = data.members[i];
        final completion = m.assigned > 0 ? ((m.done / m.assigned) * 100).round() : 0;
        rows.add([
          i + 1,
          m.name,
          m.role ?? '',
          m.department,
          m.branchCode ?? '',
          m.points,
          m.assigned,
          m.done,
          '$completion%',
          m.inProgress,
          m.toBeStarted,
          m.overdue,
          m.dueToday,
          m.emergencyHighOpen,
          m.dropped,
          m.done > 0 ? '${m.onTime}%' : '—',
          m.avgDays,
          m.lastLogin ?? '',
        ]);
      }

      rows.add([]);
      rows.add(['Department Breakdown']);
      rows.add(['Department', 'Members', 'Assigned', 'Done', 'Completion %', 'Overdue']);
      for (final d in data.departments) {
        rows.add([
          d.department,
          d.members,
          d.assigned,
          d.done,
          '${d.completion}%',
          d.overdue,
        ]);
      }

      final String csvData = Csv().encode(rows);
      await Share.share(csvData, subject: 'Team_Performance_Report.csv');
    } catch (e) {
      debugPrint('[TeamPerformanceExportService] Error exporting CSV: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export CSV: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static Future<void> exportExcel(
    BuildContext context,
    TeamPerformanceModel data,
    AppStrings s,
  ) async {
    try {
      final excel = excel_pkg.Excel.createExcel();
      final sheet = excel['Workload & Delivery'];
      excel.setDefaultSheet('Workload & Delivery');

      // Title
      sheet.appendRow([excel_pkg.TextCellValue('Team Performance Report')]);
      sheet.appendRow([excel_pkg.TextCellValue('Exported on: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}')]);
      sheet.appendRow([excel_pkg.TextCellValue('')]);

      // Headers
      sheet.appendRow([
        excel_pkg.TextCellValue('#'),
        excel_pkg.TextCellValue('Member'),
        excel_pkg.TextCellValue('Role'),
        excel_pkg.TextCellValue('Department'),
        excel_pkg.TextCellValue('Branch'),
        excel_pkg.TextCellValue('Points'),
        excel_pkg.TextCellValue('Assigned'),
        excel_pkg.TextCellValue('Done'),
        excel_pkg.TextCellValue('Completion %'),
        excel_pkg.TextCellValue('In Progress'),
        excel_pkg.TextCellValue('To Start'),
        excel_pkg.TextCellValue('Overdue'),
        excel_pkg.TextCellValue('Due Today'),
        excel_pkg.TextCellValue('EMG+High'),
        excel_pkg.TextCellValue('Dropped'),
        excel_pkg.TextCellValue('On-Time %'),
        excel_pkg.TextCellValue('Avg Days'),
        excel_pkg.TextCellValue('Last Login'),
      ]);

      for (int i = 0; i < data.members.length; i++) {
        final m = data.members[i];
        final completion = m.assigned > 0 ? ((m.done / m.assigned) * 100).round() : 0;
        sheet.appendRow([
          excel_pkg.IntCellValue(i + 1),
          excel_pkg.TextCellValue(m.name),
          excel_pkg.TextCellValue(m.role ?? ''),
          excel_pkg.TextCellValue(m.department),
          excel_pkg.TextCellValue(m.branchCode ?? ''),
          excel_pkg.IntCellValue(m.points),
          excel_pkg.IntCellValue(m.assigned),
          excel_pkg.IntCellValue(m.done),
          excel_pkg.TextCellValue('$completion%'),
          excel_pkg.IntCellValue(m.inProgress),
          excel_pkg.IntCellValue(m.toBeStarted),
          excel_pkg.IntCellValue(m.overdue),
          excel_pkg.IntCellValue(m.dueToday),
          excel_pkg.IntCellValue(m.emergencyHighOpen),
          excel_pkg.IntCellValue(m.dropped),
          excel_pkg.TextCellValue(m.done > 0 ? '${m.onTime}%' : '—'),
          excel_pkg.DoubleCellValue(m.avgDays),
          excel_pkg.TextCellValue(m.lastLogin ?? ''),
        ]);
      }

      // Department Sheet
      final deptSheet = excel['Department Breakdown'];
      deptSheet.appendRow([
        excel_pkg.TextCellValue('Department'),
        excel_pkg.TextCellValue('Members'),
        excel_pkg.TextCellValue('Assigned'),
        excel_pkg.TextCellValue('Done'),
        excel_pkg.TextCellValue('Completion %'),
        excel_pkg.TextCellValue('Overdue'),
      ]);
      for (final d in data.departments) {
        deptSheet.appendRow([
          excel_pkg.TextCellValue(d.department),
          excel_pkg.IntCellValue(d.members),
          excel_pkg.IntCellValue(d.assigned),
          excel_pkg.IntCellValue(d.done),
          excel_pkg.TextCellValue('${d.completion}%'),
          excel_pkg.IntCellValue(d.overdue),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final now = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        await Share.shareXFiles(
          [
            XFile.fromData(
              Uint8List.fromList(fileBytes),
              name: 'Team_Performance_Report_$now.xlsx',
              mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          ],
          subject: 'Team_Performance_Report_$now.xlsx',
        );
      }
    } catch (e) {
      debugPrint('[TeamPerformanceExportService] Error exporting Excel: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export Excel: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
