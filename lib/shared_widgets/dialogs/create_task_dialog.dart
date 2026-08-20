import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

class CreateTaskDialog extends StatefulWidget {
  const CreateTaskDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const CreateTaskDialog(),
    );
  }

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final DioClient _dioClient = DioClient();
  bool _isLoading = true;

  List<dynamic> _branches = [];
  List<dynamic> _assignees = [];
  String? _selectedBranch;
  String _selectedPriority = 'high';
  String _selectedCategory = 'general';
  bool _isRecurring = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final DateTime _selectedDate = DateTime.now();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
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
      final branchesRes = await _dioClient.dio.get(ApiConstants.branches);
      final assigneesRes = await _dioClient.dio.get(ApiConstants.assignees);

      final branchesData = _safeParse(branchesRes.data);
      final assigneesData = _safeParse(assigneesRes.data);

      if (mounted) {
        setState(() {
          if (branchesData is List) _branches = branchesData;
          if (assigneesData is List) _assignees = assigneesData;
          if (_branches.isNotEmpty) {
            _selectedBranch = _branches.first['name']?.toString() ?? 'Head Office';
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
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
        width: 600,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header with Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '+ Create New Task',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task No & Date Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Task No', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                TextField(
                                  enabled: false,
                                  decoration: InputDecoration(
                                    hintText: 'Auto-generated',
                                    isDense: true,
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                TextField(
                                  enabled: false,
                                  decoration: InputDecoration(
                                    hintText: '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                    isDense: true,
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Task Title
                      const Text('Task Title *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Prepare admissions data sheet',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Task Description
                      const Text('Task Description *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _descController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Describe the task in detail...',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Assigned By & School Branch
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Assigned By', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                TextField(
                                  enabled: false,
                                  decoration: InputDecoration(
                                    hintText: 'Vamsi',
                                    isDense: true,
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('School Branch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedBranch,
                                  isDense: true,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  items: _branches.map((b) {
                                    final name = b['name']?.toString() ?? 'Head Office';
                                    return DropdownMenuItem(value: name, child: Text(name));
                                  }).toList(),
                                  onChanged: (val) => setState(() => _selectedBranch = val),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Priority Chips
                      const Text('Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildPriorityChip('emergency', 'Emergency · Act NOW', const Color(0xFFDC2626)),
                          _buildPriorityChip('top_most', 'Top Most · Act Today', const Color(0xFFD97706)),
                          _buildPriorityChip('high', 'High · Act this Week', const Color(0xFF0F172A)),
                          _buildPriorityChip('medium', 'Medium · Schedule to Act', const Color(0xFF7C3AED)),
                          _buildPriorityChip('low', 'Low · When time Permits', const Color(0xFF64748B)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Target Date
                      const Text('Target Date *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_targetDate.day.toString().padLeft(2, '0')}/${_targetDate.month.toString().padLeft(2, '0')}/${_targetDate.year}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.calendar_month_rounded),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _targetDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) setState(() => _targetDate = picked);
                            },
                          ),
                        ],
                      ),
                      const Text(
                        'Auto-set from priority — editable.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),

                      // Category (Confidential vs General)
                      const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedCategory = 'confidential'),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _selectedCategory == 'confidential' ? Colors.red : Colors.grey.shade300,
                                    width: _selectedCategory == 'confidential' ? 2 : 1,
                                  ),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(Icons.lock_outline_rounded, color: Colors.amber, size: 28),
                                    SizedBox(height: 6),
                                    Text('Confidential', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedCategory = 'general'),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _selectedCategory == 'general' ? Colors.red : Colors.grey.shade300,
                                    width: _selectedCategory == 'general' ? 2 : 1,
                                  ),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(Icons.article_outlined, color: Colors.grey, size: 28),
                                    SizedBox(height: 6),
                                    Text('General', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Recurring Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _isRecurring,
                            onChanged: (val) => setState(() => _isRecurring = val ?? false),
                          ),
                          const Text('Make this a recurring task', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text('Assigned To', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        isDense: true,
                        decoration: InputDecoration(
                          hintText: 'Search users...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: _assignees.map((a) {
                          final name = a['name']?.toString() ?? 'Anamika';
                          return DropdownMenuItem(value: name, child: Text(name));
                        }).toList(),
                        onChanged: (val) {},
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B132B),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Save Task'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String key, String label, Color chipColor) {
    final isSelected = _selectedPriority == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : chipColor,
        ),
      ),
      selected: isSelected,
      selectedColor: chipColor,
      backgroundColor: chipColor.withValues(alpha: 0.1),
      onSelected: (val) => setState(() => _selectedPriority = key),
    );
  }
}
