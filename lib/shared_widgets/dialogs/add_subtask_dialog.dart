import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_strings.dart';
import '../../modules/auth/bloc/auth_bloc.dart';
import '../../modules/auth/bloc/auth_state.dart';
import '../../modules/dashboard/models/branch_model.dart';
import '../../modules/tasks/bloc/subtask_bloc.dart';
import '../../modules/tasks/bloc/subtask_event.dart';
import '../../modules/tasks/bloc/subtask_state.dart';
import '../../modules/tasks/models/clone_task_models.dart' hide BranchModel;
import '../../modules/tasks/models/task_model.dart';

class AddSubTaskDialog extends StatefulWidget {
  final TaskDetailModel parentTask;

  const AddSubTaskDialog({
    super.key,
    required this.parentTask,
  });

  static Future<dynamic> show(
    BuildContext context, {
    required TaskDetailModel parentTask,
  }) {
    return showDialog<dynamic>(
      context: context,
      barrierDismissible: false, // Locked background screen - makes it unclickable
      builder: (context) => BlocProvider(
        create: (_) => SubtaskBloc()
          ..add(LoadSubtaskLookupsEvent(
            parentTaskId: parentTask.id,
            branchId: parentTask.branchId,
          )),
        child: AddSubTaskDialog(parentTask: parentTask),
      ),
    );
  }

  @override
  State<AddSubTaskDialog> createState() => _AddSubTaskDialogState();
}

