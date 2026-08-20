import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

class CreateEventDialog extends StatefulWidget {
  const CreateEventDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const CreateEventDialog(),
    );
  }

  @override
  State<CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<CreateEventDialog> {
  final DioClient _dioClient = DioClient();
  bool _isLoading = true;
  List<dynamic> _branches = [];
  String? _selectedBranch;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _deptTagsController = TextEditingController(text: 'Cultural, Admin, Academics');
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _checklistController = TextEditingController();

  DateTime? _selectedDate;
  final List<String> _checklistItems = [];

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _deptTagsController.dispose();
    _descController.dispose();
    _checklistController.dispose();
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

  Future<void> _loadBranches() async {
    try {
      final res = await _dioClient.dio.get(ApiConstants.branches);
      final data = _safeParse(res.data);
      if (mounted) {
        setState(() {
          if (data is List) _branches = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addChecklistItem() {
    final text = _checklistController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _checklistItems.add(text);
        _checklistController.clear();
      });
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
        padding: const EdgeInsets.all(24),
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
                    const Icon(Icons.star_rounded, size: 20, color: Color(0xFF0F172A)),
                    const SizedBox(width: 6),
                    Text(
                      'New Event',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
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
                      // Title
                      const Text('Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Annual Day 2026',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Date & Branch Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate ?? DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null) setState(() => _selectedDate = picked);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _selectedDate == null
                                              ? 'dd/mm/yyyy'
                                              : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _selectedDate == null ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                                          ),
                                        ),
                                        const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.grey),
                                      ],
                                    ),
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
                                const Text('Branch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedBranch,
                                  hint: const Text('—', style: TextStyle(fontSize: 12)),
                                  isDense: true,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  items: [
                                    const DropdownMenuItem<String>(value: null, child: Text('—')),
                                    ..._branches.map((b) {
                                      final name = b['name']?.toString() ?? 'Head Office';
                                      return DropdownMenuItem(value: name, child: Text(name));
                                    }),
                                  ],
                                  onChanged: (val) => setState(() => _selectedBranch = val),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Department Tags
                      const Text('Department tags (comma-separated)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _deptTagsController,
                        decoration: InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Owner / Lead Dropdown
                      Row(
                        children: [
                          const Text('Owner / Lead ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(
                            '(drives the checklist & submits for review)',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: 'Me (creator)',
                        isDense: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Me (creator)', child: Text('Me (creator)')),
                        ],
                        onChanged: (val) {},
                      ),
                      const SizedBox(height: 14),

                      // Description Text Area
                      const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _descController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Checklist Adder
                      const Text('Checklist', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _checklistController,
                              decoration: InputDecoration(
                                hintText: 'Add a task...',
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onSubmitted: (_) => _addChecklistItem(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.add_rounded),
                            onPressed: _addChecklistItem,
                          ),
                        ],
                      ),
                      if (_checklistItems.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Column(
                          children: _checklistItems.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_box_outline_blank, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(item, style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B132B),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Create Event'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
