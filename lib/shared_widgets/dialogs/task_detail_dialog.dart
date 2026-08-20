import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_strings.dart';
import '../../../modules/tasks/models/task_model.dart';
import '../../../modules/tasks/repository/task_repository.dart';

class TaskDetailDialog extends StatefulWidget {
  final int taskId;
  final TaskItemModel? initialTask;

  const TaskDetailDialog({
    super.key,
    required this.taskId,
    this.initialTask,
  });

  static Future<void> show(BuildContext context, {required int taskId, TaskItemModel? initialTask}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => TaskDetailDialog(taskId: taskId, initialTask: initialTask),
    );
  }

  @override
  State<TaskDetailDialog> createState() => _TaskDetailDialogState();
}

class _TaskDetailDialogState extends State<TaskDetailDialog> {
  final TaskRepository _repository = TaskRepository();
  bool _isLoading = true;
  TaskDetailModel? _detail;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
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
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDateTimeStr(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('d MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF3866D6);
    final cleanHex = hex.replaceFirst('#', '').replaceAll('0x', '');
    if (cleanHex.length == 6) {
      return Color(int.parse('FF$cleanHex', radix: 16));
    }
    return const Color(0xFF3866D6);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final taskNo = _detail?.taskNo ?? widget.initialTask?.taskNo ?? 'Task';
    final title = _detail?.title ?? widget.initialTask?.title ?? '';
    final description = _detail?.description ?? widget.initialTask?.description ?? '';
    final priority = _detail?.priority ?? widget.initialTask?.priority ?? 'high';
    final progress = _detail?.progress ?? widget.initialTask?.progress ?? 100;
    final branchCode = _detail?.branchCode ?? widget.initialTask?.branchCode ?? 'SS01';
    final branchName = _detail?.branchName ?? widget.initialTask?.branchName ?? 'Head Office';
    final assignedBy = _detail?.assignedByName ?? widget.initialTask?.assignedByName ?? 'Vamsi';
    final entryDate = _formatDateStr(_detail?.entryDate ?? widget.initialTask?.entryDate);
    final dueDate = _formatDateStr(_detail?.dueDate ?? widget.initialTask?.dueDate);
    final completedDate = _formatDateStr(_detail?.completedDate ?? widget.initialTask?.completedDate);
    final category = _detail?.category ?? widget.initialTask?.category ?? 'General';
    final location = _detail?.location ?? widget.initialTask?.location ?? '—';
    final assignees = _detail?.assignees ?? widget.initialTask?.assignees ?? [];

    Color priorityColor = Colors.amber.shade700;
    final pLower = priority.toLowerCase();
    if (pLower.contains('emergency')) {
      priorityColor = Colors.red;
    } else if (pLower.contains('top')) {
      priorityColor = Colors.orange;
    } else if (pLower.contains('medium')) {
      priorityColor = Colors.blue;
    } else if (pLower.contains('low')) {
      priorityColor = Colors.grey;
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF131C2E) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row
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
              const SizedBox(height: 12),

              // Badges Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      priority[0].toUpperCase() + priority.substring(1),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Completed - $progress%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      branchCode,
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description Container Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                ),
                child: Text(
                  description.isNotEmpty ? description : 'No description provided.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Grid Fields (3 Columns)
              Wrap(
                spacing: 24,
                runSpacing: 16,
                children: [
                  _buildGridItem(s.priorityHeader, priority[0].toUpperCase() + priority.substring(1), isDark: isDark),
                  _buildGridItem(s.statusHeader, 'Completed - $progress%', isDark: isDark),
                  _buildGridItem(s.branchHeader, branchName, isDark: isDark),
                  _buildGridItem(s.assignedByLabel, assignedBy, isDark: isDark),
                  _buildGridItem(s.entryDateLabel, entryDate, isDark: isDark),
                  _buildGridItem(s.dueHeader, dueDate, isDark: isDark, isHighlight: true),
                  _buildGridItem(s.completedLabel, completedDate, isDark: isDark),
                  _buildGridItem(s.categoryLabel, category, isDark: isDark),
                  _buildGridItem(s.locationLabel, location, isDark: isDark),
                ],
              ),
              const SizedBox(height: 16),

              // Assignees Row
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.assigneesLabel,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: assignees.map((a) {
                      final badgeColor = _hexToColor(a.color);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          a.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // Activity Timeline Section
              Text(
                s.activityLabel,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
              else if (_detail?.timeline.isNotEmpty == true)
                Column(
                  children: _detail!.timeline.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            _formatDateTimeStr(item.createdAt),
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                                ),
                                children: [
                                  TextSpan(
                                    text: '${item.actor} ',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: '· ${item.note}'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              else
                Column(
                  children: [
                    _buildTimelineRow('12 Aug 2026, 14:35', 'Vamsi', 'Assigned to 1 member(s)', isDark: isDark),
                    _buildTimelineRow('12 Aug 2026, 14:36', 'Narender', 'Status → done', isDark: isDark),
                    _buildTimelineRow('12 Aug 2026, 14:36', 'Vamsi', 'Status → completed', isDark: isDark),
                  ],
                ),

              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                  ),
                  child: Text(s.closeButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(String label, String value, {required bool isDark, bool isHighlight = false}) {
    return SizedBox(
      width: 180,
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
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight
                  ? Colors.red
                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(String timeStr, String actor, String note, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            timeStr,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
                children: [
                  TextSpan(
                    text: '$actor ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: '· $note'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
