import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_strings.dart';
import '../../modules/dashboard/models/branch_model.dart';
import '../../modules/tasks/models/clone_task_models.dart' hide BranchModel;
import '../../modules/tasks/models/task_model.dart';
import '../../modules/tasks/repository/task_repository.dart';
import '../animations/app_animations.dart';

class EditTaskDialog extends StatefulWidget {
  final TaskDetailModel task;

  const EditTaskDialog({
    super.key,
    required this.task,
  });

  static Future<bool?> show(
    BuildContext context, {
    required TaskDetailModel task,
  }) {
    return showSmoothDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => EditTaskDialog(task: task),
    );
  }

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final TaskRepository _repository = TaskRepository();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _remarksController;
  late TextEditingController _commentController;
  final TextEditingController _searchAssigneeController = TextEditingController();

  List<BranchModel> _branches = [];
  List<AssigneeModel> _assignees = [];
  List<AssigneeModel> _filteredAssignees = [];

  int? _selectedBranchId;
  late String _selectedPriority;
  late String _selectedCategory;
  late DateTime _targetDate;
  final List<int> _selectedAssigneeIds = [];

  final List<String> _categories = [
    'General',
    'Academics',
    'Administration',
    'Admission Counselling',
    'Accounts',
    'Transport',
    'Events',
  ];

  final List<Map<String, String>> _priorities = [
    {'value': 'emergency', 'label': 'Emergency'},
    {'value': 'top_most', 'label': 'Top Most'},
    {'value': 'high', 'label': 'High'},
    {'value': 'medium', 'label': 'Medium'},
    {'value': 'low', 'label': 'Low'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
    _remarksController = TextEditingController(text: widget.task.remarks ?? '');
    _commentController = TextEditingController();

    _selectedBranchId = widget.task.branchId;
    _selectedPriority = widget.task.priority.isNotEmpty ? widget.task.priority : 'high';
    _selectedCategory = widget.task.category.isNotEmpty ? widget.task.category : 'General';

    DateTime? parsedDate;
    if (widget.task.dueDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(widget.task.dueDate);
    }
    _targetDate = parsedDate ?? DateTime.now().add(const Duration(days: 7));

    for (final a in widget.task.assignees) {
      _selectedAssigneeIds.add(a.id);
    }

    _loadLookups();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _remarksController.dispose();
    _commentController.dispose();
    _searchAssigneeController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    try {
      final results = await Future.wait([
        _repository.getBranches(),
        _repository.getAssigneesLookup(),
      ]);

      if (mounted) {
        setState(() {
          _branches = results[0] as List<BranchModel>;
          _assignees = results[1] as List<AssigneeModel>;
          _filteredAssignees = List.from(_assignees);

          if (_selectedBranchId == null ||
              !_branches.any((b) => b.id == _selectedBranchId)) {
            if (_branches.isNotEmpty) {
              _selectedBranchId = _branches.first.id;
            }
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
      if (query.trim().isEmpty) {
        _filteredAssignees = List.from(_assignees);
      } else {
        final q = query.toLowerCase();
        _filteredAssignees = _assignees.where((a) {
          final name = a.name.toLowerCase();
          final dept = (a.department ?? '').toLowerCase();
          return name.contains(q) || dept.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _selectTargetDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) {
      setState(() => _targetDate = picked);
    }
  }

  Color _hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return const Color(0xFF8B5CF6);
    try {
      final hex = hexString.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF8B5CF6);
  }

  void _showBranchPicker() {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = _branches.where((b) {
              final q = searchQuery.toLowerCase();
              return b.name.toLowerCase().contains(q) || b.code.toLowerCase().contains(q);
            }).toList();

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              title: Text(s.schoolBranchLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 360,
                height: 380,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: s.searchPeopleHint,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (val) {
                        setDialogState(() => searchQuery = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(child: Text(s.noStaffFound))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final b = filtered[index];
                                final isSelected = b.id == _selectedBranchId;
                                return ListTile(
                                  dense: true,
                                  title: Text(b.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                  subtitle: Text(b.code, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  trailing: isSelected ? const Icon(Icons.check, color: Colors.green, size: 18) : null,
                                  onTap: () {
                                    setState(() => _selectedBranchId = b.id);
                                    Navigator.of(ctx).pop();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(s.cancelButton),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitChanges() async {
    final s = AppStrings.of(context);
    final title = _titleController.text.trim();
    final comment = _commentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.taskTitleLabel} * is required'), backgroundColor: Colors.red),
      );
      return;
    }

    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.commentLabel} * is required'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dueDateStr = DateFormat('yyyy-MM-dd').format(_targetDate);
      final payload = {
        'title': title,
        'description': _descController.text.trim(),
        'branchId': _selectedBranchId ?? widget.task.branchId,
        'dueDate': dueDateStr,
        'priority': _selectedPriority,
        'category': _selectedCategory,
        'assigneeIds': _selectedAssigneeIds,
        'remarks': _remarksController.text.trim(),
        'comment': comment,
      };

      await _repository.updateTaskDetail(widget.task.id, payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.taskUpdatedSuccess), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update task: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    final selectedBranch = _branches.where((b) => b.id == _selectedBranchId).firstOrNull;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 32,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: size.height * 0.9,
        ),
        child: _isLoading
            ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                      child: Row(
                        children: [
                          const Text('✏️ ', style: TextStyle(fontSize: 16)),
                          Text(
                            s.editTaskTitle,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Task ID ${widget.task.taskNo}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.of(context).pop(false),
                            splashRadius: 18,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Task Title *
                            Text(
                              '${s.taskTitleLabel} *',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _titleController,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Task Description
                            Text(
                              s.taskDescriptionLabel,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _descController,
                              maxLines: 3,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // School Branch & Target Date Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.schoolBranchLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: _branches.length > 3 ? _showBranchPicker : null,
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  selectedBranch?.name ?? 'Select Branch',
                                                  style: const TextStyle(fontSize: 13),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const Icon(Icons.arrow_drop_down, size: 20),
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
                                      Text(s.targetDateLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: _selectTargetDate,
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16),
                                          ),
                                          child: Text(
                                            DateFormat('dd/MM/yyyy').format(_targetDate),
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Priority & Category Row
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.priorityLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        value: _priorities.any((p) => p['value'] == _selectedPriority)
                                            ? _selectedPriority
                                            : 'high',
                                        isDense: true,
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        items: _priorities.map((p) {
                                          return DropdownMenuItem<String>(
                                            value: p['value'],
                                            child: Text(p['label']!, style: const TextStyle(fontSize: 13)),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) setState(() => _selectedPriority = val);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.categoryLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        value: _categories.contains(_selectedCategory) ? _selectedCategory : 'General',
                                        isDense: true,
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        items: _categories.map((c) {
                                          return DropdownMenuItem<String>(
                                            value: c,
                                            child: Text(c, style: const TextStyle(fontSize: 13)),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) setState(() => _selectedCategory = val);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Assigned To Section
                            Row(
                              children: [
                                Text(
                                  s.assignedToLabel,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '· ${_selectedAssigneeIds.length} ${s.selectedLabel.toLowerCase()}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _searchAssigneeController,
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                hintText: s.searchPeopleHint,
                                prefixIcon: const Icon(Icons.search, size: 16),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onChanged: _filterAssignees,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _filteredAssignees.isEmpty
                                  ? Center(child: Text(s.noStaffFound, style: const TextStyle(fontSize: 12, color: Colors.grey)))
                                  : ListView.separated(
                                      itemCount: _filteredAssignees.length,
                                      separatorBuilder: (_, index) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
                                      itemBuilder: (context, idx) {
                                        final assignee = _filteredAssignees[idx];
                                        final isChecked = _selectedAssigneeIds.contains(assignee.id);
                                        return CheckboxListTile(
                                          dense: true,
                                          visualDensity: VisualDensity.compact,
                                          value: isChecked,
                                          title: Text(assignee.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                          secondary: CircleAvatar(
                                            radius: 12,
                                            backgroundColor: _hexToColor(assignee.avatarColor),
                                            child: Text(
                                              assignee.initials,
                                              style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          subtitle: assignee.department != null && assignee.department!.isNotEmpty
                                              ? Text(assignee.department!, style: const TextStyle(fontSize: 10, color: Colors.grey))
                                              : null,
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                _selectedAssigneeIds.add(assignee.id);
                                              } else {
                                                _selectedAssigneeIds.remove(assignee.id);
                                              }
                                            });
                                          },
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 6),
                            if (_selectedAssigneeIds.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: _selectedAssigneeIds.map((id) {
                                  final person = _assignees.cast<AssigneeModel?>().firstWhere(
                                        (a) => a?.id == id,
                                        orElse: () => null,
                                      );
                                  if (person == null) return const SizedBox.shrink();
                                  return Chip(
                                    visualDensity: VisualDensity.compact,
                                    label: Text(person.name, style: const TextStyle(fontSize: 11)),
                                    deleteIcon: const Icon(Icons.close, size: 14),
                                    onDeleted: () {
                                      setState(() => _selectedAssigneeIds.remove(id));
                                    },
                                  );
                                }).toList(),
                              ),
                            const SizedBox(height: 14),

                            // Remarks
                            Text(s.remarksLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _remarksController,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Comment * (what changed and why)
                            RichText(
                              text: TextSpan(
                                text: '${s.commentLabel} * ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                children: [
                                  TextSpan(
                                    text: s.commentSubtext,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _commentController,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: s.commentHint,
                                hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Footer actions
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(s.cancelButton),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _isSaving ? null : _submitChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _isSaving
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(s.saveChangesButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
