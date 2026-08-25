import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../modules/tasks/models/task_model.dart';

class RequestTaskClosureDialog extends StatefulWidget {
  const RequestTaskClosureDialog({super.key});

  static Future<bool?> show(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const RequestTaskClosureDialog(),
    );
  }

  @override
  State<RequestTaskClosureDialog> createState() => _RequestTaskClosureDialogState();
}

class _RequestTaskClosureDialogState extends State<RequestTaskClosureDialog> {
  final DioClient _dioClient = DioClient();
  final TextEditingController _commentController = TextEditingController();

  bool _isLoadingTasks = true;
  List<TaskItemModel> _myTasks = [];
  TaskItemModel? _selectedTask;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadMyTasks();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  dynamic _safeParse(dynamic data) {
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return null;
      }
    }
    return data;
  }

  Future<void> _loadMyTasks() async {
    try {
      final res = await _dioClient.dio.get(
        '${ApiConstants.tasks}',
        queryParameters: {'scope': 'mine', 'limit': 200},
      );
      final data = _safeParse(res.data);
      if (mounted && data is Map<String, dynamic>) {
        final parsed = TasksResponseModel.fromJson(data);
        setState(() {
          _myTasks = parsed.items;
          if (_myTasks.isNotEmpty) {
            _selectedTask = _myTasks.first;
          }
          _isLoadingTasks = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingTasks = false);
    }
  }

  Future<void> _submitClosureRequest() async {
    if (_selectedTask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task * selection is required')),
      );
      return;
    }

    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completion comment * is required')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final payload = {'comment': comment};
      await _dioClient.dio.post(
        '${ApiConstants.tasks}/${_selectedTask!.id}/done',
        data: payload,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task closure requested successfully!'),
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
            content: Text('Failed to submit task closure: $e'),
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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
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
                  'Request task closure',
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

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Alert Info Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                      ),
                      child: Text(
                        'You can\'t close a task yourself — it goes to the task creator, who reviews and completes it.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Task * Dropdown
                    Row(
                      children: const [
                        Text('Task ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text('*', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (_isLoadingTasks)
                      const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                    else if (_myTasks.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('No open tasks available', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      )
                    else
                      DropdownButtonFormField<TaskItemModel>(
                        value: _selectedTask,
                        isDense: true,
                        isExpanded: true,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        items: _myTasks.map((task) {
                          return DropdownMenuItem<TaskItemModel>(
                            value: task,
                            child: Text(
                              '${task.taskNo} — ${task.title}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedTask = val);
                        },
                      ),
                    const SizedBox(height: 14),

                    // Completion comment * Text Field
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
                        hintText: 'What did you complete? Anything the reviewer should know?',
                        hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
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
                  onPressed: _isSaving ? null : _submitClosureRequest,
                  child: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Send for review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
