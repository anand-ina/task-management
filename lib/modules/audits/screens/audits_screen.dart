import '../../../shared_widgets/floating_action_button/todo_floating_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/dropdowns/searchable_filter_dropdown.dart';
import '../bloc/audit_bloc.dart';
import '../bloc/audit_event.dart';
import '../bloc/audit_state.dart';
import '../models/audit_model.dart';

class AuditsScreen extends StatefulWidget {
  final bool isAuditee;

  const AuditsScreen({
    super.key,
    required this.isAuditee,
  });

  @override
  State<AuditsScreen> createState() => _AuditsScreenState();
}

class _AuditsScreenState extends State<AuditsScreen> {
  bool _isScheduleFormOpen = false;

  // Form Controllers & State
  final _titleController = TextEditingController();
  final _scopeNoteController = TextEditingController();
  final _checklistController = TextEditingController();

  int? _selectedAuditorId;
  String _auditeeType = 'branch'; // 'branch' or 'person'
  int? _selectedAuditeeBranchId;
  int? _selectedAuditeeUserId;
  DateTime? _scheduledDate;
  DateTime? _dueDate;

  @override
  void dispose() {
    _titleController.dispose();
    _scopeNoteController.dispose();
    _checklistController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _titleController.clear();
    _scopeNoteController.clear();
    _checklistController.clear();
    _selectedAuditorId = null;
    _auditeeType = 'branch';
    _selectedAuditeeBranchId = null;
    _selectedAuditeeUserId = null;
    _scheduledDate = null;
    _dueDate = null;
  }

