import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

class ReassignTaskDialog extends StatefulWidget {
  final int taskId;
  final List<dynamic>? currentAssignees;

  const ReassignTaskDialog({
    super.key,
    required this.taskId,
    this.currentAssignees,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int taskId,
    List<dynamic>? currentAssignees,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ReassignTaskDialog(
        taskId: taskId,
        currentAssignees: currentAssignees,
      ),
    );
  }

  @override
  State<ReassignTaskDialog> createState() => _ReassignTaskDialogState();
}

class _ReassignTaskDialogState extends State<ReassignTaskDialog> {
  final DioClient _dioClient = DioClient();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  List<dynamic> _allAssignees = [];
  List<dynamic> _filteredAssignees = [];
  final Set<int> _selectedAssigneeIds = {};

  @override
  void initState() {
    super.initState();
    // Initialize selected assignee IDs from current assignees if available
    if (widget.currentAssignees != null) {
      for (final a in widget.currentAssignees!) {
        if (a is Map && a['id'] is int) {
          _selectedAssigneeIds.add(a['id'] as int);
        } else if (a.id is int) {
          _selectedAssigneeIds.add(a.id as int);
        }
      }
    }
    _fetchAssignees();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  Future<void> _fetchAssignees() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.assignees);
      final parsed = _safeParse(response.data);
      if (parsed is List) {
        if (mounted) {
          setState(() {
            _allAssignees = parsed;
            _filteredAssignees = List.from(parsed);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredAssignees = List.from(_allAssignees);
      } else {
        _filteredAssignees = _allAssignees.where((a) {
          final name = (a['name'] ?? '').toString().toLowerCase();
          return name.contains(q);
        }).toList();
      }
    });
  }

  Color _hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return const Color(0xFF2563EB);
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF2563EB);
    }
  }

  Future<void> _submitReassign() async {
    if (_selectedAssigneeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one assignee.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'assigneeIds': _selectedAssigneeIds.toList(),
      };

      final response = await _dioClient.dio.post(
        '${ApiConstants.tasks}/${widget.taskId}/reassign',
        data: payload,
      );

      if (mounted) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task reassigned successfully.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to reassign task.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isSubmitting = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reassigning task: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_add_alt_1_rounded, size: 20, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Text(
                      'Reassign Task',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: _filter,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Search assignees...',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colors.grey),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Assign To Label & Selected Count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Assign To',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                Text(
                  '${_selectedAssigneeIds.length} selected',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Assignees List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                  : _filteredAssignees.isEmpty
                      ? const Center(
                          child: Text(
                            'No assignees found.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                          ),
                          child: ListView.separated(
                            itemCount: _filteredAssignees.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: isDark ? Colors.white10 : Colors.grey.shade200,
                            ),
                            itemBuilder: (context, index) {
                              final item = _filteredAssignees[index];
                              final id = item['id'] as int? ?? 0;
                              final name = (item['name'] ?? 'User').toString();
                              final initials = (item['initials'] ?? 'U').toString();
                              final colorHex = item['color']?.toString();
                              final badgeColor = _hexToColor(colorHex);
                              final isSelected = _selectedAssigneeIds.contains(id);

                              return CheckboxListTile(
                                value: isSelected,
                                activeColor: const Color(0xFF2563EB),
                                visualDensity: VisualDensity.compact,
                                controlAffinity: ListTileControlAffinity.leading,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedAssigneeIds.add(id);
                                    } else {
                                      _selectedAssigneeIds.remove(id);
                                    }
                                  });
                                },
                                title: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: badgeColor,
                                      child: Text(
                                        initials,
                                        style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
            const SizedBox(height: 16),

            // Footer Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitReassign,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: Text(
                    _isSubmitting ? 'Reassigning...' : 'Reassign',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
