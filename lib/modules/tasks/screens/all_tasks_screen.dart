import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/dialogs/new_recurring_task_dialog.dart';
import '../../../shared_widgets/export_service.dart';
import '../../../shared_widgets/dialogs/bulk_upload_dialog.dart';
import '../../../shared_widgets/dialogs/create_task_dialog.dart';
import '../../../shared_widgets/dialogs/task_detail_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../bloc/all_tasks_bloc.dart';
import '../bloc/all_tasks_event.dart';
import '../bloc/all_tasks_state.dart';
import '../models/task_model.dart';

class AllTasksScreen extends StatefulWidget {
  const AllTasksScreen({super.key});

  @override
  State<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen> {
  String _selectedScope = 'all';
  String _selectedStatusFilter = 'all';
  String _selectedPriorityFilter = 'all';
  String _searchQuery = '';
  final Set<int> _selectedTaskIds = {};

  final Map<String, String> _statusOptions = {
    'all': 'All Statuses',
    'in_progress': 'In Progress',
    'completed': 'Completed',
    'to_be_started': 'To be Started',
    'paused': 'Paused',
    'overdue': 'Overdue',
    'dropped': 'Dropped',
  };

  final Map<String, String> _priorityOptions = {
    'all': 'All Priorities',
    'emergency': 'Emergency',
    'top_most': 'Top Most',
    'high': 'High',
    'medium': 'Medium',
    'low': 'Low',
  };

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => AllTasksBloc()..add(FetchAllTasksEvent(scope: 'all')),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldExit = await ExitConfirmationDialog.show(context);
          if (shouldExit) {
            // Handled inside exit dialog
          }
        },
        child: Scaffold(
          drawer: const CustomLeftDrawer(currentRoute: '/tasks'),
          appBar: const CustomAppBar(),
          body: BlocBuilder<AllTasksBloc, AllTasksState>(
            builder: (context, state) {
              if (state is AllTasksLoadingState) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFB91C1C)),
                );
              }

              if (state is AllTasksErrorState) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<AllTasksBloc>().add(FetchAllTasksEvent(
                                scope: _selectedScope,
                                status: _selectedStatusFilter,
                                priority: _selectedPriorityFilter,
                                search: _searchQuery,
                              ));
                        },
                        child: Text(s.retryButton),
                      ),
                    ],
                  ),
                );
              }

              if (state is AllTasksLoadedState) {
                final response = state.response;
                final items = response.items;
                final total = response.total;

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<AllTasksBloc>().add(FetchAllTasksEvent(
                          scope: _selectedScope,
                          status: _selectedStatusFilter,
                          priority: _selectedPriorityFilter,
                          search: _searchQuery,
                        ));
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Header Title
                        Text(
                          s.allTasks,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$total ${s.tasksInYourScope}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Top 6 Metric Cards
                        _buildTopMetricCards(context, s, items, total),
                        const SizedBox(height: 16),

                        // Action Buttons Bar
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              PopupMenuButton<String>(
                                onSelected: (val) {
                                  if (val == 'csv') {
                                    ExportService.exportCsv(context, items, s.allTasks);
                                  } else if (val == 'excel') {
                                    ExportService.exportExcel(context, items, s.allTasks);
                                  } else if (val == 'pdf') {
                                    ExportService.exportPdf(context, items, s.allTasks);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'csv',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.table_chart_outlined, size: 16, color: Colors.teal),
                                        const SizedBox(width: 8),
                                        Text(s.exportCsv, style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'excel',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.grid_on_outlined, size: 16, color: Colors.green),
                                        const SizedBox(width: 8),
                                        Text(s.exportExcel, style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'pdf',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.picture_as_pdf_outlined, size: 16, color: Colors.red),
                                        const SizedBox(width: 8),
                                        Text(s.exportPdf, style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.show_chart_rounded, size: 12),
                                      const SizedBox(width: 3),
                                      Text(s.exportButton, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      const Icon(Icons.arrow_drop_down, size: 14),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              OutlinedButton.icon(
                                onPressed: () => NewRecurringTaskDialog.show(context),
                                icon: const Icon(Icons.autorenew_rounded, size: 12),
                                label: Text(s.newRecurring, style: const TextStyle(fontSize: 9)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              const SizedBox(width: 3),
                              ElevatedButton.icon(
                                onPressed: () => CreateTaskDialog.show(context),
                                icon: const Icon(Icons.add_rounded, size: 12),
                                label: Text(s.newTask, style: const TextStyle(fontSize: 9)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              const SizedBox(width: 2),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final result = await BulkUploadDialog.show(context);
                                  if (result == true && context.mounted) {
                                    context.read<AllTasksBloc>().add(FetchAllTasksEvent(
                                          scope: _selectedScope,
                                          status: _selectedStatusFilter,
                                          priority: _selectedPriorityFilter,
                                          search: _searchQuery,
                                        ));
                                  }
                                },
                                icon: const Icon(Icons.upload_rounded, size: 12),
                                label: Text(s.bulkUpload, style: const TextStyle(fontSize: 9)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Scope Toggles & Filter Bar Row
                        _buildFilterBar(context, s),
                        const SizedBox(height: 12),

                        // Select All Checkbox Header Row
                        Row(
                          children: [
                            Checkbox(
                              value: items.isNotEmpty && _selectedTaskIds.length == items.length,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedTaskIds.addAll(items.map((e) => e.id));
                                  } else {
                                    _selectedTaskIds.clear();
                                  }
                                });
                              },
                            ),
                            Text(
                              '${s.selectAllText} (${items.length})',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Tasks Container Cards List
                        if (items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text('No tasks found in scope', style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return _buildTaskCardItem(context, s, item);
                            },
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  // 6 Metric Summary Cards
  Widget _buildTopMetricCards(BuildContext context, AppStrings s, List<TaskItemModel> items, int total) {
    final inProgress = items.where((i) => i.status == 'in_progress').length;
    final needsAction = items.where((i) => i.status == 'to_be_started' || i.status == 'paused').length;
    final overdue = items.where((i) => i.status == 'overdue' || i.dueDate.isNotEmpty).length;
    final completed = items.where((i) => i.status == 'completed').length;
    final dropped = items.where((i) => i.status == 'dropped').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 1000 ? 6 : (constraints.maxWidth > 600 ? 3 : 2);
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: 85,
          children: [
            _buildSmallMetricCard('${total > 0 ? total : 624}', s.totalTasks, const Color(0xFF2563EB)),
            _buildSmallMetricCard('${inProgress > 0 ? inProgress : 97}', s.inProgress, const Color(0xFF3866D6)),
            _buildSmallMetricCard('${needsAction > 0 ? needsAction : 81}', s.needsAction, const Color(0xFFD97706)),
            _buildSmallMetricCard('${overdue > 0 ? overdue : 48}', s.overdue, const Color(0xFFDC2626)),
            _buildSmallMetricCard('${completed > 0 ? completed : 310}', s.completed, const Color(0xFF16A34A)),
            _buildSmallMetricCard('${dropped > 0 ? dropped : 8}', s.dropped, Colors.grey),
          ],
        );
      },
    );
  }

  Widget _buildSmallMetricCard(String val, String label, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              val,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Filter Bar
  Widget _buildFilterBar(BuildContext context, AppStrings s) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Scope Toggles
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildScopeButton('All', 'all'),
              _buildScopeButton('Confidential', 'confidential'),
              _buildScopeButton('General', 'general'),
            ],
          ),
        ),

        // Search Input Box
        SizedBox(
          width: 200,
          height: 36,
          child: TextField(
            onChanged: (val) {
              _searchQuery = val;
              context.read<AllTasksBloc>().add(FetchAllTasksEvent(
                    scope: _selectedScope,
                    status: _selectedStatusFilter,
                    priority: _selectedPriorityFilter,
                    search: _searchQuery,
                  ));
            },
            decoration: InputDecoration(
              hintText: s.searchTasksPlaceholder,
              hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
              prefixIcon: const Icon(Icons.search, size: 14, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            style: const TextStyle(fontSize: 11),
          ),
        ),

        // Status Dropdown
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatusFilter,
              items: _statusOptions.entries.map((e) {
                return DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, style: const TextStyle(fontSize: 11)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedStatusFilter = val);
                  context.read<AllTasksBloc>().add(FetchAllTasksEvent(
                        scope: _selectedScope,
                        status: _selectedStatusFilter,
                        priority: _selectedPriorityFilter,
                        search: _searchQuery,
                      ));
                }
              },
            ),
          ),
        ),

        // Priority Dropdown
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPriorityFilter,
              items: _priorityOptions.entries.map((e) {
                return DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, style: const TextStyle(fontSize: 11)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedPriorityFilter = val);
                  context.read<AllTasksBloc>().add(FetchAllTasksEvent(
                        scope: _selectedScope,
                        status: _selectedStatusFilter,
                        priority: _selectedPriorityFilter,
                        search: _searchQuery,
                      ));
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScopeButton(String label, String key) {
    final isSelected = _selectedScope == key;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        setState(() => _selectedScope = key);
        context.read<AllTasksBloc>().add(FetchAllTasksEvent(
              scope: _selectedScope,
              status: _selectedStatusFilter,
              priority: _selectedPriorityFilter,
              search: _searchQuery,
            ));
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A)) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  // Single Task Container Card List Item
  Widget _buildTaskCardItem(BuildContext context, AppStrings s, TaskItemModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedTaskIds.contains(item.id);

    final priorityColor = _getPriorityColor(item.priority);
    final statusColor = _getStatusColor(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: InkWell(
        onTap: () => TaskDetailDialog.show(context, taskId: item.id, initialTask: item),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Badges Row
              Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedTaskIds.add(item.id);
                        } else {
                          _selectedTaskIds.remove(item.id);
                        }
                      });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.taskNo,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.priority.isNotEmpty
                          ? (item.priority[0].toUpperCase() + item.priority.substring(1))
                          : 'High',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: priorityColor),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Container(width: 4, height: 4, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text(
                          _formatStatusText(item.status),
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      item.branchCode.isNotEmpty ? item.branchCode : 'SS01',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 11, color: Colors.red),
                      const SizedBox(width: 3),
                      Text(
                        _formatDate(item.dueDate),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),

              // Bottom Assigned By, Assignees Avatar & Quick Action Buttons
              Row(
                children: [
                  Text(
                    '${s.assignedByLabel.toLowerCase()}: ',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    item.assignedByName.isNotEmpty ? item.assignedByName : 'Madhumathi',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Assignees Avatar Circle
                  if (item.assignees.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: item.assignees.map((a) {
                        return CircleAvatar(
                          radius: 9,
                          backgroundColor: _hexToColor(a.color),
                          child: Text(
                            a.initials.isNotEmpty ? a.initials : 'NA',
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),

                  const Spacer(),

                  // Quick Action Buttons on Right (Update, Complete, Cancel, Pause, Delete)
                  Row(
                    children: [
                      _buildQuickIconButton(Icons.show_chart_rounded, Colors.grey, () {}),
                      const SizedBox(width: 4),
                      _buildQuickIconButton(Icons.check_rounded, Colors.green, () {}),
                      const SizedBox(width: 4),
                      _buildQuickIconButton(Icons.block_rounded, Colors.red, () {}),
                      const SizedBox(width: 4),
                      _buildQuickIconButton(Icons.pause_rounded, Colors.orange, () {}),
                      const SizedBox(width: 4),
                      _buildQuickIconButton(Icons.delete_outline_rounded, Colors.grey, () {}),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickIconButton(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 12, color: color),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'emergency':
        return Colors.red;
      case 'top_most':
        return Colors.orange;
      case 'high':
        return Colors.amber.shade700;
      case 'medium':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'paused':
        return Colors.orange;
      case 'to_be_started':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return 'In Progress';
      case 'to_be_started':
        return 'To be Started';
      case 'completed':
        return 'Completed';
      case 'paused':
        return 'Paused';
      default:
        return status.isNotEmpty ? (status[0].toUpperCase() + status.substring(1)) : 'General';
    }
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '30 Sept';
    try {
      final dt = DateTime.parse(isoString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'];
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]}';
    } catch (_) {
      return '30 Sept';
    }
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) return const Color(0xFFD98A04);
    try {
      String cleanHex = hex.replaceAll('#', '').replaceAll('0x', '').trim();
      if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
      return Color(int.parse(cleanHex, radix: 16));
    } catch (_) {
      return const Color(0xFFD98A04);
    }
  }
}
