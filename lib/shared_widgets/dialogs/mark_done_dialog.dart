import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../modules/tasks/models/task_model.dart';

class MarkDoneDialog extends StatefulWidget {
  final TaskItemModel task;

  const MarkDoneDialog({
    super.key,
    required this.task,
  });

  static Future<bool?> show(
    BuildContext context, {
    required TaskItemModel task,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => MarkDoneDialog(task: task),
    );
  }

  @override
  State<MarkDoneDialog> createState() => _MarkDoneDialogState();
}

class _MarkDoneDialogState extends State<MarkDoneDialog> {
  final DioClient _dioClient = DioClient();

  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, dynamic>> _uploadedAttachments = [];
  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadFile() async {
    setState(() => _isUploading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    final filename = 'Cercle LOGO PDF (${_uploadedAttachments.length + 1}).pdf';
    if (mounted) {
      setState(() {
        _uploadedAttachments.add({
          'filename': filename,
          'url': '/uploads/${DateTime.now().millisecondsSinceEpoch}-37824.pdf-$filename',
          'mime': 'application/pdf',
          'size': 1383704,
        });
        _isUploading = false;
      });
    }
  }

  Future<void> _submitDoneForReview() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completion comment * is required')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final payload = {
        'comment': comment,
        'mentionIds': [],
        'attachments': _uploadedAttachments,
      };

      await _dioClient.dio.post(
        '${ApiConstants.tasks}/${widget.task.id}/done',
        data: payload,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task submitted for review successfully!'),
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
            content: Text('Failed to submit task for review: $e'),
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
        width: 520,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header with Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mark Done → send for review',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            // Alert Info Banner (Matching Image 3)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
              ),
              child: Text(
                'You can\'t close a task yourself — it goes to the assigner for review, who completes it and awards points.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Completion Comment * Text Field
            Row(
              children: const [
                Text('Completion comment ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text('*', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _commentController,
              maxLines: 3,
              style: const TextStyle(fontSize: 11),
              decoration: InputDecoration(
                hintText: 'What did you complete? Type @ to notify someone.',
                hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),

            // Proof / Attachments Section
            const Text('Proof / attachments', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
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

            const SizedBox(height: 20),
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
                  onPressed: _isSaving ? null : _submitDoneForReview,
                  child: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Submit for review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
