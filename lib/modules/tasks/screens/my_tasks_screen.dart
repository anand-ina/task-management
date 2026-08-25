import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/dialogs/task_detail_dialog.dart';
import '../../../shared_widgets/dialogs/bulk_actions_dialog.dart';
import '../../../shared_widgets/dialogs/move_task_dialog.dart';
import '../../../shared_widgets/dialogs/mark_done_dialog.dart';
import '../../../shared_widgets/dialogs/create_task_dialog.dart';
import '../../../shared_widgets/export_service.dart';
import '../../../shared_widgets/dialogs/bulk_upload_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/all_tasks_bloc.dart';
import '../bloc/all_tasks_event.dart';
import '../bloc/all_tasks_state.dart';
import '../models/task_model.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  String _selectedScope = 'all';
  String _selectedStatusFilter = 'all';
  String _selectedPriorityFilter = 'all';
  String _searchQuery = '';
  String _selectedView = 'list';
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

    final authState = context.watch<AuthBloc>().state;
    bool isAcademicExecutive = false;
    if (authState is AuthenticatedState) {
      final role = authState.userProfile.role.toLowerCase();
      final roleLabel = authState.userProfile.roleLabel.toLowerCase();
      final email = authState.userProfile.email.toLowerCase();
      if (role.contains('executive') || role.contains('ae') || roleLabel.contains('executive') || roleLabel.contains('ae') || email.contains('sushma')) {
        isAcademicExecutive = true;
      }
    }

    return BlocProvider(
      create: (context) => AllTasksBloc()..add(FetchAllTasksEvent(scope: 'mine')),
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
          drawer: const CustomLeftDrawer(currentRoute: '/my-tasks'),
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
                                scope: 'mine',
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
                final rawItems = response.items;
                final total = response.total;

                final items = rawItems.where((item) {
                  if (_selectedScope == 'confidential') {
                    return item.isConfidential ||
                        item.category.toLowerCase().contains('confidential') ||
                        item.title.toLowerCase().contains('confidential');
                  } else if (_selectedScope == 'general') {
                    return !item.isConfidential &&
                        !item.category.toLowerCase().contains('confidential');
                  }
                  return true;
                }).toList();

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<AllTasksBloc>().add(FetchAllTasksEvent(
                          scope: 'mine',
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
                          s.myTasks,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${total > 0 ? total : 0} ${s.tasksAssignedToOrCreatedByYou}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Top 6 Metric Summary Cards
                        _buildTopMetricCards(context, s, items, total),
                        const SizedBox(height: 16),

                        // View Toggles & Action Buttons Row
                        Column(
                          children: [
                            // View Toggles (List, Board, Calendar)
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                // mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildViewButton(Icons.menu_rounded, s.listView, 'list'),Spacer(),
                                  _buildViewButton(Icons.grid_view_rounded, s.boardView, 'board'),Spacer(),
                                  _buildViewButton(Icons.calendar_today_rounded, s.calendarView, 'calendar'),
                                ],
                              ),
                            ),
                            SizedBox(height: 10,),
                            // const Spacer(),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  PopupMenuButton<String>(
                                    onSelected: (val) {
                                      if (val == 'csv') {
                                        ExportService.exportCsv(context, items, s.myTasks);
                                      } else if (val == 'excel') {
                                        ExportService.exportExcel(context, items, s.myTasks);
                                      } else if (val == 'pdf') {
                                        ExportService.exportPdf(context, items, s.myTasks);
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
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.show_chart_rounded, size: 14),
                                          const SizedBox(width: 4),
                                          Text(s.exportButton, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          const Icon(Icons.arrow_drop_down, size: 16),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => CreateTaskDialog.show(context),
                                    icon: const Icon(Icons.add_rounded, size: 14),
                                    label: Text(s.newTask, style: const TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0F172A),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  if (!isAcademicExecutive) ...[
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        final result = await BulkUploadDialog.show(context);
                                        if (result == true && context.mounted) {
                                          context.read<AllTasksBloc>().add(FetchAllTasksEvent(
                                                scope: 'mine',
                                                status: _selectedStatusFilter,
                                                priority: _selectedPriorityFilter,
                                                search: _searchQuery,
                                              ));
                                        }
                                      },
                                      icon: const Icon(Icons.upload_rounded, size: 14),
                                      label: Text(s.bulkUpload, style: const TextStyle(fontSize: 11)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                          ],
                        ),
                        const SizedBox(height: 16),

                        // Scope Toggles & Filter Bar Row
                        _buildFilterBar(context, s),
                        const SizedBox(height: 12),

                        // Bulk Actions Selection Header Bar or Select All Row
                        if (_selectedTaskIds.isNotEmpty)
                          _buildBulkSelectionHeader(context, s, items)
                        else
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
                                '${s.selectAllText} (${items.isNotEmpty ? items.length : 0})',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),

                        // Tasks Container (List, Board, or Calendar View)
                        if (items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text('No tasks assigned to or created by you', style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        else if (_selectedView == 'board')
                          _buildBoardView(context, s, items)
                        else if (_selectedView == 'calendar')
                          _buildCalendarView(context, s, items)
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

  Widget _buildViewButton(IconData icon, String label, String key) {
    final isSelected = _selectedView == key;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _selectedView = key),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF1E293B) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? const Color(0xFF0F172A) : Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? (isDark ? Colors.white : const Color(0xFF0F172A)) : Colors.grey,
              ),
            ),
          ],
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
            _buildSmallMetricCard('${total > 0 ? total : 0}', s.totalTasks, const Color(0xFF2563EB)),
            _buildSmallMetricCard('${inProgress > 0 ? inProgress : 0}', s.inProgress, const Color(0xFF3866D6)),
            _buildSmallMetricCard('${needsAction > 0 ? needsAction : 0}', s.needsAction, const Color(0xFFD97706)),
            _buildSmallMetricCard('${overdue > 0 ? overdue : 0}', s.overdue, const Color(0xFFDC2626)),
            _buildSmallMetricCard('${completed > 0 ? completed : 0}', s.completed, const Color(0xFF16A34A)),
            _buildSmallMetricCard('${dropped > 0 ? dropped : 0}', s.dropped, Colors.grey),
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
              SizedBox(width: 10,),
              SizedBox(
                width: 130,
                height: 36,
                child: TextField(
                  onChanged: (val) {
                    _searchQuery = val;
                    context.read<AllTasksBloc>().add(FetchAllTasksEvent(
                      scope: 'mine',
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
            ],
          ),
        ),

        // Search Input Box


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
                        scope: 'mine',
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
                        scope: 'mine',
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
              scope: 'mine',
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
          padding: const EdgeInsets.all(10),
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
                  const SizedBox(width: 2),
                  Text(
                    item.taskNo,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.priority.isNotEmpty
                          ? (item.priority[0].toUpperCase() + item.priority.substring(1))
                          : 'Emergency',
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

              // Bottom Assigned By & Assignees
              Row(
                children: [
                  Text(
                    '${s.assignedByLabel.toLowerCase()}: ',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  _buildAssignedByWithCount(context, item),
                  const Spacer(),

                  // Quick Action Buttons on Right
                  Row(
                    children: [
                      // Move Task Button (show_chart_rounded)
                      _buildQuickIconButton(Icons.show_chart_rounded, Colors.blue, () async {
                        final res = await MoveTaskDialog.show(context, task: item);
                        if (res == true && context.mounted) {
                          context.read<AllTasksBloc>().add(FetchAllTasksEvent(
                                scope: 'mine',
                                status: _selectedStatusFilter,
                                priority: _selectedPriorityFilter,
                                search: _searchQuery,
                              ));
                        }
                      }),
                      const SizedBox(width: 4),

                      // Mark Done / Send to Review Button (check_rounded)
                      _buildQuickIconButton(Icons.check_rounded, Colors.green, () async {
                        final res = await MarkDoneDialog.show(context, task: item);
                        if (res == true && context.mounted) {
                          context.read<AllTasksBloc>().add(FetchAllTasksEvent(
                                scope: 'mine',
                                status: _selectedStatusFilter,
                                priority: _selectedPriorityFilter,
                                search: _searchQuery,
                              ));
                        }
                      }),
                      const SizedBox(width: 4),

                      // Block Task Button (block_rounded)
                      _buildQuickIconButton(Icons.block_rounded, Colors.red, () async {
                        final res = await MoveTaskDialog.show(context, task: item, initialStatus: 'blocked');
                        if (res == true && context.mounted) {
                          context.read<AllTasksBloc>().add(FetchAllTasksEvent(
                                scope: 'mine',
                                status: _selectedStatusFilter,
                                priority: _selectedPriorityFilter,
                                search: _searchQuery,
                              ));
                        }
                      }),
                      const SizedBox(width: 4),

                      // Pause Task Button (pause_rounded)
                      _buildQuickIconButton(Icons.pause_rounded, Colors.orange, () async {
                        try {
                          await DioClient().dio.patch('${ApiConstants.tasks}/${item.id}', data: {'status': 'paused'});
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Task paused successfully!'), backgroundColor: Colors.orange),
                            );
                            context.read<AllTasksBloc>().add(FetchAllTasksEvent(
                                  scope: 'mine',
                                  status: _selectedStatusFilter,
                                  priority: _selectedPriorityFilter,
                                  search: _searchQuery,
                                ));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to pause task: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      }),
                      const SizedBox(width: 4),

                      // Scrap / Delete Task Button (delete_outline_rounded)
                      _buildQuickIconButton(Icons.delete_outline_rounded, Colors.grey, () async {
                        try {
                          await DioClient().dio.patch('${ApiConstants.tasks}/${item.id}', data: {'status': 'scrapped'});
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Task scrapped successfully!'), backgroundColor: Colors.grey),
                            );
                            context.read<AllTasksBloc>().add(FetchAllTasksEvent(
                                  scope: 'mine',
                                  status: _selectedStatusFilter,
                                  priority: _selectedPriorityFilter,
                                  search: _searchQuery,
                                ));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to scrap task: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      }),
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

  Widget _buildAssignedByWithCount(BuildContext context, TaskItemModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assignees = item.assignees;

    String primaryName = item.assignedByName.isNotEmpty ? item.assignedByName : 'Vamsi';
    if (assignees.isNotEmpty && assignees.first.name.isNotEmpty) {
      primaryName = assignees.first.name;
    }

    if (assignees.length <= 1) {
      return Text(
        primaryName,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : const Color(0xFF334155),
        ),
      );
    }

    final remainingCount = assignees.length - 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          primaryName,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          tooltip: 'Show all assignees',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          offset: const Offset(0, 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '+$remainingCount',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          itemBuilder: (context) {
            return assignees.map((a) {
              return PopupMenuItem<String>(
                enabled: false,
                height: 32,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: _hexToColor(a.color),
                      child: Text(
                        a.initials.isNotEmpty ? a.initials : 'AN',
                        style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      a.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
        ),
      ],
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
      case 'done':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'paused':
        return Colors.orange;
      case 'to_be_started':
        return Colors.grey;
      default:
        return Colors.teal;
    }
  }

  String _formatStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return 'Done (in review)';
      case 'in_progress':
        return 'In Progress';
      case 'to_be_started':
        return 'To be Started';
      case 'completed':
        return 'Completed';
      case 'paused':
        return 'Paused';
      default:
        return status.isNotEmpty ? (status[0].toUpperCase() + status.substring(1)) : 'Done (in review)';
    }
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '01 Dec';
    try {
      final dt = DateTime.parse(isoString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'];
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]}';
    } catch (_) {
      return '01 Dec';
    }
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) return const Color(0xFF0E9AA7);
    try {
      String cleanHex = hex.replaceAll('#', '').replaceAll('0x', '').trim();
      if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
      return Color(int.parse(cleanHex, radix: 16));
    } catch (_) {
      return const Color(0xFF0E9AA7);
    }
  }

  Widget _buildBulkSelectionHeader(BuildContext context, AppStrings s, List<TaskItemModel> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCount = _selectedTaskIds.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: Checkbox(
              value: items.isNotEmpty && _selectedTaskIds.length == items.length,
              activeColor: const Color(0xFF0F172A),
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
          ),
          const SizedBox(width: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$selectedCount selected',
              style: const TextStyle(fontSize: 6, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 5),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.settings_outlined, size: 14),
            label: const Text('Bulk actions', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
            onPressed: () async {
              final result = await BulkActionsDialog.show(
                context,
                selectedTaskIds: _selectedTaskIds.toList(),
              );
              if (result == true) {
                setState(() => _selectedTaskIds.clear());
                if (context.mounted) {
                  context.read<AllTasksBloc>().add(FetchAllTasksEvent(
                        scope: 'mine',
                        status: _selectedStatusFilter,
                        priority: _selectedPriorityFilter,
                        search: _searchQuery,
                      ));
                }
              }
            },
          ),
          const SizedBox(width: 3),
          PopupMenuButton<String>(
            onSelected: (val) {
              final selectedTasks = items.where((task) => _selectedTaskIds.contains(task.id)).toList();
              if (selectedTasks.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No selected tasks to export.')),
                );
                return;
              }
              final exportTitle = '${s.myTasks}_Selected';
              if (val == 'csv') {
                ExportService.exportCsv(context, selectedTasks, exportTitle);
              } else if (val == 'excel') {
                ExportService.exportExcel(context, selectedTasks, exportTitle);
              } else if (val == 'pdf') {
                ExportService.exportPdf(context, selectedTasks, exportTitle);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    const Icon(Icons.table_chart_outlined, size: 16, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text(s.exportCsv),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(s.exportExcel),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(s.exportPdf),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? Colors.white38 : Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.north_east_rounded, size: 12),
                  SizedBox(width: 3),
                  Text('Export selected', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_drop_down, size: 14),
                ],
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() => _selectedTaskIds.clear()),
            child: const Text('Clear', style: TextStyle(fontSize: 8, color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Kanban Board View matching Image 1
  Widget _buildBoardView(BuildContext context, AppStrings s, List<TaskItemModel> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final columns = [
      {'key': 'to_be_started', 'label': 'TO BE STARTED', 'color': Colors.grey},
      {'key': 'in_progress', 'label': 'IN PROGRESS', 'color': Colors.blue},
      {'key': 'blocked', 'label': 'BLOCKED', 'color': Colors.red},
      {'key': 'done', 'label': 'DONE (REVIEW)', 'color': Colors.teal},
      {'key': 'completed', 'label': 'COMPLETED', 'color': Colors.green},
      {'key': 'dropped', 'label': 'DROPPED', 'color': Colors.grey},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columns.map((col) {
          final colKey = col['key'] as String;
          final colLabel = col['label'] as String;
          final colColor = col['color'] as Color;

          final colTasks = items.where((t) {
            final st = t.status.toLowerCase();
            if (colKey == 'done') return st == 'done' || st.contains('review');
            if (colKey == 'to_be_started') return st == 'to_be_started' || st == 'pending';
            return st == colKey;
          }).toList();

          return Container(
            width: 250,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Column Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: colColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          colLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${colTasks.length}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Cards inside column
                if (colTasks.isEmpty)
                  Container(
                    height: 100,
                    alignment: Alignment.center,
                    child: Text(
                      'Drop here',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.black26),
                    ),
                  )
                else
                  Column(
                    children: colTasks.map((task) {
                      final pColor = _getPriorityColor(task.priority);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        child: InkWell(
                          onTap: () => TaskDetailDialog.show(context, taskId: task.id, initialTask: task),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.taskNo,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  task.title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        task.branchCode.isNotEmpty ? task.branchCode : 'SS00',
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: pColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        task.priority.isNotEmpty ? (task.priority[0].toUpperCase() + task.priority.substring(1)) : 'High',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: pColor),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatDate(task.dueDate),
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: task.dueDate.isNotEmpty ? Colors.amber.shade800 : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Calendar View matching Image 2
  Widget _buildCalendarView(BuildContext context, AppStrings s, List<TaskItemModel> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month Title Header with Navigation Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'August 2026',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('<', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 4),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Today', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 4),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('>', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Grid of 35 Days (August 2026 starting on Saturday 1st)
        LayoutBuilder(
          builder: (context, constraints) {
            final daysInMonth = 31;
            final startDayOffset = 6; // Aug 1 2026 is Saturday
            final totalGridCells = 35;

            final weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: constraints.maxWidth < 700 ? 700 : constraints.maxWidth,
                child: Column(
                  children: [
                    // Weekday headers
                    Row(
                      children: weekdays.map((w) {
                        return Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                w,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 4),

                    // Calendar Days Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisExtent: 80,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                      ),
                      itemCount: totalGridCells,
                      itemBuilder: (context, index) {
                        final dayNum = index - startDayOffset + 1;
                        final isValidDay = dayNum >= 1 && dayNum <= daysInMonth;

                        // Find tasks for this day in August 2026
                        final dayTasks = isValidDay
                            ? items.where((t) {
                                if (t.dueDate.isEmpty) return false;
                                try {
                                  final dt = DateTime.parse(t.dueDate);
                                  return dt.day == dayNum && dt.month == 8;
                                } catch (_) {
                                  return false;
                                }
                              }).toList()
                            : <TaskItemModel>[];

                        final isCurrentTodayDay = dayNum == 21;

                        return Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isCurrentTodayDay
                                ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))
                                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark ? Colors.white12 : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isValidDay)
                                Text(
                                  '$dayNum',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isCurrentTodayDay ? FontWeight.bold : FontWeight.normal,
                                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                                  ),
                                ),
                              const SizedBox(height: 2),
                              if (dayTasks.isNotEmpty)
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: dayTasks.map((t) {
                                        return InkWell(
                                          onTap: () => TaskDetailDialog.show(context, taskId: t.id, initialTask: t),
                                          child: Container(
                                            width: double.infinity,
                                            margin: const EdgeInsets.only(bottom: 2),
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: const Color(0xFFFDE68A)),
                                            ),
                                            child: Text(
                                              t.taskNo,
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF92400E),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
