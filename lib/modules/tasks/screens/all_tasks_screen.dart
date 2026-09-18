import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/bulk_upload_dialog.dart';
import '../../../shared_widgets/dialogs/create_task_dialog.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/dialogs/new_recurring_task_dialog.dart';
import '../../../shared_widgets/dialogs/task_detail_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/export_service.dart';
import '../../../shared_widgets/floating_action_button/todo_floating_action_button.dart';
import '../bloc/all_tasks_bloc.dart';
import '../bloc/all_tasks_event.dart';
import '../bloc/all_tasks_state.dart';
import '../models/task_model.dart';

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

class AllTasksScreen extends StatefulWidget {
  const AllTasksScreen({super.key});

  @override
  State<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen> {
  late final AllTasksBloc _allTasksBloc;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

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

  @override
  void initState() {
    super.initState();
    _allTasksBloc = AllTasksBloc()
      ..add(FetchAllTasksEvent(scope: 'all', limit: 20, offset: 0));
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

    _allTasksBloc.add(FetchAllTasksEvent(
      scope: 'all',
      status: _selectedStatusFilter,
      priority: _selectedPriorityFilter,
      owner: _selectedOwnerFilter != 'all' ? _selectedOwnerFilter : null,
      dueFrom: dueFromStr,
      dueTo: dueToStr,
      progressMin: _progressMin,
      progressMax: _progressMax,
      category: _selectedCategory != 'all' ? _selectedCategory : null,
      search: _searchQuery,
      limit: 80,
      offset: offset,
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

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: _allTasksBloc,
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

                        // 7 Stat Cards
                        _buildStatCardsRow(context, s, response),
                        const SizedBox(height: 8),

                        // Footnote
                        _buildFootnote(context, s),
                        const SizedBox(height: 16),

                        // Action Buttons Bar
                        _buildActionButtons(context, s, items),
                        const SizedBox(height: 16),

                        // Filter Controls
                        _buildFilterSection(context, s),
                        const SizedBox(height: 14),

                        // Select All Checkbox Row
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

                        // Tasks List
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
                        else ...[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              return _buildTaskCardItem(context, s, items[index]);
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
                                    color: Color(0xFF2563EB),
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
            color: const Color(0xFFD97706),
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
            color: const Color(0xFF64748B),
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
          TextSpan(
            text: s.statFootnoteOverdue,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF4444),
            ),
          ),
          TextSpan(text: s.statFootnoteSuffix),
        ],
      ),
    );
  }

  // Action Buttons Bar
  Widget _buildActionButtons(BuildContext context, AppStrings s, List<TaskItemModel> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Export Dropdown
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

          // + New Recurring
          OutlinedButton.icon(
            onPressed: () => NewRecurringTaskDialog.show(context),
            icon: const Icon(Icons.autorenew_rounded, size: 14),
            label: Text(s.newRecurringButton, style: const TextStyle(fontSize: 11)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),

          // + New Task
          ElevatedButton.icon(
            onPressed: () => CreateTaskDialog.show(context),
            icon: const Icon(Icons.add_rounded, size: 14),
            label: Text(s.newTaskButton, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
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

  // Filter Section
  Widget _buildFilterSection(BuildContext context, AppStrings s) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildCategoryPill(s.categoryAll, 'all'),
            const SizedBox(width: 6),
            _buildCategoryPill(s.categoryConfidential, 'confidential'),
            const SizedBox(width: 6),
            _buildCategoryPill(s.categoryGeneral, 'general'),
            const SizedBox(width: 10),
          ],),
        SizedBox(height: 10,),
        // Row 1: Category pills, Search, Status, Priority, Owner
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            children: [

              Row(
                children: [
                  // Category Pills

                  // Search Box
                  SizedBox(
                    width: 180,
                    height: 36,
                    child: TextField(
                      onChanged: (val) {
                        _searchQuery = val;
                        _dispatchFetch(offset: 0);
                      },
                      decoration: InputDecoration(
                        hintText: s.searchTasksPlaceholder,
                        hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, size: 14, color: Colors.grey),
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Status Dropdown
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatusFilter,
                        items: [
                          DropdownMenuItem(value: 'all', child: Text(s.allStatuses, style: const TextStyle(fontSize: 11))),
                          DropdownMenuItem(value: 'to_be_started', child: Text(s.toBeStarted, style: const TextStyle(fontSize: 11))),
                          DropdownMenuItem(value: 'in_progress', child: Text(s.inProgress, style: const TextStyle(fontSize: 11))),
                          DropdownMenuItem(value: 'needs_review', child: Text(s.statNeedsReview, style: const TextStyle(fontSize: 11))),
                          DropdownMenuItem(value: 'completed', child: Text(s.completed, style: const TextStyle(fontSize: 11))),
                          DropdownMenuItem(value: 'dropped', child: Text(s.dropped, style: const TextStyle(fontSize: 11))),
                          DropdownMenuItem(value: 'overdue', child: Text(s.overdue, style: const TextStyle(fontSize: 11))),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedStatusFilter = val);
                            _dispatchFetch(offset: 0);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),


                ],
              ),
              const SizedBox(height: 10),

              Row(children: [    // Priority Dropdown
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPriorityFilter,
                      items: [
                        DropdownMenuItem(value: 'all', child: Text(s.allPriorities, style: const TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'emergency', child: Text(s.priorityEmergency, style: const TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'top_most', child: Text(s.priorityTopMost, style: const TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'high', child: Text(s.priorityHigh, style: const TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'medium', child: Text(s.priorityMedium, style: const TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'low', child: Text(s.priorityLow, style: const TextStyle(fontSize: 11))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedPriorityFilter = val);
                          _dispatchFetch(offset: 0);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Owner Dropdown
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedOwnerFilter,
                      items: [
                        DropdownMenuItem(value: 'all', child: Text(s.createdByAssignedToAll, style: const TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'assigned', child: Text(s.assignedToMe, style: const TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'created', child: Text(s.createdByMe, style: const TextStyle(fontSize: 11))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedOwnerFilter = val);
                          _dispatchFetch(offset: 0);
                        }
                      },
                    ),
                  ),
                ),],)
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Row 2: Completion %, Due Date Range
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Completion %
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCompletion,
                    items: [
                      DropdownMenuItem(value: 'all', child: Text(s.anyCompletionPercent, style: const TextStyle(fontSize: 11))),
                      DropdownMenuItem(value: '0', child: Text(s.completion0, style: const TextStyle(fontSize: 11))),
                      DropdownMenuItem(value: '1-25', child: Text(s.completion1To25, style: const TextStyle(fontSize: 11))),
                      DropdownMenuItem(value: '26-50', child: Text(s.completion26To50, style: const TextStyle(fontSize: 11))),
                      DropdownMenuItem(value: '51-75', child: Text(s.completion51To75, style: const TextStyle(fontSize: 11))),
                      DropdownMenuItem(value: '76-99', child: Text(s.completion76To99, style: const TextStyle(fontSize: 11))),
                      DropdownMenuItem(value: '100', child: Text(s.completion100, style: const TextStyle(fontSize: 11))),
                    ],
                    onChanged: (val) {
                      if (val != null) _onCompletionFilterChanged(val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Due Label
              Text(
                s.dueLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),

              // Date Picker Start
              _buildDateBox(
                context,
                _dueFrom,
                (picked) {
                  setState(() => _dueFrom = picked);
                  _dispatchFetch(offset: 0);
                },
              ),
              const SizedBox(width: 6),

              // To Label
              Text(
                s.toLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),

              // Date Picker End
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
    );
  }

  Widget _buildCategoryPill(String label, String key) {
    final isSelected = _selectedCategory == key;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        setState(() => _selectedCategory = key);
        _dispatchFetch(offset: 0);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF334155) : const Color(0xFF0F172A))
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
          ),
        ),
      ),
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

  // Single Task Card Item
  Widget _buildTaskCardItem(BuildContext context, AppStrings s, TaskItemModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedTaskIds.contains(item.id);

    final priorityColor = _getPriorityColor(item.priority);
    final statusColor = _getStatusColor(item.status);

    return Container(
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

                  // Priority Pill
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getPriorityLabel(s, item.priority),
                          style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: priorityColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox( height:3 ),
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


                  // Status Dot + Progress %

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

              // Bottom Row: Assigned by + Assignee Avatars
              Row(
                children: [
                  Text(
                    s.byAuthor(item.assignedByName.isNotEmpty ? item.assignedByName : 'Admin'),
                    style: TextStyle(
                      fontSize: 9,
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
                            margin: const EdgeInsets.only(left: 2),
                            child: CircleAvatar(
                              radius: 9,
                              backgroundColor: avatarColor,
                              child: Text(
                                a.initials.isNotEmpty ? a.initials : 'NA',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 7,
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
                  const SizedBox(width: 3),

                  // Branch Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      item.branchCode.isNotEmpty ? item.branchCode : 'SS00',
                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),

                  // Linked Ticket Chip
                  if (item.ticketNo != null && item.ticketNo!.isNotEmpty) ...[
                    const SizedBox(width: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🎫', style: TextStyle(fontSize: 8)),
                          const SizedBox(width: 2),
                          Text(
                            item.ticketNo!,
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Confidential Chip
                  if (item.isConfidential) ...[
                    const SizedBox(width: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE7F3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        s.categoryConfidential,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDB2777),
                        ),
                      ),
                    ),
                  ],


                  // Due Date
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 11, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        _formatDate(item.dueDate),
                        style: const TextStyle(
                          fontSize: 10,
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
      ),
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
      case 'needs_review':
        return const Color(0xFFD97706);
      case 'to_be_started':
        return const Color(0xFF64748B);
      case 'overdue':
        return const Color(0xFFEF4444);
      case 'dropped':
        return const Color(0xFF94A3B8);
      default:
        return Colors.grey;
    }
  }

  String _formatStatusText(AppStrings s, String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return s.inProgress;
      case 'to_be_started':
        return s.toBeStarted;
      case 'needs_review':
        return s.statNeedsReview;
      case 'completed':
        return s.completed;
      case 'dropped':
        return s.dropped;
      case 'overdue':
        return s.overdue;
      default:
        return status.isNotEmpty ? (status[0].toUpperCase() + status.substring(1)) : '';
    }
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
