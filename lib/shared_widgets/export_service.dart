import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../modules/tasks/models/task_model.dart';

class ExportService {
  static const String _prefKeyExportDir = 'saved_export_directory';

  /// Saves export file. On first download, prompts user to select a location/folder,
  /// saves that directory in SharedPreferences, and reuses it for future downloads.
  static Future<String?> _saveExportFile({
    required BuildContext context,
    required String defaultFileName,
    required Uint8List bytes,
    required List<String> allowedExtensions,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? savedDir = prefs.getString(_prefKeyExportDir);

    // If a saved directory exists and is valid, write directly to it
    if (savedDir != null && savedDir.isNotEmpty) {
      final dir = Directory(savedDir);
      if (await dir.exists()) {
        final filePath = '${dir.path}/$defaultFileName';
        final file = File(filePath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes);
        return filePath;
      }
    }

    // First time: Prompt user to choose location/directory
    String? targetPath;
    try {
      final dynamic rawPath = await FilePicker.saveFile(
        dialogTitle: 'Select Save Location',
        fileName: defaultFileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );
      if (rawPath != null) {
        targetPath = rawPath is Uri ? rawPath.path : rawPath.toString();
      }
    } catch (e) {
      debugPrint('[ExportService] FilePicker.saveFile fallback: $e');
    }

    if (targetPath == null || targetPath.isEmpty) {
      try {
        final chosenDir = await FilePicker.getDirectoryPath(
          dialogTitle: 'Select Download Folder',
        );
        if (chosenDir != null && chosenDir.isNotEmpty) {
          targetPath = '$chosenDir/$defaultFileName';
          savedDir = chosenDir;
        }
      } catch (e) {
        debugPrint('[ExportService] FilePicker.getDirectoryPath fallback: $e');
      }
    } else {
      savedDir = File(targetPath).parent.path;
    }

    // Default fallback if user cancels
    if (targetPath == null || targetPath.isEmpty) {
      Directory? defaultDir;
      try {
        defaultDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      } catch (_) {
        defaultDir = await getTemporaryDirectory();
      }
      targetPath = '${defaultDir.path}/$defaultFileName';
      savedDir = defaultDir.path;
    }

    // Write file to target path
    final file = File(targetPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);

    // Save directory preference for future exports
    if (savedDir != null && savedDir.isNotEmpty) {
      await prefs.setString(_prefKeyExportDir, savedDir);
      debugPrint('[ExportService] Saved export folder preference: $savedDir');
    }

    return targetPath;
  }

  static Future<void> exportCsv(BuildContext context, List<TaskItemModel> tasks, String title) async {
    try {
      if (tasks.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No tasks available to export.')),
          );
        }
        return;
      }

      final List<List<dynamic>> rows = [
        [
          'Task No',
          'Title',
          'Branch',
          'Priority',
          'Status',
          'Progress %',
          'Assigned By',
          'Assignees',
          'Due Date',
          'Confidential',
        ]
      ];

      for (final task in tasks) {
        final assigneesText = task.assignees.map((e) => e.name).join('; ');
        rows.add([
          task.taskNo,
          task.title,
          task.branchCode.isNotEmpty ? task.branchCode : task.branchName,
          task.priority,
          task.status,
          task.progress,
          task.assignedByName.isNotEmpty ? task.assignedByName : task.assignedByText,
          assigneesText,
          task.dueDate,
          task.isConfidential ? 'Yes' : 'No',
        ]);
      }

      final String csvData = Csv().encode(rows);
      final Uint8List bytes = Uint8List.fromList(utf8.encode(csvData));
      final fileName = '${title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

      final targetPath = await _saveExportFile(
        context: context,
        defaultFileName: fileName,
        bytes: bytes,
        allowedExtensions: ['csv'],
      );

      if (targetPath == null) return;

      debugPrint('[ExportService] CSV saved to: $targetPath');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded CSV: ${targetPath.split('/').last}'),
            backgroundColor: const Color(0xFF16A34A),
            action: SnackBarAction(
              label: 'Change Location',
              textColor: Colors.amber,
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove(_prefKeyExportDir);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Location reset. Next export will prompt for folder.')),
                  );
                }
              },
            ),
          ),
        );
      }

      try {
        await Share.shareXFiles([XFile(targetPath)], text: '$title CSV Export');
      } catch (e) {
        debugPrint('[ExportService] Share fallback error: $e');
      }
    } catch (e, stack) {
      debugPrint('[ExportService] CSV Export error: $e\n$stack');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static Future<void> exportExcel(BuildContext context, List<TaskItemModel> tasks, String title) async {
    try {
      if (tasks.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No tasks available to export.')),
          );
        }
        return;
      }

      final excel = Excel.createExcel();
      final sheetName = title.length > 30 ? title.substring(0, 30) : title;
      final sheet = excel[sheetName];
      excel.setDefaultSheet(sheetName);

      sheet.appendRow([
        TextCellValue('Task No'),
        TextCellValue('Title'),
        TextCellValue('Branch'),
        TextCellValue('Priority'),
        TextCellValue('Status'),
        TextCellValue('Progress %'),
        TextCellValue('Assigned By'),
        TextCellValue('Assignees'),
        TextCellValue('Due Date'),
        TextCellValue('Confidential'),
      ]);

      for (final task in tasks) {
        final assigneesText = task.assignees.map((e) => e.name).join('; ');
        sheet.appendRow([
          TextCellValue(task.taskNo),
          TextCellValue(task.title),
          TextCellValue(task.branchCode.isNotEmpty ? task.branchCode : task.branchName),
          TextCellValue(task.priority),
          TextCellValue(task.status),
          IntCellValue(task.progress),
          TextCellValue(task.assignedByName.isNotEmpty ? task.assignedByName : task.assignedByText),
          TextCellValue(assigneesText),
          TextCellValue(task.dueDate),
          TextCellValue(task.isConfidential ? 'Yes' : 'No'),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final fileName = '${title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

        final targetPath = await _saveExportFile(
          context: context,
          defaultFileName: fileName,
          bytes: Uint8List.fromList(fileBytes),
          allowedExtensions: ['xlsx'],
        );

        if (targetPath == null) return;

        debugPrint('[ExportService] Excel saved to: $targetPath');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded Excel: ${targetPath.split('/').last}'),
              backgroundColor: const Color(0xFF16A34A),
              action: SnackBarAction(
                label: 'Change Location',
                textColor: Colors.amber,
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove(_prefKeyExportDir);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Location reset. Next export will prompt for folder.')),
                    );
                  }
                },
              ),
            ),
          );
        }

        try {
          await Share.shareXFiles([XFile(targetPath)], text: '$title Excel Export');
        } catch (e) {
          debugPrint('[ExportService] Share fallback error: $e');
        }
      }
    } catch (e, stack) {
      debugPrint('[ExportService] Excel Export error: $e\n$stack');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static Future<void> exportPdf(BuildContext context, List<TaskItemModel> tasks, String title) async {
    try {
      if (tasks.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No tasks available to export.')),
          );
        }
        return;
      }

      final pdf = pw.Document();
      final nowStr = DateFormat('dd/MM/yyyy, HH:mm:ss').format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (pw.Context context) {
            return pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(DateFormat('dd/MM/yyyy, HH:mm').format(DateTime.now()), style: const pw.TextStyle(fontSize: 8)),
                pw.Text(title, style: const pw.TextStyle(fontSize: 8)),
              ],
            );
          },
          build: (pw.Context context) {
            return [
              pw.SizedBox(height: 12),
              pw.Text(
                title,
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${tasks.length} row(s) · exported $nowStr',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: [
                  'Task No',
                  'Title',
                  'Branch',
                  'Priority',
                  'Status',
                  'Progress %',
                  'Assigned By',
                  'Assignees',
                  'Due Date',
                  'Confidential',
                ],
                data: tasks.map((task) {
                  final assigneesText = task.assignees.map((e) => e.name).join('; ');
                  return [
                    task.taskNo,
                    task.title,
                    task.branchCode.isNotEmpty ? task.branchCode : task.branchName,
                    task.priority,
                    task.status,
                    '${task.progress}',
                    task.assignedByName.isNotEmpty ? task.assignedByName : task.assignedByText,
                    assigneesText,
                    task.dueDate,
                    task.isConfidential ? 'Yes' : 'No',
                  ];
                }).toList(),
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.grey800),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(5),
              ),
            ];
          },
        ),
      );

      final pdfBytes = await pdf.save();
      final fileName = '${title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      final targetPath = await _saveExportFile(
        context: context,
        defaultFileName: fileName,
        bytes: pdfBytes,
        allowedExtensions: ['pdf'],
      );

      if (targetPath != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded PDF: ${targetPath.split('/').last}'),
            backgroundColor: const Color(0xFF16A34A),
            action: SnackBarAction(
              label: 'Change Location',
              textColor: Colors.amber,
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove(_prefKeyExportDir);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Location reset. Next export will prompt for folder.')),
                  );
                }
              },
            ),
          ),
        );
      }

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: fileName,
      );
    } catch (e, stack) {
      debugPrint('[ExportService] PDF Export error: $e\n$stack');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export PDF failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