class _AddSubTaskDialogState extends State<AddSubTaskDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _taskIdController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _searchAssigneeController = TextEditingController();
  final TextEditingController _checklistInputController = TextEditingController();

  DateTime _taskDate = DateTime.now();
  late DateTime _targetDate;
  int? _selectedBranchId;
  int? _assigningOnBehalfOfId;
  String _selectedPriority = 'high';

  final List<int> _selectedAssigneeIds = [];
  final List<String> _checklistItems = [];
  final List<Map<String, dynamic>> _attachments = [];

  String? _selectedGroupFilter;
  List<AssigneeModel> _allAssignees = [];
  List<AssigneeModel> _filteredAssignees = [];
  List<BranchModel> _branches = [];

  final List<Map<String, String>> _priorities = [
    {'value': 'emergency', 'label': 'Emergency · Act NOW'},
    {'value': 'top_most', 'label': 'Top Most · Act Today'},
    {'value': 'high', 'label': 'High · Act this Week'},
    {'value': 'medium', 'label': 'Medium · Schedule to Act'},
    {'value': 'low', 'label': 'Low · When time Permits'},
  ];

  @override
  void initState() {
    super.initState();
    DateTime? parentDueDate;
    if (widget.parentTask.dueDate.isNotEmpty) {
      parentDueDate = DateTime.tryParse(widget.parentTask.dueDate);
    }
    _targetDate = parentDueDate ?? DateTime.now().add(const Duration(days: 7));
    _selectedBranchId = widget.parentTask.branchId;
  }

  @override
  void dispose() {
    _taskIdController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _remarksController.dispose();
    _searchAssigneeController.dispose();
    _checklistInputController.dispose();
    super.dispose();
  }

  void _syncLookups(SubtaskState state) {
    if (state is SubtaskLookupsLoaded) {
      if (_taskIdController.text.isEmpty) {
        _taskIdController.text = state.lookups.nextTaskNo;
      }
      _allAssignees = state.lookups.assignees;
      _branches = state.lookups.branches;
      _filterAssignees();

      if (_selectedBranchId == null && _branches.isNotEmpty) {
        _selectedBranchId = _branches.first.id;
      }
    }
  }

  void _filterAssignees() {
    final query = _searchAssigneeController.text.trim().toLowerCase();
    setState(() {
      _filteredAssignees = _allAssignees.where((a) {
        final matchesQuery = query.isEmpty ||
            a.name.toLowerCase().contains(query) ||
            (a.department ?? '').toLowerCase().contains(query);
        final matchesGroup = _selectedGroupFilter == null ||
            (a.department?.toLowerCase() == _selectedGroupFilter?.toLowerCase());
        return matchesQuery && matchesGroup;
      }).toList();
    });
  }

  Map<String, int> _getDepartmentCounts() {
    final Map<String, int> counts = {};
    for (final a in _allAssignees) {
      final dept = a.department?.trim();
      final key = (dept != null && dept.isNotEmpty) ? dept : 'Other';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> _pickFiles() async {
    try {
      final dynamic result = await FilePicker.pickFiles(allowMultiple: true);
      if (result != null && result.files != null && (result.files as List).isNotEmpty) {
        setState(() {
          for (final f in result.files) {
            _attachments.add({
              'filename': f.name,
              'size': f.size,
              'path': f.path,
              'mime': 'application/octet-stream',
            });
          }
        });
      }
    } catch (_) {}
  }

  void _addChecklistItem() {
    final text = _checklistInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _checklistItems.add(text);
        _checklistInputController.clear();
      });
    }
  }

  void _generateChecklistItems() {
    setState(() {
      if (!_checklistItems.contains('Review requirements')) {
        _checklistItems.add('Review requirements');
      }
      if (!_checklistItems.contains('Prepare implementation')) {
        _checklistItems.add('Prepare implementation');
      }
      if (!_checklistItems.contains('Submit for approval')) {
        _checklistItems.add('Submit for approval');
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

  Future<void> _selectTaskDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _taskDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) {
      setState(() => _taskDate = picked);
    }
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

  void _submitSubtask() {
    final s = AppStrings.of(context);
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.taskTitleLabel} * is required'), backgroundColor: Colors.red),
      );
      return;
    }
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.taskDescriptionLabel} * is required'), backgroundColor: Colors.red),
      );
      return;
    }

    final dueDateStr = DateFormat('yyyy-MM-dd').format(_targetDate);

    final payload = {
      'title': title,
      'description': desc,
      'branchId': _selectedBranchId ?? widget.parentTask.branchId,
      'priority': _selectedPriority,
      'category': 'General',
      'dueDate': dueDateStr,
      'remarks': _remarksController.text.trim(),
      'assigneeIds': _selectedAssigneeIds,
      'checklist': _checklistItems.map((e) => {'title': e, 'is_completed': false}).toList(),
      'attachments': _attachments,
      'isRecurring': false,
      'parentTaskId': widget.parentTask.id,
      'splitPerAssignee': false,
    };

    context.read<SubtaskBloc>().add(CreateSubtaskEvent(payload));
  }

  void _showForbiddenDialog(String message) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 22),
            const SizedBox(width: 8),
            Text(
              s.forbiddenErrorTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.closeButton),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;

    final authState = context.watch<AuthBloc>().state;
    String currentUserName = 'User';
    if (authState is AuthenticatedState) {
      currentUserName = authState.userProfile.name;
    }

    final selectedBranch = _branches.where((b) => b.id == _selectedBranchId).firstOrNull;

    final departmentCounts = _getDepartmentCounts();

    return BlocConsumer<SubtaskBloc, SubtaskState>(
      listener: (context, state) {
        _syncLookups(state);

        if (state is SubtaskSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.subtaskCreatedSuccess), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(state.createdTask ?? true);
        } else if (state is SubtaskForbiddenError) {
          // Show popup alert dialog with error message and DO NOT CLOSE AddSubTaskDialog
          _showForbiddenDialog(state.message);
        } else if (state is SubtaskError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state is SubtaskSubmitting;
        final isLoadingLookups = state is SubtaskLoading;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 36,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 780,
              maxHeight: size.height * 0.92,
            ),
            child: isLoadingLookups
                ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
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
                              const Icon(Icons.subdirectory_arrow_right, size: 20, color: Color(0xFF475569)),
                              const SizedBox(width: 8),
                              Text(
                                s.addSubTaskButton.replaceAll('+', '').trim(),
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: isSubmitting ? null : () => Navigator.of(context).pop(false),
                                splashRadius: 18,
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // Form Scroll Area
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Banner Card: Sub-task of SS03-0007/10-26 — ui changes
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark ? Colors.blue.withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      text: '${s.subTaskOf} ',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: isDark ? Colors.white70 : const Color(0xFF1E3A8A),
                                      ),
                                      children: [
                                        TextSpan(
                                          text: widget.parentTask.taskNo,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(
                                          text: ' — ${widget.parentTask.title}',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Row 1: Task ID (auto-generated) & Date
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s.taskIdAutoGenerated, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 6),
                                          TextField(
                                            controller: _taskIdController,
                                            readOnly: true,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              filled: true,
                                              fillColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            s.taskIdAutoGeneratedHint,
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s.dateLabel, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 6),
                                          InkWell(
                                            onTap: _selectTaskDate,
                                            child: InputDecorator(
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              child: Text(
                                                DateFormat('dd/MM/yyyy').format(_taskDate),
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

                                // Task Title *
                                Text('${s.taskTitleLabel} *', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _titleController,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: s.taskTitleHint,
                                    hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Task Description *
                                Text('${s.taskDescriptionLabel} *', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _descController,
                                  maxLines: 3,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: s.taskDescriptionHint,
                                    hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Assigned By (readonly box)
                                Text(s.assignedByLabel, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    '$currentUserName (me)',
                                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF334155)),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  s.assignedBySubtext,
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                                const SizedBox(height: 14),

                                // Row: Assigning on Behalf of & School Branch
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s.assigningOnBehalfOfLabel, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 6),
                                          DropdownButtonFormField<int?>(
                                            value: _assigningOnBehalfOfId,
                                            isDense: true,
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            items: [
                                              DropdownMenuItem<int?>(
                                                value: null,
                                                child: Text('$currentUserName (me)', style: const TextStyle(fontSize: 13)),
                                              ),
                                              ..._allAssignees.map((a) {
                                                return DropdownMenuItem<int?>(
                                                  value: a.id,
                                                  child: Text(a.name, style: const TextStyle(fontSize: 13)),
                                                );
                                              }),
                                            ],
                                            onChanged: (val) {
                                              setState(() => _assigningOnBehalfOfId = val);
                                            },
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            s.assigningOnBehalfOfSubtext,
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s.schoolBranchLabel, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
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
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Priority 5 pill buttons
                                Text(s.priorityLabel, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: _priorities.map((p) {
                                      final isSelected = _selectedPriority == p['value'];
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: ChoiceChip(
                                          selected: isSelected,
                                          label: Text(
                                            p['label']!,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                            ),
                                          ),
                                          selectedColor: const Color(0xFF0F172A),
                                          backgroundColor: isDark ? Colors.white10 : Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                            side: BorderSide(
                                              color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade300,
                                            ),
                                          ),
                                          showCheckmark: false,
                                          onSelected: (selected) {
                                            if (selected) {
                                              setState(() => _selectedPriority = p['value']!);
                                            }
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Target Date *
                                Text('${s.targetDateLabel} *', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
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
                                const SizedBox(height: 4),
                                Text(
                                  '${s.targetDateSubtext} (${widget.parentTask.dueDate}).',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                                const SizedBox(height: 16),

                                // Assigned To Section with groups & split list
                                Text(s.assignedToLabel, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _searchAssigneeController,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: InputDecoration(
                                    hintText: s.searchUsersHint,
                                    prefixIcon: const Icon(Icons.search, size: 16),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onChanged: (_) => _filterAssignees(),
                                ),
                                const SizedBox(height: 8),

                                // Department group pills
                                if (departmentCounts.isNotEmpty)
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: departmentCounts.entries.map((entry) {
                                        final isGroupSelected = _selectedGroupFilter == entry.key;
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 6),
                                          child: ActionChip(
                                            visualDensity: VisualDensity.compact,
                                            label: Text(
                                              '+ ${entry.key} (${entry.value})',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: isGroupSelected ? FontWeight.bold : FontWeight.normal,
                                                color: isGroupSelected ? Colors.white : const Color(0xFF2563EB),
                                              ),
                                            ),
                                            backgroundColor: isGroupSelected ? const Color(0xFF2563EB) : const Color(0xFFEFF6FF),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              side: BorderSide(color: isGroupSelected ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE)),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                if (_selectedGroupFilter == entry.key) {
                                                  _selectedGroupFilter = null;
                                                } else {
                                                  _selectedGroupFilter = entry.key;
                                                }
                                                _filterAssignees();
                                              });
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                const SizedBox(height: 8),

                                // Assignees split view (Left list, Right selected)
                                isMobile
                                    ? Column(
                                        children: [
                                          _buildAssigneeList(isDark),
                                          const SizedBox(height: 8),
                                          _buildSelectedBox(isDark, s),
                                        ],
                                      )
                                    : Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: _buildAssigneeList(isDark)),
                                          const SizedBox(width: 12),
                                          Expanded(child: _buildSelectedBox(isDark, s)),
                                        ],
                                      ),
                                const SizedBox(height: 16),

                                // Attachments
                                Text(s.attachmentsLabel, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _pickFiles,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDark ? Colors.white24 : Colors.grey.shade400,
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.attach_file, size: 16, color: Colors.blue),
                                        const SizedBox(width: 6),
                                        Text(
                                          s.addFilesButton,
                                          style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_attachments.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: _attachments.map((att) {
                                      return Chip(
                                        visualDensity: VisualDensity.compact,
                                        label: Text(att['filename']?.toString() ?? 'File', style: const TextStyle(fontSize: 11)),
                                        deleteIcon: const Icon(Icons.close, size: 14),
                                        onDeleted: () {
                                          setState(() => _attachments.remove(att));
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                                const SizedBox(height: 16),

                                // Task Checklist
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(s.taskChecklistLabel, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                    OutlinedButton.icon(
                                      onPressed: _generateChecklistItems,
                                      icon: const Icon(Icons.auto_awesome, size: 12, color: Colors.purple),
                                      label: Text(s.generateButton, style: const TextStyle(fontSize: 11)),
                                      style: OutlinedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _checklistInputController,
                                        style: const TextStyle(fontSize: 12),
                                        decoration: InputDecoration(
                                          hintText: s.addChecklistItemHint,
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onSubmitted: (_) => _addChecklistItem(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: _addChecklistItem,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                                        foregroundColor: isDark ? Colors.white : Colors.black87,
                                        visualDensity: VisualDensity.compact,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Text(s.addItemButton, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                if (_checklistItems.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  ..._checklistItems.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final item = entry.value;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_box_outline_blank, size: 16, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Expanded(child: Text(item, style: const TextStyle(fontSize: 12))),
                                          IconButton(
                                            icon: const Icon(Icons.close, size: 14, color: Colors.grey),
                                            splashRadius: 14,
                                            onPressed: () {
                                              setState(() => _checklistItems.removeAt(index));
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                                const SizedBox(height: 16),

                                // Remarks
                                Text(s.remarksLabel, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
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
                              ],
                            ),
                          ),
                        ),

                        // Footer Buttons Bar
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: isSubmitting ? null : () => Navigator.of(context).pop(false),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(s.cancelButton),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: isSubmitting ? null : _submitSubtask,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: isSubmitting
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check, size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            s.saveSubTaskButton.replaceAll('✓', '').trim(),
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildAssigneeList(bool isDark) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _filteredAssignees.isEmpty
          ? const Center(child: Text('No users found', style: TextStyle(fontSize: 11, color: Colors.grey)))
          : ListView.separated(
              itemCount: _filteredAssignees.length,
              separatorBuilder: (_, index) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
              itemBuilder: (context, idx) {
                final a = _filteredAssignees[idx];
                final isSelected = _selectedAssigneeIds.contains(a.id);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedAssigneeIds.remove(a.id);
                      } else {
                        _selectedAssigneeIds.add(a.id);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: _hexToColor(a.avatarColor),
                          child: Text(
                            a.initials,
                            style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            a.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, size: 16, color: Colors.green)
                        else
                          const Icon(Icons.circle_outlined, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSelectedBox(bool isDark, AppStrings s) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${s.selectedLabel} (${_selectedAssigneeIds.length})',
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _selectedAssigneeIds.isEmpty
                ? Center(
                    child: Text(
                      s.pickUsersFromLeft,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _selectedAssigneeIds.map((id) {
                        final person = _allAssignees.cast<AssigneeModel?>().firstWhere(
                              (a) => a?.id == id,
                              orElse: () => null,
                            );
                        if (person == null) return const SizedBox.shrink();
                        return Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(person.name, style: const TextStyle(fontSize: 11)),
                          deleteIcon: const Icon(Icons.close, size: 13),
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
    );
  }
}
