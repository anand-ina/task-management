import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_strings.dart';
import '../../../modules/auth/bloc/auth_bloc.dart';
import '../../../modules/auth/bloc/auth_state.dart';
import '../../../modules/tasks/models/task_model.dart';
import '../../../modules/tasks/repository/task_repository.dart';
import 'mark_done_dialog.dart';
import 'move_task_dialog.dart';
import 'raise_escalation_dialog.dart';
import 'reassign_task_dialog.dart';


class TaskDetailDialog extends StatefulWidget {
  final int taskId;
  final TaskItemModel? initialTask;
  final bool isReadOnly;

  const TaskDetailDialog({
    super.key,
    required this.taskId,
    this.initialTask,
    this.isReadOnly = false,
  });

  static Future<void> show(
    BuildContext context, {
    required int taskId,
    TaskItemModel? initialTask,
    bool isReadOnly = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => TaskDetailDialog(
        taskId: taskId,
        initialTask: initialTask,
        isReadOnly: isReadOnly,
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
  TaskDetailModel? _detail;
  final List<Map<String, dynamic>> _postedComments = [];

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    try {
      final res = await _repository.getTaskDetail(widget.taskId);
      if (mounted) {
        setState(() {
          _detail = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDateStr(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('d MMM').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF8B5CF6);
    final cleanHex = hex.replaceFirst('#', '').replaceAll('0x', '');
    if (cleanHex.length == 6) {
      return Color(int.parse('FF$cleanHex', radix: 16));
    }
    return const Color(0xFF8B5CF6);
  }

  String _formatStatusLabel(String status) {
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
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final authState = context.watch<AuthBloc>().state;
    bool isTeamLead = false;
    bool isAcademicExecutive = false;
    if (authState is AuthenticatedState) {
      final role = authState.userProfile.role.toLowerCase();
      final roleLabel = authState.userProfile.roleLabel.toLowerCase();
      final email = authState.userProfile.email.toLowerCase();
      if (roleLabel.contains('team lead') || roleLabel.contains('tl') || role.contains('team_lead') || role.contains('tl')) {
        isTeamLead = true;
      }
      if (role.contains('executive') || role.contains('ae') || roleLabel.contains('executive') || roleLabel.contains('ae') || email.contains('sushma')) {
        isAcademicExecutive = true;
      }
    }

    final taskNo = _detail?.taskNo ?? widget.initialTask?.taskNo ?? 'Task';
    final title = _detail?.title ?? widget.initialTask?.title ?? '';
    final description = _detail?.description ?? widget.initialTask?.description ?? '';
    final priority = _detail?.priority ?? widget.initialTask?.priority ?? 'high';
    final status = _detail?.status ?? widget.initialTask?.status ?? 'to_be_started';
    final progress = _detail?.progress ?? widget.initialTask?.progress ?? 0;
    final branchName = _detail?.branchName ?? widget.initialTask?.branchName ?? 'Head Office';
    final assignedBy = _detail?.assignedByName ?? widget.initialTask?.assignedByName ?? 'Test_Manager';
    final entryDate = _formatDateStr(_detail?.entryDate ?? widget.initialTask?.entryDate);
    final dueDate = _formatDateStr(_detail?.dueDate ?? widget.initialTask?.dueDate);
    final completedDate = _formatDateStr(_detail?.completedDate ?? widget.initialTask?.completedDate);
    final category = _detail?.category ?? widget.initialTask?.category ?? 'General';
    final assignees = _detail?.assignees ?? widget.initialTask?.assignees ?? [];
    final reviewNote = _detail?.reviewComment ?? widget.initialTask?.reviewComment;
    final attachments = _detail?.attachments ?? [];
    final timeline = _detail?.timeline ?? [];

    Color priorityColor = Colors.amber.shade800;
    if (priority.toLowerCase().contains('emergency') || priority.toLowerCase().contains('high')) {
      priorityColor = Colors.red;
    } else if (priority.toLowerCase().contains('top')) {
      priorityColor = Colors.orange;
    } else if (priority.toLowerCase().contains('medium')) {
      priorityColor = Colors.blue;
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        padding: const EdgeInsets.all(14),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Header Row with Close Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '$taskNo · $title',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 2. Dynamic Metadata Box (Priority, Status, Branch, Category, Assigned By, Entry Date, Due Date, Completed)
              Container(
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
                        _buildMetaGridItem('Priority', priority[0].toUpperCase() + priority.substring(1), isDark, valueColor: priorityColor),
                        _buildMetaGridItem('Status', '${_formatStatusLabel(status)}${progress > 0 ? " · $progress%" : ""}', isDark, valueColor: Colors.blue),
                        _buildMetaGridItem('Branch', branchName, isDark),
                        _buildMetaGridItem('Category', category, isDark),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildMetaGridItem('Assigned by', assignedBy, isDark),
                        _buildMetaGridItem('Entry date', entryDate.isNotEmpty ? entryDate : '24 Aug 2026', isDark),
                        _buildMetaGridItem('Due date', dueDate.isNotEmpty ? dueDate : '31 Aug 2026', isDark, valueColor: Colors.amber),
                        _buildMetaGridItem('Completed', completedDate.isNotEmpty && completedDate != '—' ? completedDate : (status.toLowerCase() == 'completed' ? '24 Aug 2026' : '—'), isDark, valueColor: Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Description Field
              if (description.isNotEmpty) ...[
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),

              // 5. Assignees Section with Reassign Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Assignees', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  if (!widget.isReadOnly && !isAcademicExecutive) ...[
                    InkWell(
                      onTap: () async {
                        final result = await ReassignTaskDialog.show(
                          context,
                          taskId: widget.taskId,
                          currentAssignees: assignees,
                        );
                        if (result == true) {
                          _fetchDetail();
                        }
                      },
                      child: const Text(
                        'Reassign',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Wrap(
                    spacing: 6,
                    children: assignees.map((a) {
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
                                a.initials.isNotEmpty ? a.initials : 'U',
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
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 6. Attachments Section (Dynamic)
              if (attachments.isNotEmpty) ...[
                const Text('Attachments', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: attachments.map((att) {
                    final filename = att['filename']?.toString() ?? 'File';
                    final contextTag = att['context']?.toString() ?? 'creation';
                    final fileUrl = att['url']?.toString() ?? '';

                    return InkWell(
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
                            Text(
                              filename,
                              style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600),
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
                const SizedBox(height: 16),
              ],

              // 7. Review Note Section (Dynamic if present)
              if (reviewNote != null && reviewNote.isNotEmpty) ...[
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
                const SizedBox(height: 16),
              ],

              // 8. Dynamic Timeline Section
              const Text('Timeline', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
              else if (timeline.isNotEmpty)
                Column(
                  children: timeline.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
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
                          Expanded(
                            child: Text(
                              item.note,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                            ),
                          ),
                          Text(
                            item.actor,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
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

              const SizedBox(height: 16),

              // 9. Comments Section
              Text(
                'Comments${_postedComments.isNotEmpty ? " (${_postedComments.length})" : ""}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 6),

              if (_postedComments.isNotEmpty)
                Column(
                  children: _postedComments.map((c) {
                    final initials = c['initials']?.toString() ?? 'SA';
                    final name = c['name']?.toString() ?? 'Test_AE';
                    final body = c['body']?.toString() ?? '';
                    final colorHex = c['avatar_color']?.toString() ?? '#8b5cf6';
                    final dateStr = DateFormat('d MMM, HH:mm').format(DateTime.now());

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
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
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: _hexToColor(colorHex),
                                child: Text(
                                  initials,
                                  style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text(dateStr, style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(body, style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : const Color(0xFF334155))),
                        ],
                      ),
                    );
                  }).toList(),
                )
              else
                Text(
                  'No comments yet — start the conversation.',
                  style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
                ),
              const SizedBox(height: 2),
              Text(
                'Type @ then a name to mention anyone — they get notified.',
                style: TextStyle(fontSize: 9.5, color: isDark ? Colors.grey[500] : Colors.grey.shade500),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        hintText: 'Write a comment... type @ to mention someone',
                        hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  if (!widget.isReadOnly) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        final txt = _commentController.text.trim();
                        if (txt.isNotEmpty) {
                          setState(() {
                            _postedComments.add({
                              'initials': 'SA',
                              'name': 'Test_AE',
                              'body': txt,
                              'avatar_color': '#8b5cf6',
                            });
                            _commentController.clear();
                          });
                        }
                      },
                      child: const Text('Send', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // 10. Footer Action Buttons Bar
              if (widget.isReadOnly) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                      ),
                      child: Text(s.closeButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ] else ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final taskItem = _detail ??
                              widget.initialTask ??
                              TaskItemModel(
                                id: widget.taskId,
                                taskNo: taskNo,
                                fy: '2026-27',
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
                              );
                          await MoveTaskDialog.show(context, task: taskItem);
                        },
                        icon: const Icon(Icons.trending_up_rounded, size: 14, color: Colors.blue),
                        label: const Text('📈 Update / Move', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await RaiseEscalationDialog.show(context);
                        },
                        icon: const Icon(Icons.flag_outlined, size: 14, color: Colors.amber),
                        label: const Text('⚑ Raise Request', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isTeamLead) ...[
                        ElevatedButton.icon(
                          onPressed: () async {
                            final taskItem = _detail ??
                                widget.initialTask ??
                                TaskItemModel(
                                  id: widget.taskId,
                                  taskNo: taskNo,
                                  fy: '2026-27',
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
                                );
                            await MarkDoneDialog.show(context, task: taskItem);
                          },
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                          label: const Text('✓ Mark Done', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                        ),
                        child: Text(s.closeButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
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
