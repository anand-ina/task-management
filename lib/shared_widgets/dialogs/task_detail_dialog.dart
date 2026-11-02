import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../modules/auth/bloc/auth_bloc.dart';
import '../../../modules/auth/bloc/auth_state.dart';
import '../../../modules/tasks/models/task_model.dart';
import '../../../modules/tasks/repository/task_repository.dart';
import '../../modules/complaints/screens/complaints_screen.dart';
import 'clone_task_dialog.dart';
import 'add_subtask_dialog.dart';
import 'edit_task_dialog.dart';
import 'mark_done_dialog.dart';
import 'move_task_dialog.dart';
import 'raise_escalation_dialog.dart';
import 'reassign_task_dialog.dart';
import 'review_task_dialog.dart';
import '../animations/app_animations.dart';

class TaskDetailDialog extends StatefulWidget {
  final int taskId;
  final TaskItemModel? initialTask;
  final bool isReadOnly;
  final bool canCloneTask;
  final bool showOnlyCloneAndCancel;

  const TaskDetailDialog({
    super.key,
    required this.taskId,
    this.initialTask,
    this.isReadOnly = false,
    this.canCloneTask = true,
    this.showOnlyCloneAndCancel = false,
  });

  static Future<void> show(
    BuildContext context, {
    required int taskId,
    TaskItemModel? initialTask,
    bool isReadOnly = false,
    bool canCloneTask = true,
    bool showOnlyCloneAndCancel = false,
  }) {
    return showSmoothDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => TaskDetailDialog(
        taskId: taskId,
        initialTask: initialTask,
        isReadOnly: isReadOnly,
        canCloneTask: canCloneTask,
        showOnlyCloneAndCancel: showOnlyCloneAndCancel,
      ),
    );
  }

  @override
  State<TaskDetailDialog> createState() => _TaskDetailDialogState();
}

class _TaskDetailDialogState extends State<TaskDetailDialog> {
  final TaskRepository _repository = TaskRepository();
  final TextEditingController _commentController = TextEditingController();

  bool _isLoading = true;
  bool _hasReviewed = false;
  TaskDetailModel? _detail;
  List<TaskCommentModel> _comments = [];
  bool _sendingComment = false;
  final Set<int> _togglingChecklist = {};

