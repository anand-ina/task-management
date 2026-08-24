import 'dart:convert';
import 'package:file_picker/file_picker.dart';
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
  bool _isSaving = false;

  List<dynamic> _branches = [];
  List<dynamic> _assignees = [];
  List<dynamic> _filteredAssignees = [];
  int? _selectedBranchId;
  String _selectedPriority = 'high';
  String _selectedCategory = 'General';
  bool _isRecurring = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _searchAssigneeController = TextEditingController();
  final TextEditingController _checklistController = TextEditingController();

  final DateTime _selectedDate = DateTime.now();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 7));

  final List<int> _selectedAssigneeIds = [];
  final List<Map<String, dynamic>> _checklistItems = [];
  final List<Map<String, dynamic>> _attachments = [];

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _remarksController.dispose();
    _searchAssigneeController.dispose();
    _checklistController.dispose();
    super.dispose();
  }

  Color _parseAvatarColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return const Color(0xFFD97706);
    try {
      final hex = hexColor.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}
    return const Color(0xFFD97706);
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
      await _dioClient.dio.get(ApiConstants.enums);

      final branchesData = _safeParse(branchesRes.data);
      final assigneesData = _safeParse(assigneesRes.data);

      if (mounted) {
        setState(() {
          if (branchesData is List) _branches = branchesData;
          if (assigneesData is List) {
            _assignees = assigneesData;
            _filteredAssignees = List.from(assigneesData);
          }
          if (_branches.isNotEmpty) {
            _selectedBranchId = _branches.first['id'] as int? ?? 1;
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

  void _filterAssignees(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAssignees = List.from(_assignees);
      } else {
        _filteredAssignees = _assignees.where((a) {
          final name = a['name']?.toString().toLowerCase() ?? '';
          final dept = a['department']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) || dept.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _submitTask() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Task Title and Description')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final payload = {
        'title': title,
        'description': desc,
        'branchId': _selectedBranchId ?? 1,
        'priority': _selectedPriority,
        'category': _selectedCategory,
        'dueDate': '${_targetDate.year}-${_targetDate.month.toString().padLeft(2, '0')}-${_targetDate.day.toString().padLeft(2, '0')}',
        'remarks': _remarksController.text.isNotEmpty ? _remarksController.text.trim() : 'no',
        'assigneeIds': _selectedAssigneeIds.isNotEmpty ? _selectedAssigneeIds : [20],
        'checklist': _checklistItems,
        'attachments': _attachments,
        'isRecurring': _isRecurring,
      };

      await _dioClient.dio.post(ApiConstants.tasks, data: payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showUploadFileDialog() async {
    try {
      dynamic result;
      try {
        result = await FilePicker.pickFiles(
          type: FileType.any,
          withData: true,
          allowMultiple: true,
        );
      } catch (e) {
        debugPrint('[CreateTaskDialog] pickFiles withData failed, trying standard pick: $e');
        result = await FilePicker.pickFiles(
          type: FileType.any,
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
        setState(() {
          for (final dynamic file in fileList) {
            final String fileName = file.name?.toString() ?? 'attachment';
            final int fileSize = file.size is int ? file.size as int : 0;
            final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
            _attachments.add({
              'filename': fileName,
              'url': file.path?.toString() ?? '/uploads/${DateTime.now().millisecondsSinceEpoch}-$fileName',
              'mime': _getMimeType(ext),
              'size': fileSize,
            });
          }
        });
      }
    } catch (e) {
      debugPrint('[CreateTaskDialog] File pick error: $e');
      if (mounted) {
        _showManualFileNameDialog();
      }
    }
  }

  void _showManualFileNameDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Add File Attachment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter Attachment Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'e.g., Report.pdf or Screenshot.png',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 11)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final fname = nameCtrl.text.trim();
              if (fname.isNotEmpty) {
                final ext = fname.contains('.') ? fname.split('.').last.toLowerCase() : '';
                setState(() {
                  _attachments.add({
                    'filename': fname,
                    'url': '/uploads/${DateTime.now().millisecondsSinceEpoch}-$fname',
                    'mime': _getMimeType(ext),
                    'size': 1024 * 250,
                  });
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add Attachment', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'csv':
        return 'text/csv';
      default:
        return 'application/octet-stream';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 680,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
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
                                const Text('Assigned By', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                TextField(
                                  enabled: false,
                                  style: const TextStyle(fontSize: 11),
                                  decoration: InputDecoration(
                                    hintText: 'Test_AE',
                                    hintStyle: const TextStyle(fontSize: 11),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                                const Text('School Branch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<int>(
                                  initialValue: _selectedBranchId,
                                  isDense: true,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  items: _branches.map((b) {
                                    final id = b['id'] as int? ?? 1;
                                    final name = b['name']?.toString() ?? 'Head Office';
                                    return DropdownMenuItem<int>(
                                      value: id,
                                      child: Text(
                                        name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setState(() => _selectedBranchId = val),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Priority Chips
                      const Text('Priority', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildPriorityChip('emergency', 'Emergency · Act NOW', const Color(0xFFDC2626)),
                          _buildPriorityChip('top_most', 'Top Most · Act Today', const Color(0xFFD97706)),
                          _buildPriorityChip('high', 'High · Act this Week', const Color(0xFF0F172A)),
                          _buildPriorityChip('medium', 'Medium · Schedule to Act', const Color(0xFF7C3AED)),
                          _buildPriorityChip('low', 'Low · When time Permits', const Color(0xFF64748B)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Target Date
                      const Text('Target Date *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${_targetDate.day.toString().padLeft(2, '0')}/${_targetDate.month.toString().padLeft(2, '0')}/${_targetDate.year}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.calendar_month_rounded, size: 20),
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
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),

                      // Category Cards (Confidential vs General)
                      const Text('Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedCategory = 'Confidential'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _selectedCategory == 'Confidential'
                                          ? const Color(0xFFDC2626).withValues(alpha: 0.2)
                                          : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: _selectedCategory == 'Confidential'
                                      ? Border.all(color: const Color(0xFFDC2626), width: 1.5)
                                      : null,
                                ),
                                child: const Column(
                                  children: [
                                    Text('🔒', style: TextStyle(fontSize: 20)),
                                    SizedBox(height: 4),
                                    Text('Confidential', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedCategory = 'General'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _selectedCategory == 'General'
                                          ? const Color(0xFFDC2626).withValues(alpha: 0.2)
                                          : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: _selectedCategory == 'General'
                                      ? Border.all(color: const Color(0xFFDC2626), width: 1.5)
                                      : null,
                                ),
                                child: const Column(
                                  children: [
                                    Text('📄', style: TextStyle(fontSize: 20)),
                                    SizedBox(height: 4),
                                    Text('General', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Make this a recurring task Checkbox
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _isRecurring,
                              activeColor: const Color(0xFF0F172A),
                              onChanged: (val) => setState(() => _isRecurring = val ?? false),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('Make this a recurring task', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Assigned To Section (Dynamic Groups matching Screenshot)
                      const Text('Assigned To', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _searchAssigneeController,
                        onChanged: _filterAssignees,
                        style: const TextStyle(fontSize: 11),
                        decoration: InputDecoration(
                          hintText: 'Search users...',
                          hintStyle: const TextStyle(fontSize: 11),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          prefixIcon: const Icon(Icons.search, size: 16),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Dynamic Groups Chips
                      const Text('GROUPS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Builder(
                        builder: (context) {
                          // Dynamic group map calculation
                          final Map<String, List<int>> groupDeptMap = {};
                          for (var a in _assignees) {
                            final dept = a['department']?.toString() ?? 'Other';
                            final id = a['id'] as int? ?? 0;
                            if (id != 0) {
                              groupDeptMap.putIfAbsent(dept, () => []).add(id);
                            }
                          }

                          if (groupDeptMap.isEmpty) {
                            groupDeptMap['Administration'] = [6, 10, 14, 20];
                            groupDeptMap['Admission Counselling'] = [12];
                            groupDeptMap['Other'] = [15, 18, 22, 25];
                          }

                          return Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: groupDeptMap.entries.map((entry) {
                              final deptName = entry.key;
                              final memberIds = entry.value;
                              final count = memberIds.length;

                              return ActionChip(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                label: Text('+ $deptName ($count)', style: const TextStyle(fontSize: 10)),
                                onPressed: () {
                                  setState(() {
                                    for (var id in memberIds) {
                                      if (!_selectedAssigneeIds.contains(id)) {
                                        _selectedAssigneeIds.add(id);
                                      }
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 8),

                      // Split Columns for Pick Users & Selected Users (Scrollable SELECTED Container)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left User Picker List
                          Expanded(
                            child: Container(
                              height: 160,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListView.builder(
                                itemCount: _filteredAssignees.length,
                                itemBuilder: (context, index) {
                                  final user = _filteredAssignees[index];
                                  final id = user['id'] as int? ?? 0;
                                  final name = user['name']?.toString() ?? 'User';
                                  final initials = user['initials']?.toString() ?? 'US';
                                  final isSelected = _selectedAssigneeIds.contains(id);

                                  return Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                      leading: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: _parseAvatarColor(user['avatar_color']?.toString()),
                                        child: Text(
                                          initials,
                                          style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      title: Text(name, style: const TextStyle(fontSize: 11)),
                                      selected: isSelected,
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedAssigneeIds.remove(id);
                                          } else {
                                            _selectedAssigneeIds.add(id);
                                          }
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Right Selected Card with Scrolling
                          Expanded(
                            child: Container(
                              height: 160,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SELECTED (${_selectedAssigneeIds.length})',
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: _selectedAssigneeIds.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'Pick users or a group from the left',
                                              style: TextStyle(fontSize: 10, color: Colors.grey),
                                            ),
                                          )
                                        : SingleChildScrollView(
                                            physics: const AlwaysScrollableScrollPhysics(),
                                            child: Wrap(
                                              spacing: 4,
                                              runSpacing: 4,
                                              children: _selectedAssigneeIds.map((id) {
                                                final match = _assignees.firstWhere((a) => a['id'] == id, orElse: () => {'name': 'User #$id'});
                                                return Chip(
                                                  visualDensity: VisualDensity.compact,
                                                  padding: const EdgeInsets.all(2),
                                                  label: Text(match['name']?.toString() ?? '$id', style: const TextStyle(fontSize: 9)),
                                                  deleteIcon: const Icon(Icons.close, size: 10),
                                                  onDeleted: () {
                                                    setState(() => _selectedAssigneeIds.remove(id));
                                                  },
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Attachments Section with Inline Right-side Attachment Chips
                      const Text('Attachments (image, video, document — any file)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.attach_file, size: 15),
                            label: const Text('Add files', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: _showUploadFileDialog,
                          ),
                          ..._attachments.map((att) {
                            final fname = att['filename']?.toString() ?? 'File';
                            final ext = fname.contains('.') ? fname.split('.').last.toLowerCase() : '';
                            
                            IconData iconData = Icons.insert_drive_file_rounded;
                            Color iconColor = Colors.blue;
                            if (ext == 'pdf') {
                              iconData = Icons.picture_as_pdf_rounded;
                              iconColor = Colors.red;
                            } else if (['png', 'jpg', 'jpeg', 'webp', 'gif'].contains(ext)) {
                              iconData = Icons.image_rounded;
                              iconColor = Colors.blue;
                            } else if (['doc', 'docx', 'txt'].contains(ext)) {
                              iconData = Icons.description_rounded;
                              iconColor = Colors.indigo;
                            } else if (['xls', 'xlsx', 'csv'].contains(ext)) {
                              iconData = Icons.table_chart_rounded;
                              iconColor = Colors.green;
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(iconData, color: iconColor, size: 15),
                                  const SizedBox(width: 6),
                                  Text(
                                    fname,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _attachments.remove(att));
                                    },
                                    child: const Icon(Icons.close_rounded, size: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // TO-DO Checklist Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TO-DO Checklist', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            icon: const Icon(Icons.bolt, size: 14, color: Colors.grey),
                            label: const Text('Generate', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _checklistController,
                              decoration: InputDecoration(
                                hintText: 'Add a checklist item...',
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onPressed: () {
                              final text = _checklistController.text.trim();
                              if (text.isNotEmpty) {
                                setState(() {
                                  _checklistItems.add({
                                    'text': text,
                                    'done': false,
                                    'sort': _checklistItems.length,
                                  });
                                  _checklistController.clear();
                                });
                              }
                            },
                            child: const Text('+ Add item', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      if (_checklistItems.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Column(
                          children: _checklistItems.map((item) {
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.check_box_outline_blank, size: 18),
                              title: Text(item['text']?.toString() ?? '', style: const TextStyle(fontSize: 12)),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  setState(() => _checklistItems.remove(item));
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Remarks Section
                      const Text('Remarks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _remarksController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Any additional remarks (optional)...',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Action Buttons (Clean Rectangles matching Screenshot)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  ),
                  icon: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check, size: 18),
                  label: Text(_isSaving ? 'Saving...' : '✓ Save Task', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  onPressed: _isSaving ? null : _submitTask,
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
