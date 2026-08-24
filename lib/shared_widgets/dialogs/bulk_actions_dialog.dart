import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

class BulkActionsDialog extends StatefulWidget {
  final List<int> selectedTaskIds;

  const BulkActionsDialog({
    super.key,
    required this.selectedTaskIds,
  });

  static Future<bool?> show(BuildContext context, {required List<int> selectedTaskIds}) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => BulkActionsDialog(selectedTaskIds: selectedTaskIds),
    );
  }

  @override
  State<BulkActionsDialog> createState() => _BulkActionsDialogState();
}

class _BulkActionsDialogState extends State<BulkActionsDialog> {
  final DioClient _dioClient = DioClient();

  String _selectedAction = 'status'; // 'status', 'due', 'reassign'

  // Change Status State
  String _selectedStatus = 'in_progress';
  final Map<String, String> _statusOptions = {
    'in_progress': 'In Progress',
    'completed': 'Completed',
    'to_be_started': 'To be Started',
    'paused': 'Paused',
    'dropped': 'Dropped',
  };

  // Target Date State
  DateTime _selectedDate = DateTime.now();

  // Reassign State
  bool _isLoadingAssignees = false;
  List<dynamic> _assignees = [];
  int? _selectedToUserId;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAssignees();
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

  Future<void> _loadAssignees() async {
    setState(() => _isLoadingAssignees = true);
    try {
      final res = await _dioClient.dio.get(ApiConstants.assignees);
      final data = _safeParse(res.data);
      if (mounted) {
        setState(() {
          if (data is List) {
            _assignees = data;
            if (_assignees.isNotEmpty) {
              _selectedToUserId = _assignees.first['id'] as int? ?? 29;
            }
          }
          _isLoadingAssignees = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAssignees = false);
    }
  }

  Future<void> _applyBulkAction() async {
    if (widget.selectedTaskIds.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      Map<String, dynamic> payload = {
        'ids': widget.selectedTaskIds,
        'action': _selectedAction,
      };

      if (_selectedAction == 'status') {
        payload['status'] = _selectedStatus;
      } else if (_selectedAction == 'due') {
        payload['action'] = 'due';
        payload['dueDate'] = DateFormat('yyyy-MM-dd').format(_selectedDate);
      } else if (_selectedAction == 'reassign') {
        payload['action'] = 'reassign';
        payload['toUserId'] = _selectedToUserId ?? 29;
      }

      await _dioClient.dio.post(
        ApiConstants.tasksBulk,
        data: payload,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk action applied to ${widget.selectedTaskIds.length} task(s) successfully!'),
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
            content: Text('Failed to apply bulk action: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = widget.selectedTaskIds.length;

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
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Bulk actions',
                      style: TextStyle(
                        fontSize: 18,
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
                        '$count tasks',
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
            const SizedBox(height: 12),

            // Action Selection Tabs/Buttons
            const Text(
              'Action',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                _buildActionButton('Change status', 'status'),
                const SizedBox(width: 3),
                _buildActionButton('Set target date', 'due'),
                const SizedBox(width: 3),
                _buildActionButton('Reassign', 'reassign'),
              ],
            ),
            const SizedBox(height: 16),

            // Action Form Details Container
            if (_selectedAction == 'status') ...[
              const Text(
                'New status',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 6),
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
                items: _statusOptions.entries.map((e) {
                  return DropdownMenuItem<String>(
                    value: e.key,
                    child: Text(e.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedStatus = val);
                },
              ),
            ] else if (_selectedAction == 'due') ...[
              const Text(
                'New target date',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ] else if (_selectedAction == 'reassign') ...[
              const Text(
                'Assign all to',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              if (_isLoadingAssignees)
                const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
              else
                DropdownButtonFormField<int>(
                  initialValue: _selectedToUserId,
                  hint: const Text('Select person...', style: TextStyle(fontSize: 12)),
                  isDense: true,
                  isExpanded: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  items: _assignees.map((user) {
                    final id = user['id'] as int? ?? 0;
                    final name = user['name']?.toString() ?? 'User';
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedToUserId = val),
                ),
              const SizedBox(height: 6),
              Text(
                'Replaces existing assignees on each selected task.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),

            // Footer Action Buttons
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
                  onPressed: _isSaving ? null : _applyBulkAction,
                  child: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Apply to $count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, String key) {
    final isSelected = _selectedAction == key;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _selectedAction = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : (isDark ? Colors.white24 : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }
}