  Future<void> _pickDate(BuildContext context, bool isScheduled) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isScheduled ? (_scheduledDate ?? now) : (_dueDate ?? now),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isScheduled) {
          _scheduledDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  void _submitScheduleForm(BuildContext context, AuditMetaModel meta) {
    final s = AppStrings.of(context);
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an audit title.')),
      );
      return;
    }

    if (_selectedAuditorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an auditor.')),
      );
      return;
    }

    if (_auditeeType == 'branch' && _selectedAuditeeBranchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an auditee branch.')),
      );
      return;
    }

    if (_auditeeType == 'person' && _selectedAuditeeUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an auditee person.')),
      );
      return;
    }

    final checklistLines = _checklistController.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final body = <String, dynamic>{
      'title': title,
      'scopeNote': _scopeNoteController.text.trim(),
      'auditorId': _selectedAuditorId,
      'scheduledDate': _scheduledDate != null
          ? DateFormat('yyyy-MM-dd').format(_scheduledDate!)
          : DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'dueDate': _dueDate != null
          ? DateFormat('yyyy-MM-dd').format(_dueDate!)
          : DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 7))),
      'checklist': checklistLines,
    };

    if (_auditeeType == 'branch') {
      body['auditeeBranchId'] = _selectedAuditeeBranchId;
    } else {
      body['auditeeUserId'] = _selectedAuditeeUserId;
    }

    context.read<AuditBloc>().add(
          ScheduleAuditEvent(
            body: body,
            isAuditee: widget.isAuditee,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = widget.isAuditee ? s.asAnAuditee : s.asAnInternalAuditor;
    final subtitle = widget.isAuditee ? s.auditsAuditeeSubtitle : s.auditsAuditorSubtitle;
    final currentRoute = widget.isAuditee ? '/audits/auditee' : '/audits/auditor';

    return BlocProvider(
      create: (context) => AuditBloc()
        ..add(FetchAuditsEvent(isAuditee: widget.isAuditee)),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (!didPop) await ExitConfirmationDialog.show(context);
        },
        child: Scaffold(
          floatingActionButton: const TodoFloatingActionButton(),
          drawer: CustomLeftDrawer(currentRoute: currentRoute),
          appBar: const CustomAppBar(),
          body: BlocConsumer<AuditBloc, AuditState>(
            listener: (context, state) {
              if (state is AuditLoadedState) {
                if (state.actionSuccess != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.actionSuccess!),
                      backgroundColor: const Color(0xFF16A34A),
                    ),
                  );
                  setState(() {
                    _isScheduleFormOpen = false;
                    _resetForm();
                  });
                } else if (state.actionError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.actionError!),
                      backgroundColor: const Color(0xFFDC2626),
                    ),
                  );
                }
              }
            },
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<AuditBloc>()
                      .add(FetchAuditsEvent(isAuditee: widget.isAuditee));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isScheduleFormOpen = !_isScheduleFormOpen;
                              });
                            },
                            icon: Icon(
                              _isScheduleFormOpen ? Icons.close_rounded : Icons.add_rounded,
                              size: 16,
                            ),
                            label: Text(
                              _isScheduleFormOpen ? 'Close' : '+ ${s.scheduleAnAudit}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isScheduleFormOpen
                                  ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                                  : const Color(0xFF0F172A),
                              foregroundColor: _isScheduleFormOpen
                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Schedule Form (Image 3)
                      if (_isScheduleFormOpen && state is AuditLoadedState) ...[
                        _buildScheduleForm(context, s, state, isDark),
                        const SizedBox(height: 24),
                      ],

                      // State Handling
                      if (state is AuditLoadingState)
                        const Padding(
                          padding: EdgeInsets.all(60),
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFF0F172A)),
                          ),
                        )
                      else if (state is AuditErrorState)
                        Center(
                          child: Column(
                            children: [
                              Text(state.message, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => context
                                    .read<AuditBloc>()
                                    .add(FetchAuditsEvent(isAuditee: widget.isAuditee)),
                                child: Text(s.retryButton),
                              ),
                            ],
                          ),
                        )
                      else if (state is AuditLoadedState) ...[
                        if (state.selectedAudit != null)
                          _buildAuditDetailView(context, s, state.selectedAudit!, isDark, state)
                        else
                          _buildAuditsList(context, s, state.audits, isDark),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Schedule Audit Form (Matching Image 3)
  Widget _buildScheduleForm(
    BuildContext context,
    AppStrings s,
    AuditLoadedState state,
    bool isDark,
  ) {
    final meta = state.meta;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.scheduleAnAudit,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),

          // Title field
          _buildFieldLabel(s.auditTitleLabel, isDark),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            decoration: _inputDecoration(isDark, hintText: 'e.g. Cash review'),
          ),
          const SizedBox(height: 14),

          // Scope note field
          _buildFieldLabel(s.scopeNoteLabel, isDark),
          const SizedBox(height: 6),
          TextField(
            controller: _scopeNoteController,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            decoration: _inputDecoration(isDark, hintText: 'Scope note (optional)'),
          ),
          const SizedBox(height: 14),

          // Auditor dropdown
          _buildFieldLabel(s.auditorLabel, isDark),
          const SizedBox(height: 6),
          SearchableFilterDropdown<int>(
            value: _selectedAuditorId,
            hint: 'Select auditor...',
            searchHint: 'Search auditor...',
            items: meta.people.map((p) {
              final label = p.role != null ? '${p.name} (${p.role})' : p.name;
              return SearchableDropdownItem<int>(value: p.id, label: label);
            }).toList(),
            onChanged: (val) {
              setState(() => _selectedAuditorId = val);
            },
          ),
          const SizedBox(height: 14),

          // Auditee Type toggle + selector
          _buildFieldLabel(s.auditeeLabel, isDark),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildToggleChip(
                label: s.branchScopeLabel,
                isSelected: _auditeeType == 'branch',
                isDark: isDark,
                onTap: () => setState(() => _auditeeType = 'branch'),
              ),
              const SizedBox(width: 8),
              _buildToggleChip(
                label: 'Person',
                isSelected: _auditeeType == 'person',
                isDark: isDark,
                onTap: () => setState(() => _auditeeType = 'person'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_auditeeType == 'branch')
            SearchableFilterDropdown<int>(
              value: _selectedAuditeeBranchId,
              hint: 'Select branch...',
              searchHint: 'Search branch...',
              items: meta.branches
                  .map((b) => SearchableDropdownItem<int>(
                        value: b.id,
                        label: b.displayName,
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() => _selectedAuditeeBranchId = val);
              },
            )
          else
            SearchableFilterDropdown<int>(
              value: _selectedAuditeeUserId,
              hint: 'Select person...',
              searchHint: 'Search person...',
              items: meta.people
                  .map((p) => SearchableDropdownItem<int>(
                        value: p.id,
                        label: p.role != null ? '${p.name} (${p.role})' : p.name,
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() => _selectedAuditeeUserId = val);
              },
            ),
          const SizedBox(height: 14),

          // Date pickers row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel(s.scheduledDateLabel, isDark),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _pickDate(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _scheduledDate != null
                                  ? DateFormat('yyyy-MM-dd').format(_scheduledDate!)
                                  : 'Pick date',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Icon(Icons.calendar_today_rounded, size: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
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
                    _buildFieldLabel(s.dueDateLabel, isDark),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _pickDate(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _dueDate != null
                                  ? DateFormat('yyyy-MM-dd').format(_dueDate!)
                                  : 'Pick date',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Icon(Icons.calendar_today_rounded, size: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Checklist field
          _buildFieldLabel(s.checklistOnePerLine, isDark),
          const SizedBox(height: 6),
          TextField(
            controller: _checklistController,
            maxLines: 4,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            decoration: _inputDecoration(
              isDark,
              hintText: 'e.g. Verify cash register\nCheck bank reconciliations\nInspect petty cash receipts',
            ),
          ),
          const SizedBox(height: 18),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isScheduling ? null : () => _submitScheduleForm(context, meta),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: state.isScheduling
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(s.scheduleAuditButton, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  /// Audits Container Cards List (Matching Image 4)
  Widget _buildAuditsList(
    BuildContext context,
    AppStrings s,
    List<AuditItemModel> audits,
    bool isDark,
  ) {
    if (audits.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isAuditee ? Icons.assignment_outlined : Icons.search_rounded,
              size: 40,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              s.noAuditsFound,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: audits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final audit = audits[index];
        final status = audit.status.toUpperCase();
        final isClosed = status == 'CLOSED';
        final isScheduled = status == 'SCHEDULED';

        Color statusBg = const Color(0xFFFEF3C7);
        Color statusFg = const Color(0xFFB45309);
        if (isClosed) {
          statusBg = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
          statusFg = isDark ? Colors.grey.shade300 : const Color(0xFF475569);
        } else if (!isScheduled) {
          statusBg = const Color(0xFFDBEAFE);
          statusFg = const Color(0xFF1D4ED8);
        }

        return InkWell(
          onTap: () {
            context.read<AuditBloc>().add(SelectAuditDetailEvent(audit.id));
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Status Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        audit.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusFg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Auditee Scope / Branch Badge
                if (audit.auditeeBranchName != null && audit.auditeeBranchName!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Branch: ${audit.auditeeBranchName}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                      ),
                    ),
                  ),

                // Meta Row (Auditor, Scheduled, Due)
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    if (audit.auditorName != null && audit.auditorName!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_outline_rounded, size: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            audit.auditorName!,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    if (audit.scheduledDate != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${s.scheduledFor}: ${audit.scheduledDate}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    if (audit.dueDate != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_available_rounded, size: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${s.dueOn}: ${audit.dueDate}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                if (audit.scopeNote != null && audit.scopeNote!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    audit.scopeNote!,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],

                if (audit.items.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${audit.items.length} checklist item${audit.items.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Audit Detail View (Matching Image 5)
  Widget _buildAuditDetailView(
    BuildContext context,
    AppStrings s,
    AuditItemModel audit,
    bool isDark,
    AuditLoadedState state,
  ) {
    final status = audit.status.toUpperCase();
    final isClosed = status == 'CLOSED';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          TextButton.icon(
            onPressed: () {
              context.read<AuditBloc>().add(ClearAuditDetailEvent());
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Back to audits', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
          const SizedBox(height: 12),

          // Title & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  audit.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isClosed
                      ? (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isClosed
                        ? (isDark ? Colors.white70 : const Color(0xFF475569))
                        : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Badges row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (audit.auditeeBranchName != null && audit.auditeeBranchName!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    'Branch: ${audit.auditeeBranchName}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                    ),
                  ),
                ),
              if (audit.auditorName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    '${s.conductedBy}: ${audit.auditorName}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Scheduled and Due row
           Column(
            children: [
              if (audit.scheduledDate != null)
                Text(
                  '${s.scheduledFor}: ${audit.scheduledDate}',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              if (audit.scheduledDate != null && audit.dueDate != null)
                Text(' · ', style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400)),
              if (audit.dueDate != null)
                Text(
                  '${s.dueOn}: ${audit.dueDate}',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
            ],
          ),
          if (audit.scopeNote != null && audit.scopeNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${s.scopeNoteLabel}: ${audit.scopeNote}',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Checklist Section
          Text(
            'Checklist Items (${audit.items.length})',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          if (audit.items.isEmpty)
            Text('No checklist items.', style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: audit.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = audit.items[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: item.done ? const Color(0xFF16A34A) : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.text,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            decoration: item.done ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 24),

          // Close Audit Action
          if (audit.canClose && !isClosed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.isClosing
                    ? null
                    : () {
                        context.read<AuditBloc>().add(
                              CloseAuditEvent(
                                id: audit.id,
                                isAuditee: widget.isAuditee,
                              ),
                            );
                      },
                icon: state.isClosing
                    ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: Text(s.closeAudit, style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0F172A)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F172A)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey.shade300 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(bool isDark, {String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
      ),
    );
  }
}
