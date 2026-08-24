import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_strings.dart';
import '../../../modules/dashboard/models/branch_model.dart';
import '../../../modules/tasks/models/task_model.dart';
import '../../../modules/tasks/repository/task_repository.dart';
import 'task_detail_dialog.dart';

class TasksDueTodayDialog extends StatefulWidget {
  final String? customTitle;
  final String? period;
  final String? priority;
  final bool? overdue;
  final String? overdueAge;
  final String? status;
  final Color? badgeColor;

  const TasksDueTodayDialog({
    super.key,
    this.customTitle,
    this.period,
    this.priority,
    this.overdue,
    this.overdueAge,
    this.status,
    this.badgeColor,
  });

  static Future<void> show(
    BuildContext context, {
    String? customTitle,
    String? period,
    String? priority,
    bool? overdue,
    String? overdueAge,
    String? status,
    Color? badgeColor,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => TasksDueTodayDialog(
        customTitle: customTitle,
        period: period,
        priority: priority,
        overdue: overdue,
        overdueAge: overdueAge,
        status: status,
        badgeColor: badgeColor,
      ),
    );
  }

  @override
  State<TasksDueTodayDialog> createState() => _TasksDueTodayDialogState();
}

class _TasksDueTodayDialogState extends State<TasksDueTodayDialog> {
  final TaskRepository _repository = TaskRepository();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  List<BranchModel> _branches = [];
  List<TaskItemModel> _items = [];
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _loadMoreData();
      }
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _repository.getBranches(),
        _repository.getTasks(
          scope: 'all',
          period: widget.period,
          priority: widget.priority,
          overdue: widget.overdue,
          overdueAge: widget.overdueAge,
          status: widget.status,
          limit: 50,
          offset: 0,
        ),
      ]);

      if (mounted) {
        final branches = results[0] as List<BranchModel>;
        final tasksRes = results[1] as TasksResponseModel;

        setState(() {
          _branches = branches;
          _items = List.from(tasksRes.items);
          _totalCount = tasksRes.total;
          _hasMore = _items.length < _totalCount;
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

  Future<void> _loadMoreData() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final res = await _repository.getTasks(
        scope: 'all',
        period: widget.period,
        priority: widget.priority,
        overdue: widget.overdue,
        overdueAge: widget.overdueAge,
        status: widget.status,
        limit: 50,
        offset: _items.length,
      );

      if (mounted) {
        setState(() {
          _items.addAll(res.items);
          _totalCount = res.total > 0 ? res.total : _totalCount;
          _hasMore = _items.length < _totalCount;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '19 Aug 2026';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dialogTitle = widget.customTitle ?? s.tasksDueTodayTitle;
    final totalToShow = _totalCount > 0 ? _totalCount : (_items.isNotEmpty ? _items.length : 10);
    final colorBadge = widget.badgeColor ?? (widget.overdue == true || (widget.priority?.contains('emergency') == true) ? Colors.red : Colors.green);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF131C2E) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 860),
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        dialogTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorBadge.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalToShow',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorBadge,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Controls Row (Showing count & Sort Controls)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing 1–${_items.isNotEmpty ? _items.length : (totalToShow > 50 ? 50 : totalToShow)} of $totalToShow',
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      const Text(
                        'Sort by',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: const [
                            Text(
                              'Entry date',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.arrow_downward_rounded, size: 12, color: Colors.black87),
                            SizedBox(width: 4),
                            Text(
                              'Desc',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Branch Legend Row
              Column(
                children: [
                  Text(
                    s.branchLegendLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Wrap(
                    spacing: 12,
                    children: _branches.map((b) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              b.code,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            b.name,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Task Container Cards List
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_items.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No tasks found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _items[index];

                    final isCompleted = item.status.toLowerCase().contains('completed');
                    Color priorityColor = Colors.amber.shade700;
                    final pLower = item.priority.toLowerCase();
                    if (pLower.contains('emergency')) {
                      priorityColor = Colors.red;
                    } else if (pLower.contains('top')) {
                      priorityColor = Colors.orange;
                    } else if (pLower.contains('medium')) {
                      priorityColor = Colors.blue;
                    } else if (pLower.contains('low')) {
                      priorityColor = Colors.grey;
                    }

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          TaskDetailDialog.show(context, taskId: item.id, initialTask: item);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Badges Row
                              Row(
                                children: [
                                  Text(
                                    item.taskNo,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      item.branchCode.isNotEmpty ? item.branchCode : 'SS01',
                                      style: const TextStyle(
                                        fontSize: 7,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: priorityColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.priority.isNotEmpty
                                          ? (item.priority[0].toUpperCase() + item.priority.substring(1))
                                          : 'High',
                                      style: TextStyle(
                                        fontSize: 7,
                                        fontWeight: FontWeight.bold,
                                        color: priorityColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? Colors.green.withValues(alpha: 0.12)
                                          : Colors.grey.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 5,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            color: isCompleted ? Colors.green : Colors.grey,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          isCompleted ? 'Completed' : 'To be Started',
                                          style: TextStyle(
                                            fontSize: 7,
                                            fontWeight: FontWeight.bold,
                                            color: isCompleted ? Colors.green : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // const Spacer(),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 7, color: Colors.red),
                                      const SizedBox(width: 3),
                                      Text(
                                        _formatDate(item.dueDate),
                                        style: const TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Title Row
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                              if (item.description.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  item.description,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 8),

                              // Bottom Row (Assigned By & Assignees)
                              Row(
                                children: [
                                  Text(
                                    '${s.assignedByLabel}: ',
                                    style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                  Text(
                                    item.assignedByName.isNotEmpty ? item.assignedByName : 'Vamsi',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    ),
                                  ),
                                  if (item.assignees.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '${s.assigneesLabel}: ',
                                      style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.grey),
                                    ),
                                    Wrap(
                                      spacing: 4,
                                      children: item.assignees.map((a) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3866D6).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            a.name,
                                            style: const TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF3866D6),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

              if (_isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