  @override
  void initState() {
    super.initState();
    _fetchDetail();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      final list = await _repository.getTaskComments(widget.taskId);
      if (mounted) setState(() => _comments = list);
    } catch (e) {
      debugPrint('TaskDetailDialog error fetching comments: $e');
    }
  }

  Future<void> _sendComment() async {
    final txt = _commentController.text.trim();
    if (txt.isEmpty || _sendingComment) return;
    setState(() => _sendingComment = true);
    try {
      final list = await _repository.addTaskComment(widget.taskId, txt);
      if (!mounted) return;
      setState(() {
        _comments = list;
        _commentController.clear();
      });
      _fetchDetail();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.red600),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  Future<void> _toggleChecklist(TaskChecklistItemModel item, bool isWatcher) async {
    if (isWatcher) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Watchers have read-only access and cannot toggle checklist items')),
      );
      return;
    }
    if (_togglingChecklist.contains(item.id)) return;
    setState(() => _togglingChecklist.add(item.id));
    try {
      await _repository.toggleChecklistItem(item.id, !item.done);
      await _fetchDetail();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.red600),
        );
      }
    } finally {
      if (mounted) setState(() => _togglingChecklist.remove(item.id));
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    try {
      final detail = await _repository.getTaskDetail(widget.taskId);
      if (mounted) {
        setState(() {
          _detail = detail;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('TaskDetailDialog error fetching task detail: $e\n$stack');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDateStr(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty || dateStr == '—') return '—';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF8B5CF6);
    final cleanHex = hex.replaceFirst('#', '').replaceAll('0x', '');
    if (cleanHex.length == 6) {
      try {
        return Color(int.parse('FF$cleanHex', radix: 16));
      } catch (_) {
        return const Color(0xFF8B5CF6);
      }
    }
    return const Color(0xFF8B5CF6);
  }

  String _formatStatusLabel(String status) {
    if (status.isEmpty) return '—';
    switch (status.toLowerCase()) {
      case 'to_be_started':
        return 'To be Started';
      case 'in_progress':
        return 'In Progress';
      case 'blocked':
        return 'Blocked';
      case 'done':
        return 'Done (review)';
      case 'completed':
        return 'Completed';
      case 'scrapped':
        return 'Scrapped';
      case 'paused':
        return 'Paused';
      case 'overdue':
        return 'Overdue';
      default:
        return status.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'to_be_started':
        return Colors.blueGrey;
      case 'in_progress':
        return Colors.blue;
      case 'blocked':
        return Colors.red;
      case 'done':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'scrapped':
        return Colors.grey;
      case 'paused':
        return Colors.orange;
      case 'overdue':
        return Colors.red.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final authState = context.watch<AuthBloc>().state;
    final taskNo = _detail?.taskNo ?? widget.initialTask?.taskNo ?? 'Task';
    final title = _detail?.title ?? widget.initialTask?.title ?? '';
    final description = _detail?.description ?? widget.initialTask?.description ?? '';

    final parentTaskNo = _detail?.parentTaskNo ?? widget.initialTask?.parentTaskNo;
    final parentTaskId = _detail?.parentTaskId ?? widget.initialTask?.parentTaskId;
    final bool isSubtask = (_detail?.isSubtask ?? widget.initialTask?.isSubtask ?? false) ||
        (parentTaskId != null && parentTaskId > 0) ||
        (parentTaskNo != null && parentTaskNo.trim().isNotEmpty) ||
        RegExp(r'/\d+-\d+-\d+$').hasMatch(taskNo);

    int? ticketId = _detail?.ticketId ?? widget.initialTask?.ticketId;
    String? ticketNo = _detail?.ticketNo ?? widget.initialTask?.ticketNo;
    if ((ticketNo == null || ticketNo.isEmpty) && description.contains('Ticket TKT-')) {
      final regExp = RegExp(r'Ticket\s+(TKT-[A-Za-z0-9\-/]+)');
      final match = regExp.firstMatch(description);
      if (match != null) {
        ticketNo = match.group(1);
      }
    }
    final priority = _detail?.priority ?? widget.initialTask?.priority ?? 'high';
    final status = _detail?.status ?? widget.initialTask?.status ?? 'to_be_started';
    final statusLower = status.toLowerCase();
    final progress = _detail?.progress ?? widget.initialTask?.progress ?? 0;
    final branchName = _detail?.branchName ?? widget.initialTask?.branchName ?? '—';
    final assignedBy = _detail?.assignedByName ?? widget.initialTask?.assignedByName ?? '—';
    final rawDueDate = _detail?.dueDate ?? widget.initialTask?.dueDate;
    final entryDate = _formatDateStr(_detail?.entryDate ?? widget.initialTask?.entryDate);
    final dueDate = _formatDateStr(rawDueDate);
    final completedDate = _formatDateStr(_detail?.completedDate ?? widget.initialTask?.completedDate);

    bool isDateExpired = false;
    if (statusLower == 'overdue') {
      isDateExpired = true;
    } else if (rawDueDate != null && rawDueDate.trim().isNotEmpty) {
      try {
        final parsedDueDate = DateTime.parse(rawDueDate).toLocal();
        final now = DateTime.now();
        final endOfDueDay = DateTime(
          parsedDueDate.year,
          parsedDueDate.month,
          parsedDueDate.day,
          23,
          59,
          59,
        );
        isDateExpired = now.isAfter(endOfDueDay);
      } catch (_) {}
    }

    final category = _detail?.category ?? widget.initialTask?.category ?? 'General';
    final assignees = _detail?.assignees ?? widget.initialTask?.assignees ?? [];
    final reviewNote = _detail?.reviewComment ?? widget.initialTask?.reviewComment;
    final attachments = _detail?.attachments ?? [];
    final timeline = _detail?.timeline ?? [];

    // ---------- Permissions: same rules as the web task detail ----------
    final me = authState is AuthenticatedState ? authState.userProfile : null;
    final perms = me?.permissions ?? const <String>[];
    bool can(String p) => perms.contains(p);
    final assignedByUserId = _detail?.assignedByUserId ?? widget.initialTask?.assignedByUserId;
    final createdByUserId = _detail?.createdByUserId;
    final isAssigner = me != null && assignedByUserId == me.id;
    final isOwner = me != null && (assignedByUserId == me.id || createdByUserId == me.id);
    final isAssignee = me != null && assignees.any((a) => a.id == me.id);
    final watchers = _detail?.watchers ?? const <TaskAssigneeModel>[];
    final isWatcher = me != null &&
        !isOwner &&
        !isAssignee &&
        !can('task.manage') &&
        (watchers.any((w) => w.id == me.id) || (_detail?.isWatcherFlag ?? false));
    final checklistItems = _detail?.checklistItems ?? const <TaskChecklistItemModel>[];
    final pendingChecklist = checklistItems.where((c) => !c.done).length;
    final checklistComplete = pendingChecklist == 0;
    final subtaskList = _detail?.subtasks ?? const <TaskItemModel>[];
    final canAddSubtask = !isWatcher &&
        can('task.create') &&
        !isSubtask &&
        (isOwner || isAssignee) &&
        !['completed', 'scrapped'].contains(statusLower) &&
        !widget.isReadOnly &&
        !widget.showOnlyCloneAndCancel;
    final canReassign = !isWatcher &&
        (can('staff.view') || can('staff.manage') || isAssigner) &&
        !widget.isReadOnly &&
        !widget.showOnlyCloneAndCancel;

    Color priorityColor = Colors.amber.shade800;
    if (priority.toLowerCase().contains('emergency') || priority.toLowerCase().contains('high')) {
      priorityColor = Colors.red;
    } else if (priority.toLowerCase().contains('top')) {
      priorityColor = Colors.orange;
    } else if (priority.toLowerCase().contains('medium')) {
      priorityColor = Colors.blue;
    }

    if (_isLoading && _detail == null && widget.initialTask == null) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  AnimatedShimmerBox(width: 160, height: 22, borderRadius: 6),
                  AnimatedShimmerBox(width: 24, height: 24, borderRadius: 12),
                ],
              ),
              const SizedBox(height: 14),
              const AnimatedShimmerBox(width: double.infinity, height: 18, borderRadius: 6),
              const SizedBox(height: 10),
              Row(
                children: const [
                  AnimatedShimmerBox(width: 75, height: 20, borderRadius: 10),
                  SizedBox(width: 8),
                  AnimatedShimmerBox(width: 85, height: 20, borderRadius: 10),
                  SizedBox(width: 8),
                  AnimatedShimmerBox(width: 70, height: 20, borderRadius: 10),
                ],
              ),
              const SizedBox(height: 18),
              const AnimatedShimmerBox(width: double.infinity, height: 75, borderRadius: 10),
              const SizedBox(height: 16),
              const AnimatedShimmerBox(width: double.infinity, height: 42, borderRadius: 8),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  AnimatedShimmerBox(width: 80, height: 32, borderRadius: 8),
                  SizedBox(width: 10),
                  AnimatedShimmerBox(width: 90, height: 32, borderRadius: 8),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_detail == null && widget.initialTask == null) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Unable to load task details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                'There was a problem fetching the task details. Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(_hasReviewed),
                    child: Text(s.closeButton),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                      });
                      _fetchDetail();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1D2C),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Container(
        constraints: BoxConstraints(maxWidth: 580, maxHeight: MediaQuery.of(context).size.height * 0.92),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isWatcher) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.badgeBlueBg(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accentBlue(context)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.visibility_outlined, size: 16, color: AppColors.accentBlue(context)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(children: [
                            const TextSpan(text: 'Task Watcher (In CC)', style: TextStyle(fontWeight: FontWeight.w800)),
                            const TextSpan(
                                text:
                                    ' — You have observer access to view task details and track updates. Watchers cannot edit details or change the status.'),
                          ]),
                          style: TextStyle(fontSize: 12, color: AppColors.textPrimary(context)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // 1. Header Row with Close Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (taskNo.isNotEmpty && title.isNotEmpty) ? '$taskNo · $title' : (title.isNotEmpty ? title : taskNo),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                'Task ID $taskNo',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                                ),
                              ),
                            ),
                            if (isSubtask && parentTaskNo != null && parentTaskNo.isNotEmpty) ...[
                              InkWell(
                                onTap: parentTaskId != null
                                    ? () async {
                                        Navigator.of(context).pop(_hasReviewed);
                                        TaskDetailDialog.show(context, taskId: parentTaskId);
                                      }
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.4) : const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.subdirectory_arrow_right_rounded,
                                        size: 13,
                                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Sub-task of $parentTaskNo',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            PulsingBadge(
                              enabled: priority.toLowerCase().contains('emergency') || priority.toLowerCase().contains('high'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: priorityColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  priority.isNotEmpty ? priority[0].toUpperCase() + priority.substring(1) : '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: priorityColor,
                                  ),
                                ),
                              ),
                            ),
                            PulsingBadge(
                              enabled: statusLower == 'overdue',
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(color: _getStatusColor(status), shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatStatusLabel(status),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(status),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (branchName.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  branchName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (ticketNo != null && ticketNo.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).pop(_hasReviewed);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ComplaintsScreen(
                                    initialTicketId: ticketId,
                                    initialSearchQuery: ticketNo,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.3) : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF3B82F6).withOpacity(0.5) : const Color(0xFFBFDBFE),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🎫 ', style: TextStyle(fontSize: 12)),
                                  Text(
                                    ticketNo,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 13,
                                    color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(_hasReviewed),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 2. Dynamic Metadata Box (Priority, Status, Branch, Category, Assigned By, Entry Date, Due Date, Completed)
              StaggeredSlideFade(
                delay: const Duration(milliseconds: 70),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildMetaGridItem('Priority', priority.isNotEmpty ? (priority[0].toUpperCase() + priority.substring(1)) : '—', isDark, valueColor: priorityColor),
                          _buildMetaGridItem('Status', '${_formatStatusLabel(status)}${progress > 0 ? " · $progress%" : ""}', isDark, valueColor: Colors.blue),
                          _buildMetaGridItem('Branch', branchName.isNotEmpty ? branchName : '—', isDark),
                          _buildMetaGridItem('Category', category.isNotEmpty ? category : '—', isDark),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildMetaGridItem('Assigned by', assignedBy.isNotEmpty ? assignedBy : '—', isDark),
                          _buildMetaGridItem('Entry date', entryDate, isDark),
                          _buildMetaGridItem('Due date', dueDate, isDark, valueColor: Colors.amber),
                          _buildMetaGridItem('Completed', completedDate.isNotEmpty && completedDate != '—' ? completedDate : (statusLower == 'completed' ? entryDate : '—'), isDark, valueColor: Colors.green),
                        ],
                      ),
                      if (progress > 0 || statusLower == 'in_progress' || statusLower == 'completed' || statusLower == 'overdue') ...[
                        const SizedBox(height: 12),
                        AnimatedTaskProgressBar(
                          progress: statusLower == 'completed' ? 100 : progress,
                          showPercentage: true,
                          height: 6,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 3. Description Field
              if (description.isNotEmpty) ...[
                StaggeredSlideFade(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),

              // 5. Assignees Section with Reassign Button
              StaggeredSlideFade(
                delay: const Duration(milliseconds: 130),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Assignees', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ...assignees.take(2).map((a) {
                          final badgeColor = _hexToColor(a.color);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 8,
                                  backgroundColor: badgeColor,
                                  child: Text(
                                    a.initials.isNotEmpty ? a.initials : (a.name.isNotEmpty ? a.name[0].toUpperCase() : 'U'),
                                    style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  a.name,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (assignees.length > 2)
                          Tooltip(
                            message: assignees.skip(2).map((e) => e.name).join(', '),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white12 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '+${assignees.length - 2}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        if (canReassign)
                          ScaleTap(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final result = await ReassignTaskDialog.show(
                                  context,
                                  taskId: widget.taskId,
                                  currentAssignees: assignees,
                                );
                                if (result == true) {
                                  _fetchDetail();
                                }
                              },
                              icon: const Icon(Icons.sync, size: 13, color: Colors.white),
                              label: Text(
                                s.reassignButton,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B1D2C),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                visualDensity: VisualDensity.compact,
                                elevation: 0,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sub-tasks Section (ONLY FOR PARENT TASKS - hidden when viewing a sub-task)
              if (!isSubtask && (subtaskList.isNotEmpty || canAddSubtask)) ...[
                StaggeredSlideFade(
                  delay: const Duration(milliseconds: 160),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                s.subTasksTitle,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              if (_detail != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_detail!.subtasksCompleted}/${_detail!.subtasksTotal > 0 ? _detail!.subtasksTotal : _detail!.subtasks.length} ${s.completedLabel.toLowerCase()}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (canAddSubtask && !isDateExpired)
                            ScaleTap(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final taskDetail = _detail ??
                                      TaskDetailModel(
                                        id: widget.taskId,
                                        taskNo: taskNo,
                                        fy: '2025-26',
                                        title: title,
                                        description: description,
                                        category: category,
                                        priority: priority,
                                        status: status,
                                        progress: progress,
                                        entryDate: entryDate,
                                        dueDate: dueDate,
                                        isConfidential: false,
                                        assignedByText: assignedBy,
                                        assignedByUserId: 1,
                                        assignedByName: assignedBy,
                                        branchId: 1,
                                        branchCode: 'SS00',
                                        branchName: branchName,
                                        assignees: assignees,
                                        timeline: [],
                                        attachments: [],
                                        checklist: [],
                                      );
                                  final created = await AddSubTaskDialog.show(
                                    context,
                                    parentTask: taskDetail,
                                  );
                                  if (created != null && created != false) {
                                    if (created is TaskItemModel && _detail != null) {
                                      setState(() {
                                        final updatedList = List<TaskItemModel>.from(_detail!.subtasks);
                                        updatedList.insert(0, created);
                                        _detail = _detail!.copyWithSubtasks(updatedList);
                                      });
                                    }
                                    _fetchDetail();
                                  }
                                },
                                icon: const Icon(Icons.add, size: 14, color: Colors.white),
                                label: Text(
                                  s.addSubTaskButton,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B1D2C),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                  elevation: 0,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (_detail == null || _detail!.subtasks.isEmpty)
                        Text(
                          s.subTasksSubtitle,
                          style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                        ),
                      if (_detail != null && _detail!.subtasks.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ..._detail!.subtasks.map((st) {
                          return ScaleTap(
                            onTap: () async {
                              await TaskDetailDialog.show(context, taskId: st.id, initialTask: st);
                              _fetchDetail();
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Task ID ',
                                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                                      ),
                                      Text(
                                        st.taskNo,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          st.title,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(st.status).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 5,
                                              height: 5,
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(st.status),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatStatusLabel(st.status),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: _getStatusColor(st.status),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (st.assignees.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        CircleAvatar(
                                          radius: 9,
                                          backgroundColor: _hexToColor(st.assignees.first.color),
                                          child: Text(
                                            st.assignees.first.initials.isNotEmpty
                                                ? st.assignees.first.initials
                                                : (st.assignees.first.name.isNotEmpty
                                                    ? st.assignees.first.name[0].toUpperCase()
                                                    : 'U'),
                                            style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (st.dueDate.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_month_outlined, size: 12, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDateStr(st.dueDate),
                                          style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 5b. Watchers / CC
              if (watchers.isNotEmpty) ...[
                Text('Watchers / CC (${watchers.length})',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary(context))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: watchers
                      .map((w) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.chipBg(context),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility_outlined, size: 12, color: AppColors.accentBlue(context)),
                                const SizedBox(width: 4),
                                Text(w.name, style: TextStyle(fontSize: 11, color: AppColors.textPrimary(context))),
                              ],
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],

              // 5c. Checklist
              if (checklistItems.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Checklist (${checklistItems.length - pendingChecklist}/${checklistItems.length})',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary(context)),
                    ),
                    if (!checklistComplete)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.badgeYellowBg(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('all must be ticked to mark done',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.badgeYellowFg(context))),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                ...checklistItems.map((c) => InkWell(
                      onTap: () => _toggleChecklist(c, isWatcher || widget.isReadOnly),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                        child: Row(
                          children: [
                            _togglingChecklist.contains(c.id)
                                ? const SizedBox(width: 20, height: 20, child: AnimatedCircleProgressIndicator(size: 18))
                                : Icon(
                                    c.done ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                    size: 20,
                                    color: c.done ? AppColors.green600 : AppColors.textSecondary(context),
                                  ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.text,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: c.done ? AppColors.textSecondary(context) : AppColors.textPrimary(context),
                                  decoration: c.done ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 16),
              ],

              // 6. Attachments Section (Dynamic)
              if (attachments.isNotEmpty) ...[
                StaggeredSlideFade(
                  delay: const Duration(milliseconds: 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Attachments', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: attachments.map((att) {
                          String filename = 'File';
                          String contextTag = 'attachment';
                          String fileUrl = '';
                          if (att is Map) {
                            filename = att['filename']?.toString() ?? att['name']?.toString() ?? 'File';
                            contextTag = att['context']?.toString() ?? 'attachment';
                            fileUrl = att['url']?.toString() ?? att['path']?.toString() ?? '';
                          } else if (att is String) {
                            fileUrl = att;
                            filename = att.split('/').isNotEmpty ? att.split('/').last : 'File';
                            if (filename.isEmpty) filename = 'File';
                          }

                          return ScaleTap(
                            onTap: () {
                              if (fileUrl.isNotEmpty) {
                                final fullUrl = fileUrl.startsWith('http') ? fileUrl : 'https://dev-task-api.srivyn.in$fileUrl';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Opening attachment: $fullUrl')),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.attach_file_rounded, size: 13, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 160),
                                    child: Text(
                                      filename,
                                      style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      contextTag,
                                      style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 7. Review Note Section (Dynamic if present)
              if (reviewNote != null && reviewNote.isNotEmpty) ...[
                StaggeredSlideFade(
                  delay: const Duration(milliseconds: 240),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Review note', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                        ),
                        child: Text(
                          reviewNote,
                          style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : const Color(0xFF334155)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 8. Dynamic Timeline Section
              StaggeredSlideFade(
                delay: const Duration(milliseconds: 270),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Timeline', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),

                    if (_isLoading && timeline.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(12), child: AnimatedCircleProgressIndicator(size: 28)))
                    else if (timeline.isNotEmpty)
                      Column(
                        children: timeline.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                if (item.kind.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.kind,
                                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Text(
                                    item.note.isNotEmpty ? item.note : '—',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                                if (item.actor.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    item.actor,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('No timeline activity logged yet.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 9. Comments & discussion (GET/POST /tasks/{id}/comments)
              StaggeredSlideFade(
                delay: const Duration(milliseconds: 300),
                child: _buildCommentsSection(context, readOnly: widget.isReadOnly || widget.showOnlyCloneAndCancel),
              ),
            ],
          ),
        ),
            ),
            _buildFooter(
              context,
              taskNo: taskNo,
              title: title,
              reviewNote: reviewNote,
              statusLower: statusLower,
              isOwner: isOwner,
              isAssigner: isAssigner,
              isWatcher: isWatcher,
              canClone: can('task.create') && widget.canCloneTask,
              checklistComplete: checklistComplete,
              pendingChecklist: pendingChecklist,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(BuildContext context, {required bool readOnly}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Comments & discussion',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
            if (_comments.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(color: AppColors.chipBg(context), borderRadius: BorderRadius.circular(10)),
                child: Text('${_comments.length}',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary(context))),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (_comments.isEmpty)
          Text('No comments yet — start the conversation.',
              style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: AppColors.textSecondary(context)))
        else
          ..._comments.map((c) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.subtleBg(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: _hexToColor(c.avatarColor),
                      child: Text(c.initials,
                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.white)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(c.name,
                                  style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
                              Text(_formatCommentDate(c.createdAt),
                                  style: TextStyle(fontSize: 10, color: AppColors.textFaint(context))),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(c.body, style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary(context))),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        if (!readOnly) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary(context)),
                  decoration: InputDecoration(
                    hintText: 'Write a comment…',
                    hintStyle: TextStyle(fontSize: 12.5, color: AppColors.textFaint(context)),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.subtleBg(context),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: _sendingComment ? null : _sendComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary(context),
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _sendingComment
                      ? const SizedBox(width: 16, height: 16, child: AnimatedCircleProgressIndicator(size: 16))
                      : const Icon(Icons.send_rounded, size: 18),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  String _formatCommentDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('d MMM, HH:mm').format(dt.toLocal());
  }

  TaskItemModel _taskForDialogs() {
    return _detail ?? widget.initialTask!;
  }

  /// Footer — mirrors the web task detail footer:
  /// Edit (creator / assigner) · Clone (task.create) · Change Status · Request Help / Change ·
  /// ✓ Submit as Done (until done; needs checklist complete) · Review → (assigner, status done) · Close.
  /// Watchers only get Close. Stays pinned under the scrollable body on mobile.
  Widget _buildFooter(
    BuildContext context, {
    required String taskNo,
    required String title,
    required String? reviewNote,
    required String statusLower,
    required bool isOwner,
    required bool isAssigner,
    required bool isWatcher,
    required bool canClone,
    required bool checklistComplete,
    required int pendingChecklist,
  }) {
    final s = AppStrings.of(context);
    final hasTask = _detail != null || widget.initialTask != null;

    Widget outlined(String label, IconData icon, VoidCallback? onTap, {Color? iconColor}) => OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 15, color: iconColor),
          label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary(context),
            side: BorderSide(color: AppColors.border(context)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );

    final closeBtn = OutlinedButton(
      onPressed: () => Navigator.of(context).pop(_hasReviewed),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary(context),
        side: BorderSide(color: AppColors.border(context)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(s.closeButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    );

    final cloneBtn = outlined(s.cloneTaskTitle, Icons.content_copy_outlined, () {
      CloneTaskDialog.show(context, sourceTask: _detail, sourceItem: widget.initialTask);
    });

    final List<Widget> buttons = [];
    Widget? note;

    if (widget.showOnlyCloneAndCancel || widget.isReadOnly) {
      if (canClone || widget.showOnlyCloneAndCancel) buttons.add(cloneBtn);
    } else if (isWatcher) {
      note = Text(
        'Task Watcher mode — you can post comments, but status updates and edits are disabled.',
        style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: AppColors.textSecondary(context)),
      );
    } else if (hasTask) {
      if (isOwner && _detail != null) {
        buttons.add(outlined(s.editButton, Icons.edit_outlined, () async {
          final updated = await EditTaskDialog.show(context, task: _detail!);
          if (updated == true) _fetchDetail();
        }));
      }
      if (canClone) buttons.add(cloneBtn);
      buttons.add(outlined('Change Status', Icons.trending_up_rounded, () async {
        final moved = await MoveTaskDialog.show(context, task: _taskForDialogs());
        if (moved == true && mounted) _fetchDetail();
      }, iconColor: AppColors.accentBlue(context)));
      buttons.add(outlined('Request Help / Change', Icons.flag_outlined, () async {
        final done = await RaiseEscalationDialog.show(context, initialTask: _taskForDialogs());
        if (done == true && mounted) _fetchDetail();
      }, iconColor: AppColors.badgeYellowFg(context)));
      if (!['completed', 'done'].contains(statusLower)) {
        buttons.add(Tooltip(
          message: checklistComplete ? '' : 'Finish all $pendingChecklist checklist item(s) first',
          child: ElevatedButton.icon(
            onPressed: !checklistComplete
                ? null
                : () async {
                    final done = await MarkDoneDialog.show(context, task: _taskForDialogs());
                    if (done == true && mounted) _fetchDetail();
                  },
            icon: const Icon(Icons.check_circle_outline, size: 15),
            label: const Text('Submit as Done', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green600,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ));
      }
      if (statusLower == 'done' && isAssigner) {
        buttons.add(ElevatedButton(
          onPressed: () async {
            final updated = await ReviewTaskDialog.show(
              context,
              taskId: widget.taskId,
              taskNo: taskNo,
              title: title,
              assigneeNote: reviewNote,
            );
            if (updated != null && mounted) {
              setState(() {
                _detail = updated;
                _hasReviewed = true;
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary(context),
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Review →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ));
      }
    }

    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border(context)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (note != null) ...[note, const SizedBox(height: 8)],
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [...buttons, closeBtn],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaGridItem(String label, String value, bool isDark, {Color? valueColor}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
