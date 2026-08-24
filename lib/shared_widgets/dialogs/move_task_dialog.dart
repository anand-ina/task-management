import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../modules/tasks/models/task_model.dart';

class MoveTaskDialog extends StatefulWidget {
  final TaskItemModel task;
  final String? initialStatus;

  const MoveTaskDialog({
    super.key,
    required this.task,
    this.initialStatus,
  });

  static Future<bool?> show(
    BuildContext context, {
    required TaskItemModel task,
    String? initialStatus,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => MoveTaskDialog(
        task: task,
        initialStatus: initialStatus,
      ),
    );
  }

  @override
  State<MoveTaskDialog> createState() => _MoveTaskDialogState();
}

class _MoveTaskDialogState extends State<MoveTaskDialog> {
  final DioClient _dioClient = DioClient();

  late String _selectedStatus;
  late String _selectedPriority;
  late double _progressValue;

  final TextEditingController _blockReasonController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  final List<Map<String, dynamic>> _uploadedAttachments = [];
  bool _isUploading = false;
  bool _isSaving = false;

  final Map<String, String> _statusDisplayMap = {
    'to_be_started': 'To be Started',
    'in_progress': 'In Progress',
    'blocked': 'Blocked',
    'paused': 'Paused',
    'done': 'Done (in review)',
    'completed': 'Completed',
    'postponed': 'Postponed',
    'scrapped': 'Scrapped',
  };

  final Map<String, String> _priorityDisplayMap = {
    'emergency': 'Emergency',
    'top_most': 'Top Most',
    'high': 'High',
    'medium': 'Medium',
    'low': 'Low',
  };

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus ?? (widget.task.status.isNotEmpty ? widget.task.status : 'to_be_started');
    _selectedPriority = widget.task.priority.isNotEmpty ? widget.task.priority.toLowerCase() : 'high';
    _progressValue = widget.task.progress.toDouble();
    if (widget.task.blockReason != null && widget.task.blockReason!.isNotEmpty) {
      _blockReasonController.text = widget.task.blockReason!;
    }
  }

  @override
  void dispose() {
    _blockReasonController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String _formatStatusLabel(String key) {
    return _statusDisplayMap[key.toLowerCase()] ?? key;
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final dynamic result = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (result != null) {
        final List<dynamic> fileList = result is List ? result : (result.files as List);
        if (fileList.isNotEmpty) {
          setState(() {
            for (var file in fileList) {
              String fileName = 'attachment';
              try {
                fileName = (file as dynamic).name?.toString() ?? 'attachment';
              } catch (_) {}

              String? path;
              try {
                path = (file as dynamic).path?.toString();
              } catch (_) {}

              int fileSize = 0;
              try {
                final dynamic bytes = (file as dynamic).bytes;
                if (bytes != null && bytes is List) {
                  fileSize = bytes.length;
                }
              } catch (_) {}

              _uploadedAttachments.add({
                'filename': fileName,
                'url': path ?? '/uploads/${DateTime.now().millisecondsSinceEpoch}-$fileName',
                'mime': 'application/octet-stream',
                'size': fileSize,
              });
            }
          });
        }
      }
    } catch (e) {
      debugPrint('[MoveTaskDialog] File pick error: $e');
    }
  }

  Future<void> _submitMoveTask() async {
    if (_selectedStatus == 'blocked' && _blockReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Block Reason (required) * is mandatory when status is Blocked')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final payload = {
        'status': _selectedStatus,
        'priority': _selectedPriority,
        'progress': _progressValue.round(),
        'blockReason': _selectedStatus == 'blocked' ? _blockReasonController.text.trim() : '',
        'comment': _commentController.text.trim(),
        'mentionIds': [],
        'attachments': _uploadedAttachments,
      };

      await _dioClient.dio.patch(
        '${ApiConstants.tasks}/${widget.task.id}',
        data: payload,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task status updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 540,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header with Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Move Task',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatStatusLabel(_selectedStatus),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task No & Title Header
                    Text(
                      '${widget.task.taskNo} — ${widget.task.title}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // New Status Dropdown
                    const Text('New Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      isDense: true,
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      items: _statusDisplayMap.entries.map((e) {
                        return DropdownMenuItem<String>(
                          value: e.key,
                          child: Text(e.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStatus = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Priority Dropdown
                    const Text('Priority', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPriority,
                      isDense: true,
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      items: _priorityDisplayMap.entries.map((e) {
                        return DropdownMenuItem<String>(
                          value: e.key,
                          child: Text(e.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPriority = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Completion Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Completion:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text('${_progressValue.round()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        activeTrackColor: Colors.blue,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                      ),
                      child: Slider(
                        value: _progressValue,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        onChanged: (val) => setState(() => _progressValue = val),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Conditional Block Reason (Required when status is blocked)
                    if (_selectedStatus == 'blocked') ...[
                      Row(
                        children: const [
                          Text('Block Reason ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                          Text('(required) *', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _blockReasonController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 11),
                        decoration: InputDecoration(
                          hintText: 'What is blocking this task?',
                          hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFF1F2),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.redAccent)),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Comment / Progress Note Text Field
                    const Text('Comment / progress note', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _commentController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        hintText: 'Add an update note... type @ to mention someone',
                        hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Attachments Section
                    const Text('Attachments', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          icon: _isUploading
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.attach_file_rounded, size: 14),
                          label: const Text('📎 Add files', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: _isUploading ? null : _pickAndUploadFile,
                        ),
                      ],
                    ),
                    if (_uploadedAttachments.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _uploadedAttachments.map((att) {
                          return Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(att['filename']?.toString() ?? 'File', style: const TextStyle(fontSize: 10)),
                            onDeleted: () {
                              setState(() => _uploadedAttachments.remove(att));
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Footer Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: _isSaving ? null : _submitMoveTask,
                  child: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Confirm Move', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
