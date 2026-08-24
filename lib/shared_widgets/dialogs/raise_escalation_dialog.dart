import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../modules/tasks/models/task_model.dart';

class RaiseEscalationDialog extends StatefulWidget {
  const RaiseEscalationDialog({super.key});

  static Future<bool?> show(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const RaiseEscalationDialog(),
    );
  }

  @override
  State<RaiseEscalationDialog> createState() => _RaiseEscalationDialogState();
}

class _RaiseEscalationDialogState extends State<RaiseEscalationDialog> {
  final DioClient _dioClient = DioClient();
  final TextEditingController _reasonController = TextEditingController();

  bool _isLoadingTasks = true;
  List<TaskItemModel> _myTasks = [];
  TaskItemModel? _selectedTask;

  bool _isLoadingRecipients = true;
  List<dynamic> _recipients = [];
  String _selectedEscalateTo = '30';

  String _selectedType = 'date_change'; // 'date_change', 'clarification', 'budget', 'cancellation'
  bool _isSaving = false;

  final Map<String, String> _typeMap = {
    'clarification': 'Clarification / doubt',
    'date_change': 'Target-date change',
    'budget': 'Budget approval',
    'cancellation': 'Cancellation',
  };

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  @override
  void dispose() {
    _reasonController.dispose();
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

  Future<void> _loadLookups() async {
    try {
      final tasksRes = await _dioClient.dio.get(
        '${ApiConstants.tasks}',
        queryParameters: {'scope': 'mine', 'limit': 200},
      );
      final tasksData = _safeParse(tasksRes.data);
      if (tasksData is Map<String, dynamic>) {
        final parsed = TasksResponseModel.fromJson(tasksData);
        _myTasks = parsed.items;
        if (_myTasks.isNotEmpty) _selectedTask = _myTasks.first;
      }

      final recRes = await _dioClient.dio.get('${ApiConstants.baseUrl}/escalations/recipients');
      final recData = _safeParse(recRes.data);
      if (recData is List) {
        _recipients = recData;
        if (_recipients.isNotEmpty) {
          _selectedEscalateTo = _recipients.first['id']?.toString() ?? '30';
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTasks = false;
          _isLoadingRecipients = false;
        });
      }
    }
  }

  Future<void> _submitEscalation() async {
    if (_selectedTask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task * selection is required')),
      );
      return;
    }

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reason * is required')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final proposedDateStr = DateFormat('yyyy-MM-dd').format(
        DateTime.now().add(const Duration(days: 12)),
      );

      final payload = {
        'taskId': _selectedTask!.id,
        'type': _selectedType,
        'reason': reason,
        'escalateTo': _selectedEscalateTo,
        'proposedDate': proposedDateStr,
      };

      await _dioClient.dio.post(
        '${ApiConstants.baseUrl}/escalations',
        data: payload,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Escalation raised successfully!'),
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
            content: Text('Failed to raise escalation: $e'),
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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header with Close Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Raise an escalation',
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
            const SizedBox(height: 8),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 12),

                    // Request type Dropdown
                    const Text('Request type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      isDense: true,
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      items: _typeMap.entries.map((e) {
                        return DropdownMenuItem<String>(
                          value: e.key,
                          child: Text(e.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedType = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Send to Dropdown
                    const Text('Send to', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    if (_isLoadingRecipients)
                      const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                    else
                      DropdownButtonFormField<String>(
                        initialValue: _selectedEscalateTo,
                        isDense: true,
                        isExpanded: true,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: '30',
                            child: Text('Assigner (immediate authority)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          ),
                          ..._recipients.map((rec) {
                            final id = rec['id']?.toString() ?? '1';
                            final name = rec['name']?.toString() ?? 'User';
                            final role = rec['role']?.toString() ?? '';
                            final label = role.isNotEmpty ? '$name ($role)' : name;
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedEscalateTo = val);
                        },
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Pick someone higher to raise over your immediate authority.',
                      style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),

                    // Reason * Text Area
                    Row(
                      children: const [
                        Text('Reason ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text('*', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _reasonController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        hintText: 'Describe your request...',
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
                  onPressed: _isSaving ? null : _submitEscalation,
                  child: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Submit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
