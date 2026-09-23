import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_strings.dart';
import '../../modules/tasks/bloc/clone_task_bloc.dart';
import '../../modules/tasks/bloc/clone_task_event.dart';
import '../../modules/tasks/bloc/clone_task_state.dart';
import '../../modules/tasks/models/clone_task_models.dart';
import '../../modules/tasks/models/task_model.dart';

/// Full Clone Task Dialog — matches uploaded screenshots.
/// Pre-fills from [sourceTask] if provided.
class CloneTaskDialog extends StatelessWidget {
  final TaskDetailModel? sourceTask;
  final TaskItemModel? sourceItem;

  const CloneTaskDialog({super.key, this.sourceTask, this.sourceItem});

  static Future<bool?> show(
    BuildContext context, {
    TaskDetailModel? sourceTask,
    TaskItemModel? sourceItem,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider(
        create: (_) => CloneTaskBloc()..add(const LoadCloneTaskLookupsEvent()),
        child: CloneTaskDialog(sourceTask: sourceTask, sourceItem: sourceItem),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CloneTaskBloc, CloneTaskState>(
      listener: (context, state) {
        if (state is CloneTaskSuccess) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task cloned successfully!'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
        } else if (state is CloneTaskError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: _CloneTaskDialogBody(
        sourceTask: sourceTask,
        sourceItem: sourceItem,
      ),
    );
  }
}

// =============================================================================
// Internal stateful body
// =============================================================================
class _CloneTaskDialogBody extends StatefulWidget {
  final TaskDetailModel? sourceTask;
  final TaskItemModel? sourceItem;

  const _CloneTaskDialogBody({this.sourceTask, this.sourceItem});

  @override
  State<_CloneTaskDialogBody> createState() => _CloneTaskDialogBodyState();
}

class _CloneTaskDialogBodyState extends State<_CloneTaskDialogBody> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final _checklistCtrl = TextEditingController();
  final _assigneeSearchCtrl = TextEditingController();

  String _selectedPriority = 'high';
  String _selectedCategory = 'General'; // 'Confidential' or 'General'
  bool _isRecurring = false;
  int? _selectedBranchId;
  int? _selectedAssignedById;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 7));

  final List<int> _selectedAssigneeIds = [];
  final List<Map<String, dynamic>> _checklistItems = [];
  final List<String> _attachmentNames = [];

  String _assigneeSearchQuery = '';
  String _nextTaskNo = '';

  // Snapshot of latest lookups (kept in sync with bloc states)
  CloneTaskLookupsModel? _lookups;

  @override
  void initState() {
    super.initState();
    _prefill();
    _assigneeSearchCtrl.addListener(() {
      setState(() => _assigneeSearchQuery = _assigneeSearchCtrl.text.toLowerCase());
    });
  }

  void _prefill() {
    final t = widget.sourceTask;
    final i = widget.sourceItem;
    _titleCtrl.text = t?.title ?? i?.title ?? '';
    _descCtrl.text = t?.description ?? i?.description ?? '';
    _remarksCtrl.text = '';
    _selectedPriority = (t?.priority ?? i?.priority ?? 'high').toLowerCase();
    _selectedCategory = (t?.category ?? i?.category ?? 'General');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _remarksCtrl.dispose();
    _checklistCtrl.dispose();
    _assigneeSearchCtrl.dispose();
    super.dispose();
  }

