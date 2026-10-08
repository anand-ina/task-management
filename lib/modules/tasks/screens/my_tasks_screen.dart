import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/bulk_actions_dialog.dart';
import '../../../shared_widgets/dialogs/bulk_upload_dialog.dart';
import '../../../shared_widgets/dialogs/create_task_dialog.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/dialogs/task_detail_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/export_service.dart';
import '../../../shared_widgets/floating_action_button/todo_floating_action_button.dart';
import '../../../shared_widgets/announcement_banner_wrapper.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/all_tasks_bloc.dart';
import '../bloc/all_tasks_event.dart';
import '../bloc/all_tasks_state.dart';
import '../models/task_model.dart';
import '../../../shared_widgets/dropdowns/searchable_filter_dropdown.dart';
import '../../../shared_widgets/dialogs/change_status_dialog.dart';
import '../../dashboard/bloc/dashboard_bloc.dart';
import '../../dashboard/bloc/dashboard_state.dart';

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dash;
  final double gap;
  final double radius;

  DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.dash = 4.0,
    this.gap = 3.0,
    this.radius = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dash < metric.length) ? dash : metric.length - distance;
        canvas.drawPath(metric.extractPath(distance, distance + length), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRectPainter oldDelegate) =>
      color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth;
}

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  late final AllTasksBloc _allTasksBloc;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  String _selectedView = 'list'; // list, board, calendar
  DateTime _selectedMonthDate = DateTime.now();

  String _selectedCategory = 'all'; // all, confidential, general
  String _selectedStatusFilter = 'all';
  String _selectedPriorityFilter = 'all';
  String _selectedOwnerFilter = 'all'; // all, assigned, created
  String _selectedCompletion = 'all';
  int? _progressMin;
  int? _progressMax;
  DateTime? _dueFrom;
  DateTime? _dueTo;
  String _searchQuery = '';
  final Set<int> _selectedTaskIds = {};
  bool _showMoreFilters = false;

  bool _quickCreatedByMe = false;
  bool _quickAssignedToMe = false;
  int? _selectedBranchId;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final hasMultiBranch = authState is AuthenticatedState && authState.userProfile.hasMultiBranchAccess;
    if (hasMultiBranch) {
      final dashState = context.read<DashboardBloc>().state;
      if (dashState is DashboardLoadedState && dashState.selectedBranch != null && !dashState.selectedBranch!.isAll) {
        _selectedBranchId = dashState.selectedBranch!.id;
      }
    } else {
      _selectedBranchId = null;
    }
    _allTasksBloc = AllTasksBloc()
      ..add(FetchAllTasksEvent(scope: 'mine', limit: 100, offset: 0, branchId: _selectedBranchId));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _allTasksBloc.close();
    super.dispose();
  }

  void _onScroll() {
    if (_selectedView != 'list') return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final blocState = _allTasksBloc.state;
      if (blocState is AllTasksLoadedState && !_isLoadingMore) {
        final rawItems = blocState.response.items;
        final total = blocState.response.total;
        if (rawItems.length < total) {
          setState(() {
            _isLoadingMore = true;
          });
          _dispatchFetch(offset: rawItems.length);
        }
      }
    }
  }

  void _dispatchFetch({int offset = 0}) {
    String? dueFromStr;
    if (_dueFrom != null) {
      dueFromStr = '${_dueFrom!.year}-${_dueFrom!.month.toString().padLeft(2, '0')}-${_dueFrom!.day.toString().padLeft(2, '0')}';
    }
    String? dueToStr;
    if (_dueTo != null) {
      dueToStr = '${_dueTo!.year}-${_dueTo!.month.toString().padLeft(2, '0')}-${_dueTo!.day.toString().padLeft(2, '0')}';
    }

    final authState = context.read<AuthBloc>().state;
    final hasMultiBranch = authState is AuthenticatedState && authState.userProfile.hasMultiBranchAccess;
    final effectiveBranchId = hasMultiBranch ? _selectedBranchId : null;

    _allTasksBloc.add(FetchAllTasksEvent(
      scope: 'mine',
      status: _selectedStatusFilter,
      priority: _selectedPriorityFilter,
      owner: _selectedOwnerFilter != 'all' ? _selectedOwnerFilter : null,
      dueFrom: dueFromStr,
      dueTo: dueToStr,
      progressMin: _progressMin,
      progressMax: _progressMax,
      category: _selectedCategory != 'all' ? _selectedCategory : null,
      search: _searchQuery,
      limit: 100,
      offset: offset,
      branchId: effectiveBranchId,
    ));
  }

  void _onCompletionFilterChanged(String val) {
    setState(() {
      _selectedCompletion = val;
      if (val == '0') {
        _progressMin = 0;
        _progressMax = 0;
      } else if (val == '1-25') {
        _progressMin = 1;
        _progressMax = 25;
      } else if (val == '26-50') {
        _progressMin = 26;
        _progressMax = 50;
      } else if (val == '51-75') {
        _progressMin = 51;
        _progressMax = 75;
      } else if (val == '76-99') {
        _progressMin = 76;
        _progressMax = 99;
      } else if (val == '100') {
        _progressMin = 100;
        _progressMax = 100;
      } else {
        _progressMin = null;
        _progressMax = null;
      }
    });
    _dispatchFetch(offset: 0);
  }

  void _toggleQuickFilter({required bool isCreated}) {
    setState(() {
      if (isCreated) {
        _quickCreatedByMe = !_quickCreatedByMe;
      } else {
        _quickAssignedToMe = !_quickAssignedToMe;
      }

      if (_quickCreatedByMe && !_quickAssignedToMe) {
        _selectedOwnerFilter = 'created';
      } else if (!_quickCreatedByMe && _quickAssignedToMe) {
        _selectedOwnerFilter = 'assigned';
      } else {
        _selectedOwnerFilter = 'all';
      }
    });
    _dispatchFetch(offset: 0);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final authState = context.watch<AuthBloc>().state;
    int currentUserId = 0;
    String currentUserName = '';
    if (authState is AuthenticatedState) {
      currentUserId = authState.userProfile.id;
      currentUserName = authState.userProfile.name;
    }

    return BlocProvider.value(
      value: _allTasksBloc,
      child: BlocListener<DashboardBloc, DashboardState>(
        listenWhen: (previous, current) {
          if (current is DashboardLoadedState) {
            if (previous is! DashboardLoadedState) return true;
            return previous.branchChangeTimestamp != current.branchChangeTimestamp ||
                   previous.selectedBranch?.id != current.selectedBranch?.id;
          }
          return false;
        },
        listener: (context, dashState) {
          if (dashState is DashboardLoadedState) {
            final authState = context.read<AuthBloc>().state;
            final hasMultiBranch = authState is AuthenticatedState && authState.userProfile.hasMultiBranchAccess;
            final newBranchId = (hasMultiBranch && dashState.selectedBranch != null && !dashState.selectedBranch!.isAll)
                ? dashState.selectedBranch!.id
                : null;
            if (_selectedBranchId != newBranchId) {
              setState(() {
                _selectedBranchId = newBranchId;
              });
            }
            _dispatchFetch(offset: 0);
          }
        },
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldExit = await ExitConfirmationDialog.show(context);
            if (shouldExit) {
              // handled
            }
          },
          child: Scaffold(
            floatingActionButton: const TodoFloatingActionButton(),
            drawer: const CustomLeftDrawer(currentRoute: '/my-tasks'),
            appBar: const CustomAppBar(),
            body: AnnouncementBannerWrapper(
              child: BlocBuilder<AllTasksBloc, AllTasksState>(
            builder: (context, state) {
              if (state is AllTasksLoadingState) {
                return const Center(
                  child: CircularProgressIndicator(),
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
                        onPressed: () => _dispatchFetch(offset: 0),
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
                _isLoadingMore = false;

                return RefreshIndicator(
                  onRefresh: () async {
                    _dispatchFetch(offset: 0);
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
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
                          '$total ${s.tasksAssignedToOrCreatedByYou}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 7 Stat Cards Row
                        _buildStatCardsRow(context, s, response),
                        const SizedBox(height: 8),

                        // Footnote
                        _buildFootnote(context, s),
                        const SizedBox(height: 16),

                        // View Switcher & Action Buttons Row
                        _buildViewSwitcherAndActions(context, s, items),
                        const SizedBox(height: 16),

                        // Filter Section
                        _buildFilterSection(context, s),
                        const SizedBox(height: 10),

                        // Status Checkbox Legend Row
                        _buildStatusCheckboxRow(context, s),

                        // // Quick Filter Chips (Created by me / Assigned to me)
                        // _buildQuickFilterRow(context, s),
                        // const SizedBox(height: 10),

                        // Bulk Actions or Select All Row
                        if (_selectedTaskIds.isNotEmpty)
                          _buildBulkSelectionHeader(context, s, items)
                        else
                          Row(
                            children: [
                              Checkbox(
                                value: items.isNotEmpty &&
                                    _selectedTaskIds.length == items.length,
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
                                s.selectAllWithCount(total),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),

                        // View Content (List, Board, or Calendar)
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                s.noDataAvailable,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else if (_selectedView == 'board')
                          _buildBoardView(context, s, items)
                        else if (_selectedView == 'calendar')
                          _buildCalendarView(context, s, items)
                        else ...[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              return _buildMyTaskCardItem(
                                context,
                                s,
                                items[index],
                                currentUserId: currentUserId,
                                currentUserName: currentUserName,
                              );
                            },
                          ),
                          if (items.length < total || _isLoadingMore)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
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
    ),
  ),
);
}

  // 7 Stat Cards Row
  Widget _buildStatCardsRow(BuildContext context, AppStrings s, TasksResponseModel response) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard(
            title: '${response.total}',
            label: s.statTotalCard,
            color: const Color(0xFF06B6D4),
            isSelected: _selectedStatusFilter == 'all',
            onTap: () {
              setState(() => _selectedStatusFilter = 'all');
              _dispatchFetch(offset: 0);
            },
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            title: '${response.needsAction}',
            label: s.toBeStarted,
            color: const Color(0xFFF59E0B),
            isSelected: _selectedStatusFilter == 'to_be_started',
            onTap: () {
              setState(() => _selectedStatusFilter = 'to_be_started');
              _dispatchFetch(offset: 0);
            },
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            title: '${response.inProgress}',
            label: s.inProgress,
            color: const Color(0xFF3B82F6),
            isSelected: _selectedStatusFilter == 'in_progress',
            onTap: () {
              setState(() => _selectedStatusFilter = 'in_progress');
              _dispatchFetch(offset: 0);
            },
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            title: '${response.needsReview}',
            label: s.statNeedsReview,
            subtitle: s.statAwaitingSignOff,
            color: const Color(0xFF0D9488),
            isSelected: _selectedStatusFilter == 'needs_review',
            onTap: () {
              setState(() => _selectedStatusFilter = 'needs_review');
              _dispatchFetch(offset: 0);
            },
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            title: '${response.completed}',
            label: s.completed,
            color: const Color(0xFF10B981),
            isSelected: _selectedStatusFilter == 'completed',
            onTap: () {
              setState(() => _selectedStatusFilter = 'completed');
              _dispatchFetch(offset: 0);
            },
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            title: '${response.dropped}',
            label: s.dropped,
            color: const Color(0xFF8B5CF6),
            isSelected: _selectedStatusFilter == 'dropped',
            onTap: () {
              setState(() => _selectedStatusFilter = 'dropped');
              _dispatchFetch(offset: 0);
            },
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            title: '${response.overdue}',
            label: s.overdue,
            subtitle: s.statAcrossStatuses,
            color: const Color(0xFFEF4444),
            isDashed: true,
            isSelected: _selectedStatusFilter == 'overdue',
            onTap: () {
              setState(() => _selectedStatusFilter = 'overdue');
              _dispatchFetch(offset: 0);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String label,
    String? subtitle,
    required Color color,
    bool isDashed = false,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardChild = Container(
      width: 125,
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDashed
            ? (isDark ? const Color(0xFF3B0707) : const Color(0xFFFEF2F2))
            : (isSelected
                ? color.withValues(alpha: isDark ? 0.2 : 0.1)
                : (isDark ? const Color(0xFF1E293B) : Colors.white)),
        borderRadius: BorderRadius.circular(10),
        border: isDashed
            ? null
            : Border.all(
                color: isSelected ? color : color.withValues(alpha: 0.35),
                width: isSelected ? 2.0 : 1.2,
              ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 8.5,
                color: isDark ? Colors.white60 : const Color(0xFF94A3B8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: isDashed
          ? CustomPaint(
              painter: DashedRectPainter(
                color: color,
                strokeWidth: isSelected ? 2.0 : 1.2,
                radius: 10,
              ),
              child: cardChild,
            )
          : cardChild,
    );
  }

  // Footnote
  Widget _buildFootnote(BuildContext context, AppStrings s) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 11,
          color: isDark ? Colors.white60 : const Color(0xFF64748B),
        ),
        children: [
          TextSpan(text: s.statFootnotePrefix),
         
        ],
      ),
    );
  }

  // View Switcher & Action Buttons Row
  Widget _buildViewSwitcherAndActions(BuildContext context, AppStrings s, List<TaskItemModel> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // View Switcher (List, Board, Calendar)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildViewTab(Icons.format_list_bulleted_rounded, s.viewList, 'list'),
                const SizedBox(width: 4),
                _buildViewTab(Icons.view_kanban_outlined, s.viewBoard, 'board'),
                const SizedBox(width: 4),
                _buildViewTab(Icons.calendar_month_outlined, s.viewCalendar, 'calendar'),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Export Dropdown
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
                  const Icon(Icons.trending_up_rounded, size: 14),
                  const SizedBox(width: 5),
                  Text(s.exportButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // + New Task
          ElevatedButton.icon(
            onPressed: () => CreateTaskDialog.show(context),
            icon: const Icon(Icons.add_rounded, size: 14),
            label: Text(s.newTaskButton, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.button(context),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),

          // Bulk Upload
          OutlinedButton.icon(
            onPressed: () async {
              final result = await BulkUploadDialog.show(context);
              if (result == true && context.mounted) {
                _dispatchFetch(offset: 0);
              }
            },
            icon: const Icon(Icons.arrow_upward_rounded, size: 14),
            label: Text(s.bulkUploadButton, style: const TextStyle(fontSize: 11)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTab(IconData icon, String label, String key) {
    final isSelected = _selectedView == key;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _selectedView = key),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF334155) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? const Color(0xFFEF4444) : Colors.grey,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Quick Filter Row: Created by me / Assigned to me
  Widget _buildQuickFilterRow(BuildContext context, AppStrings s) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // Created by me
        InkWell(
          onTap: () => _toggleQuickFilter(isCreated: true),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                  color: _quickCreatedByMe ? const Color(0xFF10B981) : Colors.transparent,
                ),
                child: _quickCreatedByMe
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 6),
              Text(
                s.createdByMe,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),

        // Assigned to me
        InkWell(
          onTap: () => _toggleQuickFilter(isCreated: false),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFF43F5E), width: 1.5),
                  color: _quickAssignedToMe ? const Color(0xFFF43F5E) : Colors.transparent,
                ),
                child: _quickAssignedToMe
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 6),
              Text(
                s.assignedToMe,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Filter Section
  Widget _buildFilterSection(BuildContext context, AppStrings s) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statusOptions = [
      SearchableDropdownItem<String?>(value: 'all', label: s.allStatuses),
      SearchableDropdownItem<String?>(value: 'to_be_started', label: s.toBeStarted),
      SearchableDropdownItem<String?>(value: 'in_progress', label: s.inProgress),
      SearchableDropdownItem<String?>(value: 'paused', label: 'Paused'),
      SearchableDropdownItem<String?>(value: 'needs_review', label: s.statNeedsReview),
      SearchableDropdownItem<String?>(value: 'completed', label: s.completed),
      SearchableDropdownItem<String?>(value: 'dropped', label: s.dropped),
      SearchableDropdownItem<String?>(value: 'overdue', label: 'Blocked / Overdue'),
    ];

    final priorityOptions = [
      SearchableDropdownItem<String?>(value: 'all', label: s.allPriorities),
      SearchableDropdownItem<String?>(value: 'emergency', label: s.priorityEmergency),
      SearchableDropdownItem<String?>(value: 'top_most', label: s.priorityTopMost),
      SearchableDropdownItem<String?>(value: 'high', label: s.priorityHigh),
      SearchableDropdownItem<String?>(value: 'medium', label: s.priorityMedium),
      SearchableDropdownItem<String?>(value: 'low', label: s.priorityLow),
    ];

    final categoryOptions = [
      SearchableDropdownItem<String?>(value: 'all', label: s.confidentialAndGeneral),
      SearchableDropdownItem<String?>(value: 'confidential', label: s.confidentialOnly),
      SearchableDropdownItem<String?>(value: 'general', label: s.generalOnly),
    ];

    final ownerOptions = [
      SearchableDropdownItem<String?>(value: 'all', label: s.createdByAssignedToAll),
      SearchableDropdownItem<String?>(value: 'assigned', label: s.assignedToMe),
      SearchableDropdownItem<String?>(value: 'created', label: s.createdByMe),
    ];

    final completionOptions = [
      SearchableDropdownItem<String?>(value: 'all', label: s.anyCompletionPercent),
      SearchableDropdownItem<String?>(value: '0', label: s.completion0),
      SearchableDropdownItem<String?>(value: '1-25', label: s.completion1To25),
      SearchableDropdownItem<String?>(value: '26-50', label: s.completion26To50),
      SearchableDropdownItem<String?>(value: '51-75', label: s.completion51To75),
      SearchableDropdownItem<String?>(value: '76-99', label: s.completion76To99),
      SearchableDropdownItem<String?>(value: '100', label: s.completion100),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Filter Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Search Box
              SizedBox(
                width: 120,
                height: 38,
                child: TextField(
                  onChanged: (val) {
                    _searchQuery = val;
                    _dispatchFetch(offset: 0);
                  },
                  decoration: InputDecoration(
                    hintText: s.searchTasksPlaceholder,
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 16,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF991B1B),
                        width: 1.2,
                      ),
                    ),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 3),

              // Status Dropdown
              SearchableFilterDropdown<String>(
                value: _selectedStatusFilter,
                hint: s.allStatuses,
                searchHint: s.allStatuses,
                items: statusOptions,
                width: 100,
                minPopupWidth: 200,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedStatusFilter = val);
                    _dispatchFetch(offset: 0);
                  }
                },
              ),
              const SizedBox(width: 2),

              // Priority Dropdown
              SearchableFilterDropdown<String>(
                value: _selectedPriorityFilter,
                hint: s.allPriorities,
                searchHint: s.allPriorities,
                items: priorityOptions,
                width: 105,
                minPopupWidth: 180,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedPriorityFilter = val);
                    _dispatchFetch(offset: 0);
                  }
                },
              ),
              const SizedBox(width: 2),

              // More Filters Button
              InkWell(
                onTap: () {
                  setState(() => _showMoreFilters = !_showMoreFilters);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _showMoreFilters
                        ? (isDark ? const Color(0xFF991B1B).withValues(alpha: 0.2) : const Color(0xFF991B1B).withValues(alpha: 0.08))
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _showMoreFilters
                          ? const Color(0xFF991B1B)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      width: _showMoreFilters ? 1.4 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 15,
                        color: _showMoreFilters
                            ? const Color(0xFF991B1B)
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        s.moreFilters,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _showMoreFilters
                              ? const Color(0xFF991B1B)
                              : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Secondary / More Filters Row (shown when _showMoreFilters is true)
        if (_showMoreFilters) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Confidential & General Dropdown
                SearchableFilterDropdown<String>(
                  value: _selectedCategory,
                  hint: s.confidentialAndGeneral,
                  searchHint: s.confidentialAndGeneral,
                  items: categoryOptions,
                  width: 175,
                  minPopupWidth: 200,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCategory = val);
                      _dispatchFetch(offset: 0);
                    }
                  },
                ),
                const SizedBox(width: 8),

                // Created by / Assigned to: All Dropdown
                SearchableFilterDropdown<String>(
                  value: _selectedOwnerFilter,
                  hint: s.createdByAssignedToAll,
                  searchHint: s.createdByAssignedToAll,
                  items: ownerOptions,
                  width: 190,
                  minPopupWidth: 210,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedOwnerFilter = val;
                        _quickCreatedByMe = (val == 'created');
                        _quickAssignedToMe = (val == 'assigned');
                      });
                      _dispatchFetch(offset: 0);
                    }
                  },
                ),
                const SizedBox(width: 8),

                // Any Completion % Dropdown
                SearchableFilterDropdown<String>(
                  value: _selectedCompletion,
                  hint: s.anyCompletionPercent,
                  searchHint: s.anyCompletionPercent,
                  items: completionOptions,
                  width: 150,
                  minPopupWidth: 170,
                  onChanged: (val) {
                    if (val != null) _onCompletionFilterChanged(val);
                  },
                ),
                const SizedBox(width: 8),

                // Due Date Range
                Text(
                  s.dueLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                _buildDateBox(
                  context,
                  _dueFrom,
                  (picked) {
                    setState(() => _dueFrom = picked);
                    _dispatchFetch(offset: 0);
                  },
                ),
                const SizedBox(width: 6),
                Text(
                  s.toLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                _buildDateBox(
                  context,
                  _dueTo,
                  (picked) {
                    setState(() => _dueTo = picked);
                    _dispatchFetch(offset: 0);
                  },
                ),
                if (_dueFrom != null || _dueTo != null) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      setState(() {
                        _dueFrom = null;
                        _dueTo = null;
                      });
                      _dispatchFetch(offset: 0);
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateBox(BuildContext context, DateTime? date, Function(DateTime?) onSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = date != null
        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
        : 'dd/mm/yyyy';

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          onSelected(picked);
        }
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: date != null ? (isDark ? Colors.white : Colors.black) : Colors.grey,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Single Task Card Item with Left Accent Border
  Widget _buildMyTaskCardItem(
    BuildContext context,
    AppStrings s,
    TaskItemModel item, {
    required int currentUserId,
    required String currentUserName,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedTaskIds.contains(item.id);

    final isCreatedByMe = item.assignedByUserId == currentUserId ||
        (currentUserName.isNotEmpty && item.assignedByName.toLowerCase().contains(currentUserName.toLowerCase())) ||
        item.assignedByText.toLowerCase().contains('created');

    final accentColor = isCreatedByMe ? const Color(0xFF10B981) : const Color(0xFFF43F5E);
    final priorityColor = _getPriorityColor(item.priority);
    final statusColor = _getStatusColor(item.status);
    final cardBgColor = _getStatusBgColor(item.status, isDark);
    final cardBorderColor = _getStatusBorderColor(item.status, isDark);

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: cardBorderColor,
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: cardBgColor,
            border: Border(
              left: BorderSide(color: accentColor, width: 4.5),
            ),
          ),
          child: InkWell(
            onTap: () => TaskDetailDialog.show(context, taskId: item.id, initialTask: item),
            child: Padding(
              padding: const EdgeInsets.all(9),
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

                  // Task ID
                  Text(
                    s.taskNoPrefix,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    item.taskNo,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Created by me / Assigned to me pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCreatedByMe
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFFE4E6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isCreatedByMe ? s.createdByMe : s.assignedToMe,
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        color: isCreatedByMe
                            ? const Color(0xFF15803D)
                            : const Color(0xFFE11D48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),

                  // Priority Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getPriorityLabel(s, item.priority),
                      style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: priorityColor),
                    ),
                  ),
                  const SizedBox(width: 2),


                ],
              ),
              const SizedBox(height: 8),

              // Title Row with Update / Edit button on far right
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      final updated = await ChangeStatusDialog.show(context, task: item);
                      if (updated == true) {
                        _dispatchFetch(offset: 0);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_outlined, size: 13, color: Color(0xFFD97706)),
                          const SizedBox(width: 5),
                          Text(
                            s.updateEdit,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Bottom Row: By Author + Assignees Avatars + Subtasks
              Row(
                children: [
                  Text(
                    s.byAuthor(item.assignedByName.isNotEmpty ? item.assignedByName : 'Admin'),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),

                  // Circular Avatars
                  if (item.assignees.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...item.assignees.take(3).map((a) {
                          final avatarColor = _hexToColor(a.color);
                          return Container(
                            margin: const EdgeInsets.only(left: 4),
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: avatarColor,
                              child: Text(
                                a.initials.isNotEmpty ? a.initials : 'NA',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }),
                        if (item.assignees.length > 3)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '+${item.assignees.length - 3}',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                          ),
                      ],
                    ),

                  // Subtasks chip
                  if (item.subtasksTotal > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.list_alt_rounded, size: 10, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text(
                            s.subtasksCountBadge(item.subtasksCompleted, item.subtasksTotal),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Status Dot + Label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.progress > 0
                              ? '${_formatStatusText(s, item.status)} · ${item.progress}%'
                              : _formatStatusText(s, item.status),
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                  if (item.isSubtask && item.parentTaskNo != null && item.parentTaskNo!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.subdirectory_arrow_right_rounded,
                            size: 11,
                            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Sub-task of ${item.parentTaskNo}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (item.branchCode.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      item.branchCode,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ],


                  // Due Date
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 10, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        _formatDate(item.dueDate),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),))
    );
  }

  // Bulk Actions Header Bar
  Widget _buildBulkSelectionHeader(BuildContext context, AppStrings s, List<TaskItemModel> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCount = _selectedTaskIds.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFBFDBFE)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Checkbox(
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
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$selectedCount selected',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.button(context),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.settings_outlined, size: 14),
              label: const Text('Bulk actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () async {
                final result = await BulkActionsDialog.show(
                  context,
                  selectedTaskIds: _selectedTaskIds.toList(),
                );
                if (result == true) {
                  setState(() => _selectedTaskIds.clear());
                  if (context.mounted) {
                    _dispatchFetch(offset: 0);
                  }
                }
              },
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: 'Export selected',
              onSelected: (val) {
                final selectedTasks = items.where((e) => _selectedTaskIds.contains(e.id)).toList();
                if (selectedTasks.isEmpty) return;
                final title = '${s.myTasks}_Selected';
                if (val == 'csv') {
                  ExportService.exportCsv(context, selectedTasks, title);
                } else if (val == 'excel') {
                  ExportService.exportExcel(context, selectedTasks, title);
                } else if (val == 'pdf') {
                  ExportService.exportPdf(context, selectedTasks, title);
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : Colors.white,
                  border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.north_east_rounded,
                      size: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Export selected',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 14,
                      color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => setState(() => _selectedTaskIds.clear()),
              child: const Text('Clear', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // Kanban Board View
  Widget _buildBoardView(BuildContext context, AppStrings s, List<TaskItemModel> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final columns = [
      {'key': 'to_be_started', 'label': s.toBeStarted.toUpperCase(), 'color': const Color(0xFFF59E0B)},
      {'key': 'in_progress', 'label': s.inProgress.toUpperCase(), 'color': const Color(0xFF3B82F6)},
      {'key': 'needs_review', 'label': s.statNeedsReview.toUpperCase(), 'color': const Color(0xFFD97706)},
      {'key': 'completed', 'label': s.completed.toUpperCase(), 'color': const Color(0xFF10B981)},
      {'key': 'dropped', 'label': s.dropped.toUpperCase(), 'color': const Color(0xFF64748B)},
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
            if (colKey == 'needs_review') return st == 'needs_review' || st == 'done';
            if (colKey == 'to_be_started') return st == 'to_be_started' || st == 'pending' || st == 'paused';
            return st == colKey;
          }).toList();

          return Container(
            width: 260,
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
                if (colTasks.isEmpty)
                  Container(
                    height: 80,
                    alignment: Alignment.center,
                    child: Text(
                      'No tasks',
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
                            color: _getStatusBorderColor(task.status, isDark),
                            width: 1.0,
                          ),
                        ),
                        color: _getStatusBgColor(task.status, isDark),
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
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
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
                                        _getPriorityLabel(s, task.priority),
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

  // Calendar View
  Widget _buildCalendarView(BuildContext context, AppStrings s, List<TaskItemModel> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstDayOfMonth = DateTime(_selectedMonthDate.year, _selectedMonthDate.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_selectedMonthDate.year, _selectedMonthDate.month);
    final startDayOffset = firstDayOfMonth.weekday % 7;
    final totalGridCells = ((startDayOffset + daysInMonth) / 7).ceil() * 7;
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(_selectedMonthDate),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      final prevMonth = _selectedMonthDate.month - 1;
                      final year = prevMonth < 1 ? _selectedMonthDate.year - 1 : _selectedMonthDate.year;
                      final month = prevMonth < 1 ? 12 : prevMonth;
                      final dim = DateUtils.getDaysInMonth(year, month);
                      final day = _selectedMonthDate.day > dim ? dim : _selectedMonthDate.day;
                      _selectedMonthDate = DateTime(year, month, day);
                    });
                  },
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), visualDensity: VisualDensity.compact),
                  child: const Text('<', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 4),
                OutlinedButton(
                  onPressed: () => setState(() => _selectedMonthDate = DateTime.now()),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), visualDensity: VisualDensity.compact),
                  child: Text(s.today, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 4),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      final nextMonth = _selectedMonthDate.month + 1;
                      final year = nextMonth > 12 ? _selectedMonthDate.year + 1 : _selectedMonthDate.year;
                      final month = nextMonth > 12 ? 1 : nextMonth;
                      final dim = DateUtils.getDaysInMonth(year, month);
                      final day = _selectedMonthDate.day > dim ? dim : _selectedMonthDate.day;
                      _selectedMonthDate = DateTime(year, month, day);
                    });
                  },
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), visualDensity: VisualDensity.compact),
                  child: const Text('>', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Day of Week Headers
        Row(
          children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((d) {
            return Expanded(
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Grid of Days
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.0,
          ),
          itemCount: totalGridCells,
          itemBuilder: (context, index) {
            final dayNumber = index - startDayOffset + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            }

            final cellDate = DateTime(_selectedMonthDate.year, _selectedMonthDate.month, dayNumber);
            final isToday = cellDate.year == now.year && cellDate.month == now.month && cellDate.day == now.day;

            final dayTasks = items.where((task) {
              if (task.dueDate.isEmpty) return false;
              try {
                final d = DateTime.parse(task.dueDate);
                return d.year == cellDate.year && d.month == cellDate.month && d.day == cellDate.day;
              } catch (_) {
                return false;
              }
            }).toList();

            return Container(
              decoration: BoxDecoration(
                color: isToday
                    ? (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF))
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isToday
                      ? const Color(0xFF3B82F6)
                      : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06)),
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      color: isToday ? const Color(0xFF3B82F6) : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  if (dayTasks.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: dayTasks.length,
                        itemBuilder: (context, ti) {
                          final t = dayTasks[ti];
                          return InkWell(
                            onTap: () => TaskDetailDialog.show(context, taskId: t.id, initialTask: t),
                            child: Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: _getStatusColor(t.status).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                t.title,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(t.status),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _getPriorityLabel(AppStrings s, String priority) {
    switch (priority.toLowerCase()) {
      case 'emergency':
        return s.priorityEmergency;
      case 'top_most':
        return s.priorityTopMost;
      case 'high':
        return s.priorityHigh;
      case 'medium':
        return s.priorityMedium;
      case 'low':
        return s.priorityLow;
      default:
        return priority.isNotEmpty ? (priority[0].toUpperCase() + priority.substring(1)) : 'General';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'emergency':
        return const Color(0xFFEF4444);
      case 'top_most':
        return const Color(0xFFF97316);
      case 'high':
        return const Color(0xFFF59E0B);
      case 'medium':
        return const Color(0xFF3B82F6);
      case 'low':
        return const Color(0xFF64748B);
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'in_progress':
        return const Color(0xFF3B82F6);
      case 'paused':
        return const Color(0xFFF59E0B);
      case 'needs_review':
      case 'done':
        return const Color(0xFF0D9488);
      case 'to_be_started':
      case 'pending':
        return const Color(0xFF64748B);
      case 'overdue':
      case 'blocked':
        return const Color(0xFFEF4444);
      case 'dropped':
      case 'scrapped':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getStatusBgColor(String status, bool isDark) {
    final color = _getStatusColor(status);
    return isDark
        ? Color.alphaBlend(color.withValues(alpha: 0.14), const Color(0xFF1E293B))
        : Color.alphaBlend(color.withValues(alpha: 0.08), Colors.white);
  }

  Color _getStatusBorderColor(String status, bool isDark) {
    final color = _getStatusColor(status);
    return isDark
        ? color.withValues(alpha: 0.35)
        : color.withValues(alpha: 0.28);
  }

  String _formatStatusText(AppStrings s, String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return s.inProgress;
      case 'to_be_started':
      case 'pending':
        return s.toBeStarted;
      case 'paused':
        return 'Paused';
      case 'needs_review':
      case 'done':
        return s.statNeedsReview;
      case 'completed':
        return s.completed;
      case 'dropped':
      case 'scrapped':
        return s.dropped;
      case 'overdue':
        return s.overdue;
      case 'blocked':
        return 'Blocked / Overdue';
      default:
        return status.isNotEmpty ? (status[0].toUpperCase() + status.substring(1)) : '';
    }
  }

  // Status Checkbox Legend Row
  Widget _buildStatusCheckboxRow(BuildContext context, AppStrings s) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statuses = [
      {'key': 'to_be_started', 'label': s.toBeStarted, 'color': const Color(0xFF64748B)},
      {'key': 'in_progress', 'label': s.inProgress, 'color': const Color(0xFF3B82F6)},
      {'key': 'paused', 'label': 'Paused', 'color': const Color(0xFFF59E0B)},
      {'key': 'needs_review', 'label': s.statNeedsReview, 'color': const Color(0xFF0D9488)},
      {'key': 'completed', 'label': s.completed, 'color': const Color(0xFF10B981)},
      {'key': 'dropped', 'label': s.dropped, 'color': const Color(0xFF8B5CF6)},
      {'key': 'overdue', 'label': 'Blocked / Overdue', 'color': const Color(0xFFEF4444)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((st) {
          final key = st['key'] as String;
          final label = st['label'] as String;
          final color = st['color'] as Color;
          final isChecked = _selectedStatusFilter == key ||
              (key == 'overdue' && (_selectedStatusFilter == 'overdue' || _selectedStatusFilter == 'blocked'));

          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: InkWell(
              // onTap: () {
              //   setState(() {
              //     if (isChecked) {
              //       _selectedStatusFilter = 'all';
              //     } else {
              //       _selectedStatusFilter = key;
              //     }
              //   });
              //   _dispatchFetch(offset: 0);
              // },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3.5),
                        border: Border.all(
                          color: color,
                          width: 1.5,
                        ),
                      ),
                      child: isChecked
                          ? const Center(
                              child: Icon(
                                Icons.check,
                                size: 11,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isChecked ? FontWeight.w600 : FontWeight.w500,
                        color: isChecked
                            ? (isDark ? Colors.white : const Color(0xFF0F172A))
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'];
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]}';
    } catch (_) {
      return '—';
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
