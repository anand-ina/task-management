import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../modules/tasks/bloc/bulk_tasks_bloc.dart';
import '../../../modules/tasks/bloc/bulk_tasks_event.dart';
import '../../../modules/tasks/bloc/bulk_tasks_state.dart';

class BulkUploadDialog extends StatelessWidget {
  const BulkUploadDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const BulkUploadDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (_) => BulkTasksBloc()..add(FetchBulkTemplateEvent()),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: 720,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(20),
          child: BlocConsumer<BulkTasksBloc, BulkTasksState>(
            listener: (context, state) {
              if (state is BulkCommitSuccessState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      s.bulkImportSuccess(
                        state.result.imported,
                        state.result.taskNos.join(', '),
                      ),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop(true);
              }
              if (state is BulkTasksErrorState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.upload_rounded, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                s.bulkUploadTasksTitle,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.bulkUploadSubtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Main Content Body
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildDialogBody(context, state, s, isDark),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDialogBody(
    BuildContext context,
    BulkTasksState state,
    AppStrings s,
    bool isDark,
  ) {
    if (state is BulkTasksLoadingState) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state is BulkPreviewLoadedState) {
      return _buildPreviewStateUI(context, state, s, isDark);
    }

    if (state is BulkTemplateLoadedState) {
      return _buildTemplateStateUI(context, state, s, isDark);
    }

    return _buildTemplateStateUI(
      context,
      null,
      s,
      isDark,
    );
  }

  Widget _buildTemplateStateUI(
    BuildContext context,
    BulkTemplateLoadedState? state,
    AppStrings s,
    bool isDark,
  ) {
    final columns = state?.template.columns ?? [];
    final accepted = state?.template.accepted.join(', ') ?? '.xlsx, .xls, .csv';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File Dropzone Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.insert_drive_file_outlined, size: 28, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () => _pickAndUploadFile(context),
                child: Text(
                  s.chooseAFile,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Accepted: $accepted',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Columns the Importer Reads Section Header
        Text(
          s.columnsImporterReads,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 10),

        // Columns Table
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: DataTable(
            headingRowHeight: 26,
            dataRowMinHeight: 30,
            dataRowMaxHeight: 46,
            columnSpacing: 24,
            horizontalMargin: 14,
            columns: [
              DataColumn(label: Text(s.columnHeader, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.bold, color: Colors.grey))),
              DataColumn(label: Text(s.exampleHeader, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey))),
              DataColumn(label: Text(s.notesHeader, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey))),
            ],
            rows: columns.isNotEmpty
                ? columns.map((col) {
                    final isRequired = col.note?.toLowerCase().contains('required') ?? false;
                    return DataRow(
                      cells: [
                        DataCell(Text(
                          col.header,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        )),
                        DataCell(Text(
                          col.example ?? '—',
                          style: TextStyle(fontSize: 9, color: isDark ? Colors.white70 : const Color(0xFF334155)),
                        )),
                        DataCell(Text(
                          col.note ?? '—',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: isRequired ? FontWeight.bold : FontWeight.normal,
                            color: isRequired ? Colors.red : (isDark ? Colors.white54 : Colors.grey.shade600),
                          ),
                        )),
                      ],
                    );
                  }).toList()
                : _buildDefaultTemplateRows(s, isDark),
          ),
        ),
        const SizedBox(height: 20),

        // Footer Cancel Button
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.cancelButton),
          ),
        ),
      ],
    );
  }

  List<DataRow> _buildDefaultTemplateRows(AppStrings s, bool isDark) {
    final defaultCols = [

    ];

    return defaultCols.map((col) {
      final isReq = col['note']!.contains('required');
      return DataRow(
        cells: [
          DataCell(Text(
            col['header']!,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          )),
          DataCell(Text(
            col['example']!,
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF334155)),
          )),
          DataCell(Text(
            col['note']!,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isReq ? FontWeight.bold : FontWeight.normal,
              color: isReq ? Colors.red : (isDark ? Colors.white54 : Colors.grey.shade600),
            ),
          )),
        ],
      );
    }).toList();
  }

  Widget _buildPreviewStateUI(
    BuildContext context,
    BulkPreviewLoadedState state,
    AppStrings s,
    bool isDark,
  ) {
    final preview = state.preview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4 Summary Metric Cards
        Row(
          children: [
            _buildStatCard('${preview.total}', s.rowsFound, isDark, const Color(0xFF2563EB)),
            const SizedBox(width: 10),
            _buildStatCard('${preview.importable}', s.willImport, isDark, const Color(0xFF16A34A)),
            const SizedBox(width: 10),
            _buildStatCard('${preview.skipped}', s.skippedCount, isDark, Colors.grey.shade700),
            const SizedBox(width: 10),
            _buildStatCard('${preview.headerRow}', s.headerRowLabel, isDark, const Color(0xFF2563EB)),
          ],
        ),
        const SizedBox(height: 20),

        // Preview Section Header
        Text(
          s.previewTitle,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 10),

        // Preview Table
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 36,
              dataRowMinHeight: 46,
              dataRowMaxHeight: 54,
              columnSpacing: 18,
              horizontalMargin: 12,
              columns: [
                DataColumn(label: Text(s.rowHeader, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                DataColumn(label: Text(s.taskHeader, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                DataColumn(label: Text(s.assignedToHeader, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                DataColumn(label: Text(s.priorityHeader, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                DataColumn(label: Text(s.statusHeader, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                DataColumn(label: Text(s.targetHeader, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                DataColumn(label: Text(s.branchHeader, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                DataColumn(label: Text(s.noteHeader, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
              ],
              rows: preview.rows.map((row) {
                final assigneeDisplay = row.assigneeNames.isNotEmpty
                    ? row.assigneeNames.join(', ')
                    : (row.assigneeName ?? '—');

                return DataRow(
                  cells: [
                    DataCell(Text('${row.line}', style: const TextStyle(fontSize: 11, color: Colors.grey))),
                    DataCell(Text(
                      row.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    )),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          assigneeDisplay,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(row.priority ?? 'medium', style: const TextStyle(fontSize: 11))),
                    DataCell(Text(row.status ?? 'to_be_started', style: const TextStyle(fontSize: 11))),
                    DataCell(Text(row.dueDate ?? '—', style: const TextStyle(fontSize: 11))),
                    DataCell(Text(row.branchName ?? '—', style: const TextStyle(fontSize: 11))),
                    DataCell(Text(row.remarks ?? '—', style: const TextStyle(fontSize: 11, color: Colors.grey))),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Actions Row
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(s.cancelButton),
            ),
            const SizedBox(width: 2),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => context.read<BulkTasksBloc>().add(ResetBulkUploadEvent()),
              child: Text(s.chooseAnotherFile),
            ),
            const SizedBox(width: 2),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              ),
              onPressed: () {
                context.read<BulkTasksBloc>().add(CommitBulkTasksEvent(rows: preview.rows));
              },
              child: Text(
                s.importTasksCount(preview.importable > 0 ? preview.importable : preview.rows.length),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String val, String label, bool isDark, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              val,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadFile(BuildContext context) async {
    try {
      dynamic result;
      try {
        result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['xlsx', 'xls', 'csv', 'XLSX', 'XLS', 'CSV'],
          withData: true,
        );
      } catch (e) {
        debugPrint('[BulkUploadDialog] Custom pickFiles failed, trying any: $e');
        result = await FilePicker.pickFiles(
          type: FileType.any,
          withData: true,
        );
      }

      List<dynamic> fileList = [];
      if (result != null) {
        if (result is List) {
          fileList = result;
        } else {
          try {
            final dynamic files = result.files;
            if (files is List) {
              fileList = files;
            }
          } catch (_) {}
        }
      }

      if (fileList.isNotEmpty) {
        final dynamic platformFile = fileList.first;
        
        String? targetPath;
        try {
          targetPath = (platformFile as dynamic).path?.toString();
        } catch (_) {}

        String fileName = 'upload_temp.xlsx';
        try {
          final dynamic nameVal = (platformFile as dynamic).name;
          if (nameVal != null && nameVal.toString().isNotEmpty) {
            fileName = nameVal.toString();
          }
        } catch (_) {}

        Uint8List? fileBytes;
        try {
          final dynamic bytesVal = (platformFile as dynamic).bytes;
          if (bytesVal != null) {
            if (bytesVal is Uint8List) {
              fileBytes = bytesVal;
            } else if (bytesVal is List<int>) {
              fileBytes = Uint8List.fromList(bytesVal);
            }
          }
        } catch (_) {}

        // If bytes is null but path is present, read bytes from file path
        if (fileBytes == null && targetPath != null && targetPath.isNotEmpty) {
          try {
            final f = File(targetPath);
            if (await f.exists()) {
              fileBytes = await f.readAsBytes();
            }
          } catch (e) {
            debugPrint('[BulkUploadDialog] File.readAsBytes failed: $e');
          }
        }

        // If path is null (e.g. Android URI scheme or content://), write bytes to temp file
        if ((targetPath == null || targetPath.isEmpty) && fileBytes != null) {
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/$fileName');
          await tempFile.writeAsBytes(fileBytes);
          targetPath = tempFile.path;
        }

        if (targetPath != null && targetPath.isNotEmpty) {
          debugPrint('[BulkUploadDialog] File selected & ready: $targetPath');
          if (context.mounted) {
            context.read<BulkTasksBloc>().add(UploadBulkPreviewEvent(filePath: targetPath));
          }
        } else {
          debugPrint('[BulkUploadDialog] Selected file has no path and no bytes');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selected file could not be read. Please choose a local file.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        debugPrint('[BulkUploadDialog] User cancelled file picker');
      }
    } catch (e, stack) {
      debugPrint('[BulkUploadDialog] Error picking file: $e\n$stack');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