  Color _avatarColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF8B5CF6);
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return const Color(0xFF8B5CF6);
    }
  }

  void _syncLookups(CloneTaskLookupsModel lookups) {
    _lookups = lookups;
    _nextTaskNo = lookups.nextTaskNo;
    if (_selectedBranchId == null && lookups.branches.isNotEmpty) {
      _selectedBranchId = lookups.branches.first.id;
    }
  }

  List<AssigneeModel> _filteredAssignees(List<AssigneeModel> all) {
    if (_assigneeSearchQuery.isEmpty) return all;
    return all
        .where((a) =>
            a.name.toLowerCase().contains(_assigneeSearchQuery) ||
            (a.department?.toLowerCase().contains(_assigneeSearchQuery) ?? false))
        .toList();
  }

  Map<String, List<AssigneeModel>> _groupAssignees(List<AssigneeModel> all) {
    final Map<String, List<AssigneeModel>> groups = {};
    for (final a in all) {
      final dept = a.department ?? 'Other';
      groups.putIfAbsent(dept, () => []).add(a);
    }
    return groups;
  }

  void _toggleAssignee(int id) {
    setState(() {
      if (_selectedAssigneeIds.contains(id)) {
        _selectedAssigneeIds.remove(id);
      } else {
        _selectedAssigneeIds.add(id);
      }
    });
  }

  void _submit({bool draft = false}) {
    final s = AppStrings.of(context);
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.taskTitleLabel)),
      );
      return;
    }
    final payload = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'priority': _selectedPriority,
      'category': _selectedCategory,
      'isRecurring': _isRecurring,
      'branchId': _selectedBranchId,
      'assignedBy': _selectedAssignedById,
      'assigneeIds': _selectedAssigneeIds,
      'targetDate': DateFormat('yyyy-MM-dd').format(_targetDate),
      'status': draft ? 'draft' : 'to_be_started',
      'remarks': _remarksCtrl.text.trim(),
      'checklist': _checklistItems,
      'isConfidential': _selectedCategory == 'Confidential',
    };
    context.read<CloneTaskBloc>().add(SubmitCloneTaskEvent(payload));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sourceNo = widget.sourceTask?.taskNo ?? widget.sourceItem?.taskNo ?? '';

    return BlocConsumer<CloneTaskBloc, CloneTaskState>(
      listener: (ctx, state) {
        if (state is CloneTaskLookupsLoaded || state is CloneTaskNextIdUpdated) {
          final lookups = state is CloneTaskLookupsLoaded
              ? state.lookups
              : (state as CloneTaskNextIdUpdated).lookups;
          setState(() => _syncLookups(lookups));
        }
      },
      builder: (ctx, state) {
        final isLoading = state is CloneTaskLoading;
        final isSubmitting = state is CloneTaskSubmitting;
        final lookups = _lookups;

        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 820),
            child: Column(
              children: [
                // ── Header ─────────────────────────────────────────────────
                _buildHeader(s, isDark, sourceNo),

                // ── Scrollable body ────────────────────────────────────────
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cloning banner
                              if (sourceNo.isNotEmpty) _buildCloningBanner(isDark, sourceNo),
                              if (sourceNo.isNotEmpty) const SizedBox(height: 16),

                              // Task ID + Date row
                              _buildTaskIdDateRow(s, isDark),
                              const SizedBox(height: 16),

                              // Task Title
                              _buildLabel(s.taskTitleLabel, required: true, isDark: isDark),
                              _buildTextField(s.taskTitleLabel, _titleCtrl, isDark),
                              const SizedBox(height: 16),

                              // Task Description
                              _buildLabel(s.taskDescLabel, required: true, isDark: isDark),
                              _buildTextField(
                                s.taskDescLabel,
                                _descCtrl,
                                isDark,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),

                              // Assigned By + School Branch
                              if (lookups != null)
                                _buildAssignedByAndBranch(s, isDark, lookups),
                              const SizedBox(height: 16),

                              // Priority
                              _buildLabel(s.priorityLabel, isDark: isDark),
                              if (lookups != null)
                                _buildPriorityButtons(isDark, lookups.priorities),
                              const SizedBox(height: 16),

                              // Target Date
                              _buildLabel(s.targetDateLabel, required: true, isDark: isDark),
                              _buildDateField(isDark),
                              const SizedBox(height: 4),
                              Text(
                                'Auto-set from priority — editable.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.grey[400] : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Category
                              _buildLabel(s.categoryLabel, isDark: isDark),
                              _buildCategoryToggle(isDark),
                              const SizedBox(height: 16),

                              // Make recurring
                              _buildRecurringCheckbox(s, isDark),
                              const SizedBox(height: 16),

                              // Assigned To
                              if (lookups != null) ...[
                                _buildLabel(s.assignedToLabel, isDark: isDark),
                                _buildAssignedTo(s, isDark, lookups),
                                const SizedBox(height: 16),
                              ],

                              // Attachments
                              _buildLabel(s.attachmentsLabel, isDark: isDark),
                              _buildAttachments(s, isDark),
                              const SizedBox(height: 16),

                              // Checklist
                              _buildLabel(s.taskChecklistLabel, isDark: isDark),
                              _buildChecklist(s, isDark),
                              const SizedBox(height: 16),

                              // Remarks
                              _buildLabel(s.remarksLabel, isDark: isDark),
                              _buildTextField(s.remarksLabel, _remarksCtrl, isDark, maxLines: 3),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                ),

                // ── Footer ─────────────────────────────────────────────────
                _buildFooter(s, isDark, isSubmitting),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------
  Widget _buildHeader(AppStrings s, bool isDark, String sourceNo) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.content_copy_outlined, size: 18),
          const SizedBox(width: 8),
          Text(
            s.cloneTaskTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => Navigator.of(context).pop(false),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cloning banner
  // ---------------------------------------------------------------------------
  Widget _buildCloningBanner(bool isDark, String sourceNo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF3B82F6) : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Cloning ',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          Text(
            sourceNo,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D4ED8),
            ),
          ),
          Expanded(
            child: Text(
              ' — a new Task ID is assigned on save. Change anything you need, then create.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Task ID + Date row
  // ---------------------------------------------------------------------------
  Widget _buildTaskIdDateRow(AppStrings s, bool isDark) {
    final taskNo = _nextTaskNo.isNotEmpty ? _nextTaskNo : '…';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('${s.taskIdLabel} (auto-generated)', isDark: isDark),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  taskNo,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Confirmed when you save — may move up if someone else saves first.',
                style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(s.dateLabel, isDark: isDark),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Assigned By + School Branch row
  // ---------------------------------------------------------------------------
  Widget _buildAssignedByAndBranch(
    AppStrings s,
    bool isDark,
    CloneTaskLookupsModel lookups,
  ) {
    final showCreatorsSearch = lookups.assignees.where((a) => a.isTaskCreator).length > 3;
    final showBranchSearch = lookups.branches.length > 3;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(s.assignedByLabel, isDark: isDark),
              _buildSearchableDropdown<AssigneeModel>(
                hint: s.assignedByLabel,
                items: lookups.assignees.where((a) => a.isTaskCreator).toList(),
                selectedId: _selectedAssignedById,
                showSearch: showCreatorsSearch,
                labelFn: (a) => a.name,
                isDark: isDark,
                onChanged: (id) => setState(() => _selectedAssignedById = id),
              ),
              const SizedBox(height: 4),
              Text(
                "Whose task this is. Pick someone else when you're entering it on behalf of them — you can still edit it.",
                style: TextStyle(fontSize: 9, color: isDark ? Colors.grey[400] : Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(s.schoolBranchLabel, isDark: isDark),
              _buildSearchableDropdown<BranchModel>(
                hint: s.schoolBranchLabel,
                items: lookups.branches,
                selectedId: _selectedBranchId,
                showSearch: showBranchSearch,
                labelFn: (b) => b.name,
                isDark: isDark,
                onChanged: (id) {
                  setState(() => _selectedBranchId = id);
                  if (id != null) {
                    context.read<CloneTaskBloc>().add(CloneTaskBranchChangedEvent(id));
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Generic searchable dropdown
  // ---------------------------------------------------------------------------
  Widget _buildSearchableDropdown<T>({
    required String hint,
    required List<T> items,
    required int? selectedId,
    required String Function(T) labelFn,
    required bool showSearch,
    required bool isDark,
    required ValueChanged<int?> onChanged,
  }) {
    int? idOf(T item) {
      if (item is AssigneeModel) return item.id;
      if (item is BranchModel) return item.id;
      return null;
    }

    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<int>(
            value: selectedId,
            hint: Text(hint, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            isExpanded: true,
            dropdownColor: bgColor,
            items: items.map((item) {
              final id = idOf(item);
              return DropdownMenuItem<int>(
                value: id,
                child: Text(labelFn(item), style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87)),
              );
            }).toList(),
            onChanged: onChanged,
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Priority buttons
  // ---------------------------------------------------------------------------
  Widget _buildPriorityButtons(bool isDark, List<EnumPriorityModel> priorities) {
    final List<EnumPriorityModel> displayPriorities = priorities.isNotEmpty
        ? priorities
        : [
            const EnumPriorityModel(value: 'emergency', label: 'Emergency', hint: 'Act NOW'),
            const EnumPriorityModel(value: 'top_most', label: 'Top Most', hint: 'Act Today'),
            const EnumPriorityModel(value: 'high', label: 'High', hint: 'Act this Week'),
            const EnumPriorityModel(value: 'medium', label: 'Medium', hint: 'Schedule to Act'),
            const EnumPriorityModel(value: 'low', label: 'Low', hint: 'When time Permits'),
          ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: displayPriorities.map((p) {
        final isSelected = _selectedPriority == p.value;
        final label = p.hint != null ? '${p.label} · ${p.hint}' : p.label;
        return InkWell(
          onTap: () => setState(() {
            _selectedPriority = p.value;
            // Auto-set target date based on priority
            final now = DateTime.now();
            switch (p.value) {
              case 'emergency':
                _targetDate = now;
                break;
              case 'top_most':
                _targetDate = now.add(const Duration(days: 1));
                break;
              case 'high':
                _targetDate = now.add(const Duration(days: 7));
                break;
              case 'medium':
                _targetDate = now.add(const Duration(days: 14));
                break;
              default:
                _targetDate = now.add(const Duration(days: 30));
            }
          }),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Date field
  // ---------------------------------------------------------------------------
  Widget _buildDateField(bool isDark) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _targetDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
        );
        if (picked != null) setState(() => _targetDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                DateFormat('dd/MM/yyyy').format(_targetDate),
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
              ),
            ),
            Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Category toggle (Confidential / General)
  // ---------------------------------------------------------------------------
  Widget _buildCategoryToggle(bool isDark) {
    return Row(
      children: ['Confidential', 'General'].map((cat) {
        final isSelected = _selectedCategory == cat;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              margin: EdgeInsets.only(right: cat == 'Confidential' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: isSelected
                    ? (cat == 'General'
                        ? (isDark ? const Color(0xFF3B1A1A) : const Color(0xFFFFF5F5))
                        : (isDark ? const Color(0xFF1E293B) : Colors.white))
                    : (isDark ? const Color(0xFF0F172A) : Colors.white),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? (cat == 'General' ? const Color(0xFFB91C1C) : const Color(0xFF94A3B8))
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(cat == 'Confidential' ? '🔒' : '📄', style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: cat == 'General' && isSelected
                          ? const Color(0xFFB91C1C)
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Recurring checkbox
  // ---------------------------------------------------------------------------
  Widget _buildRecurringCheckbox(AppStrings s, bool isDark) {
    return Row(
      children: [
        Checkbox(
          value: _isRecurring,
          onChanged: (v) => setState(() => _isRecurring = v ?? false),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Text(s.makeRecurringLabel, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Assigned To section
  // ---------------------------------------------------------------------------
  Widget _buildAssignedTo(AppStrings s, bool isDark, CloneTaskLookupsModel lookups) {
    final all = lookups.assignees;
    final filtered = _filteredAssignees(all);
    final groups = _groupAssignees(filtered);
    final selectedAssignees = all.where((a) => _selectedAssigneeIds.contains(a.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search box
        TextField(
          controller: _assigneeSearchCtrl,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: s.searchUsersHint,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            prefixIcon: const Icon(Icons.search, size: 16),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          ),
        ),
        const SizedBox(height: 10),

        // Groups + list
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Groups + assignee list
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group chips
                  if (groups.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: groups.entries.map((entry) {
                        return ActionChip(
                          label: Text(
                            '+ ${entry.key} (${entry.value.length})',
                            style: const TextStyle(fontSize: 10),
                          ),
                          onPressed: () {
                            setState(() {
                              for (final a in entry.value) {
                                if (!_selectedAssigneeIds.contains(a.id)) {
                                  _selectedAssigneeIds.add(a.id);
                                }
                              }
                            });
                          },
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Assignee list (scrollable, max 200px)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final a = filtered[i];
                        final isSelected = _selectedAssigneeIds.contains(a.id);
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: _avatarColor(a.avatarColor),
                            child: Text(
                              a.initials,
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(a.name, style: const TextStyle(fontSize: 12)),
                          trailing: isSelected
                              ? const Icon(Icons.check, size: 16, color: Color(0xFF16A34A))
                              : null,
                          onTap: () => _toggleAssignee(a.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Right: selected chips
            if (selectedAssignees.isNotEmpty) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELECTED (${selectedAssignees.length})',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: selectedAssignees.map((a) {
                            return Chip(
                              avatar: CircleAvatar(
                                backgroundColor: _avatarColor(a.avatarColor),
                                child: Text(
                                  a.initials,
                                  style: const TextStyle(fontSize: 8, color: Colors.white),
                                ),
                              ),
                              label: Text(a.name, style: const TextStyle(fontSize: 10)),
                              deleteIcon: const Icon(Icons.close, size: 12),
                              onDeleted: () => _toggleAssignee(a.id),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // "Give each person their own sub-task"
                    if (selectedAssignees.length > 1)
                      Row(
                        children: [
                          Checkbox(
                            value: true,
                            onChanged: null, // future feature
                            visualDensity: VisualDensity.compact,
                          ),
                          Expanded(
                            child: Text(
                              'Give each person their own sub-task',
                              style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Attachments
  // ---------------------------------------------------------------------------
  Widget _buildAttachments(AppStrings s, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'image, video, document — any file',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final dynamic result = await FilePicker.pickFiles(
              allowMultiple: true,
              type: FileType.any,
            );
            if (result != null) {
              final List<dynamic> fileList = result is List ? result : (result.files as List);
              setState(() {
                for (final dynamic f in fileList) {
                  final String name = (f as dynamic).name?.toString() ?? '';
                  if (name.isNotEmpty && !_attachmentNames.contains(name)) {
                    _attachmentNames.add(name);
                  }
                }
              });
            }
          },
          icon: const Icon(Icons.attach_file, size: 14),
          label: Text(s.addFilesButton, style: const TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        if (_attachmentNames.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _attachmentNames.map((name) {
              return Chip(
                label: Text(name, style: const TextStyle(fontSize: 10)),
                deleteIcon: const Icon(Icons.close, size: 12),
                onDeleted: () => setState(() => _attachmentNames.remove(name)),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Checklist
  // ---------------------------------------------------------------------------
  Widget _buildChecklist(AppStrings s, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _checklistCtrl,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Add a checklist item...',
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                final text = _checklistCtrl.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    _checklistItems.add({'text': text, 'done': false});
                    _checklistCtrl.clear();
                  });
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(s.addItemButton, style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 6),
            OutlinedButton(
              onPressed: null, // generate via AI — future feature
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('+ ${s.generateButton}', style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        if (_checklistItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          ..._checklistItems.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Row(
              children: [
                Checkbox(
                  value: item['done'] as bool? ?? false,
                  onChanged: (v) => setState(() => _checklistItems[i]['done'] = v ?? false),
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(child: Text(item['text'] as String, style: const TextStyle(fontSize: 12))),
                IconButton(
                  onPressed: () => setState(() => _checklistItems.removeAt(i)),
                  icon: const Icon(Icons.close, size: 14),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            );
          }),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Footer
  // ---------------------------------------------------------------------------
  Widget _buildFooter(AppStrings s, bool isDark, bool isSubmitting) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: isSubmitting ? null : () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
            ),
            child: Text(s.cancelButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: isSubmitting ? null : () => _submit(draft: true),
            icon: const Icon(Icons.save_outlined, size: 14),
            label: Text(s.saveDraftButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: isSubmitting ? null : () => _submit(draft: false),
            icon: isSubmitting
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check, size: 14),
            label: Text(s.saveTaskButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  Widget _buildLabel(String text, {bool required = false, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
          if (required) ...[
            const SizedBox(width: 2),
            const Text(' *', style: TextStyle(fontSize: 12, color: Color(0xFFB91C1C))),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller,
    bool isDark, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}
