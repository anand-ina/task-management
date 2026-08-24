import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/dialogs/tasks_due_today_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/export_service.dart';
import '../bloc/organization_bloc.dart';
import '../bloc/organization_event.dart';
import '../bloc/organization_state.dart';
import '../models/organization_data_model.dart';
import '../models/trends_model.dart';
import '../../dashboard/models/dashboard_stats.dart';

class OrganizationOverviewScreen extends StatefulWidget {
  const OrganizationOverviewScreen({super.key});

  @override
  State<OrganizationOverviewScreen> createState() => _OrganizationOverviewScreenState();
}

class _OrganizationOverviewScreenState extends State<OrganizationOverviewScreen> {
  String _searchBranchQuery = '';

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => OrganizationBloc()..add(FetchOrganizationDataEvent()),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldExit = await ExitConfirmationDialog.show(context);
          if (shouldExit) {
            // Handled inside dialog
          }
        },
        child: Scaffold(
          drawer: const CustomLeftDrawer(currentRoute: '/org-overview'),
          appBar: const CustomAppBar(),
          body: BlocBuilder<OrganizationBloc, OrganizationState>(
            builder: (context, state) {
              if (state is OrganizationLoadingState) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFB91C1C)),
                );
              }

              if (state is OrganizationErrorState) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<OrganizationBloc>().add(FetchOrganizationDataEvent());
                        },
                        child: Text(s.retryButton),
                      ),
                    ],
                  ),
                );
              }

              if (state is OrganizationLoadedState) {
                final data = state.data;
                final stats = data.overallDashboard.stats;
                final byDeadline = data.overallDashboard.byDeadline;
                final performance = data.overallDashboard.performance;

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<OrganizationBloc>().add(FetchOrganizationDataEvent(bucket: state.activeBucket));
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Header
                        Text(
                          s.organizationOverview,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.everyCampusDeptAtAGlance,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Top 4 Metric Cards
                        _buildTopMetricGrid(context, s, stats),
                        const SizedBox(height: 24),

                        // By Branch Unit Section Container List Card
                        _buildBranchUnitContainerListCard(context, s, data.branchUnitStats),
                        const SizedBox(height: 24),

                        // Analytics Header Row
                        Row(
                          children: [
                            Text(
                              s.analyticsTitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const Spacer(),
                            PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'csv') {
                                  ExportService.exportOrgOverviewCsv(context: context, branchStats: data.branchUnitStats);
                                } else if (val == 'excel') {
                                  ExportService.exportOrgOverviewExcel(context: context, branchStats: data.branchUnitStats);
                                } else if (val == 'pdf') {
                                  ExportService.exportOrgOverviewPdf(context: context, branchStats: data.branchUnitStats);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'csv',
                                  child: Row(
                                    children: [
                                      Icon(Icons.insert_drive_file_outlined, size: 16, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Export to CSV', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'excel',
                                  child: Row(
                                    children: [
                                      Icon(Icons.table_chart_outlined, size: 16, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text('Export to Excel', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'pdf',
                                  child: Row(
                                    children: [
                                      Icon(Icons.picture_as_pdf_outlined, size: 16, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Export to PDF', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.download_rounded, size: 14),
                                    const SizedBox(width: 6),
                                    Text(s.exportButton, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_drop_down, size: 16),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              s.organizationWide,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Trends Over Time Chart Card
                        _buildTrendsCard(context, s, data.trends, state.activeBucket),
                        const SizedBox(height: 20),

                        // On-Time Completion (By Due Window) Card
                        _buildOnTimeCompletionCard(context, s, performance),
                        const SizedBox(height: 20),

                        // Task Status Distribution & Priority Load Row
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 800;
                            return isWide
                                ? Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _buildTaskStatusDistributionCard(context, s, stats)),
                                      const SizedBox(width: 16),
                                      Expanded(child: _buildPriorityLoadCard(context, s, stats)),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _buildTaskStatusDistributionCard(context, s, stats),
                                      const SizedBox(height: 16),
                                      _buildPriorityLoadCard(context, s, stats),
                                    ],
                                  );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Completion By Branch & Workload By Deadline Row
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 800;
                            return isWide
                                ? Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _buildCompletionByBranchCard(context, s, data.branchUnitStats)),
                                      const SizedBox(width: 16),
                                      Expanded(child: _buildWorkloadByDeadlineCard(context, s, byDeadline, stats.overdue)),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _buildCompletionByBranchCard(context, s, data.branchUnitStats),
                                      const SizedBox(height: 16),
                                      _buildWorkloadByDeadlineCard(context, s, byDeadline, stats.overdue),
                                    ],
                                  );
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

  // Top 4 Metric Cards
  Widget _buildTopMetricGrid(BuildContext context, AppStrings s, dynamic stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 2);
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 105,
          children: [
            _buildMetricCard(
              '${stats.total}',
              s.totalTasks,
              color: const Color(0xFF3866D6),
              onTap: () => TasksDueTodayDialog.show(context, customTitle: 'All Tasks', badgeColor: const Color(0xFF3866D6)),
            ),
            _buildMetricCard(
              '${stats.completed}',
              '${s.completed} · ${stats.completionRate}%',
              color: const Color(0xFF1F9D57),
              onTap: () => TasksDueTodayDialog.show(context, customTitle: 'Completed Tasks', status: 'completed', badgeColor: const Color(0xFF1F9D57)),
            ),
            _buildMetricCard(
              '${stats.inProgress}',
              s.inProgress,
              color: const Color(0xFF0284C7),
              onTap: () => TasksDueTodayDialog.show(context, customTitle: 'In Progress Tasks', status: 'in_progress', badgeColor: const Color(0xFF0284C7)),
            ),
            _buildMetricCard(
              '${stats.overdue}',
              s.overdue,
              color: const Color(0xFFDC2626),
              onTap: () => TasksDueTodayDialog.show(context, customTitle: 'Overdue Tasks', overdue: true, badgeColor: const Color(0xFFDC2626)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(String val, String label, {required Color color, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                val,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // By Branch Unit Section Container Card List
  Widget _buildBranchUnitContainerListCard(BuildContext context, AppStrings s, List<BranchUnitStatModel> branchStats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = branchStats.where((b) {
      if (_searchBranchQuery.isEmpty) return true;
      final q = _searchBranchQuery.toLowerCase();
      return b.branch.name.toLowerCase().contains(q) || b.branch.code.toLowerCase().contains(q);
    }).toList();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  s.byBranchUnit,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 180,
                  height: 32,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchBranchQuery = val),
                    decoration: InputDecoration(
                      hintText: s.searchBranchPlaceholder,
                      hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, size: 14, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                      ),
                    ),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('No branch units found', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final st = item.stats;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        TasksDueTodayDialog.show(
                          context,
                          customTitle: '${item.branch.name} Tasks',
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Code Badge, Branch Name & Completion Rate
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    item.branch.code,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.branch.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1F9D57).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${st.completionRate}% Done',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F9D57),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Progress Bar
                            LinearProgressIndicator(
                              value: (st.completionRate / 100).clamp(0.0, 1.0),
                              backgroundColor: Colors.grey.shade200,
                              color: const Color(0xFF1F9D57),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            const SizedBox(height: 12),

                            // Metric Badges Row
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _buildMetricBadge('TOTAL', '${st.total}', Colors.grey),
                                _buildMetricBadge('COMPLETED', '${st.completed}', const Color(0xFF1F9D57)),
                                _buildMetricBadge('IN PROGRESS', '${st.inProgress}', const Color(0xFF0284C7)),
                                _buildMetricBadge('TO START', '${st.toBeStarted}', const Color(0xFF475569)),
                                _buildMetricBadge('OVERDUE', '${st.overdue}', const Color(0xFFDC2626)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  // Trends Over Time Chart Card
  Widget _buildTrendsCard(BuildContext context, AppStrings s, TrendsResponseModel trends, String activeBucket) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = trends.items;
    final maxVal = items.fold<int>(1, (prev, e) => (e.created > prev ? e.created : (e.completed > prev ? e.completed : prev)));

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.trendsOverTime,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildBucketButton(context, s.weeklyBucket, 'week', activeBucket),
                      _buildBucketButton(context, s.monthlyBucket, 'month', activeBucket),
                      _buildBucketButton(context, s.quarterlyBucket, 'quarter', activeBucket),
                      _buildBucketButton(context, s.yearlyBucket, 'year', activeBucket),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bar Visual Component
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: items.map((item) {
                  final createdH = ((item.created / maxVal) * 120).clamp(4.0, 120.0);
                  final completedH = ((item.completed / maxVal) * 120).clamp(4.0, 120.0);

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 10,
                            height: createdH,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 10,
                            height: completedH,
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Legends Row
            Row(
              children: [
                Container(width: 10, height: 10, color: const Color(0xFF2563EB)),
                const SizedBox(width: 6),
                Text(s.createdLegend, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(width: 16),
                Container(width: 10, height: 10, color: const Color(0xFF16A34A)),
                const SizedBox(width: 6),
                Text(s.completedLegend, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBucketButton(BuildContext context, String label, String key, String activeKey) {
    final isSelected = key == activeKey;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        context.read<OrganizationBloc>().add(FetchOrganizationDataEvent(bucket: key));
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF1E293B) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? (isDark ? Colors.white : const Color(0xFF0F172A)) : Colors.grey,
          ),
        ),
      ),
    );
  }

  // On-Time Completion (By Due Window) Card
  Widget _buildOnTimeCompletionCard(BuildContext context, AppStrings s, dynamic performance) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int dayVal = 90;
    int weekVal = 48;
    int monthVal = 49;
    int quarterVal = 56;
    int yearVal = 63;

    if (performance is DashboardPerformance) {
      dayVal = performance.day ?? 90;
      weekVal = performance.week ?? 48;
      monthVal = performance.month ?? 49;
      quarterVal = performance.quarter ?? 56;
      yearVal = performance.year ?? 63;
    } else if (performance is Map<String, dynamic>) {
      dayVal = (performance['day'] as int?) ?? 90;
      weekVal = (performance['week'] as int?) ?? 48;
      monthVal = (performance['month'] as int?) ?? 49;
      quarterVal = (performance['quarter'] as int?) ?? 56;
      yearVal = (performance['year'] as int?) ?? 63;
    }

    Color getColor(int val) {
      if (val >= 75) return const Color(0xFF16A34A);
      if (val >= 50) return const Color(0xFFD97706);
      return const Color(0xFFDC2626);
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.onTimeCompletionDueWindow,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRingGauge(context, '$dayVal%', s.today, getColor(dayVal), (dayVal / 100.0).clamp(0.0, 1.0)),
                _buildRingGauge(context, '$weekVal%', 'This Week', getColor(weekVal), (weekVal / 100.0).clamp(0.0, 1.0)),
                _buildRingGauge(context, '$monthVal%', 'This Month', getColor(monthVal), (monthVal / 100.0).clamp(0.0, 1.0)),
                _buildRingGauge(context, '$quarterVal%', 'Quarter', getColor(quarterVal), (quarterVal / 100.0).clamp(0.0, 1.0)),
                _buildRingGauge(context, '$yearVal%', 'FY', getColor(yearVal), (yearVal / 100.0).clamp(0.0, 1.0)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRingGauge(BuildContext context, String percentStr, String label, Color color, double value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: CircularProgressIndicator(
                value: value,
                backgroundColor: Colors.grey.shade200,
                color: color,
                strokeWidth: 6,
              ),
            ),
            Text(
              percentStr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  // Task Status Distribution Card
  Widget _buildTaskStatusDistributionCard(BuildContext context, AppStrings s, dynamic stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.taskStatusDistribution,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Donut Visual
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: (stats.completed / (stats.total > 0 ? stats.total : 1)).clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFF3866D6).withValues(alpha: 0.2),
                        color: const Color(0xFF1F9D57),
                        strokeWidth: 14,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${stats.total}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const Text(
                          'total',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),

                // Status List
                Expanded(
                  child: Column(
                    children: [
                      _buildStatusLegendRow('Completed', '${stats.completed}', '${stats.completionRate}%', const Color(0xFF1F9D57)),
                      const SizedBox(height: 6),
                      _buildStatusLegendRow('In Progress', '${stats.inProgress}', '20%', const Color(0xFF0284C7)),
                      const SizedBox(height: 6),
                      _buildStatusLegendRow('To be Started', '${stats.toBeStarted}', '16%', const Color(0xFF3866D6)),
                      const SizedBox(height: 6),
                      _buildStatusLegendRow('On hold / Dropped', '${stats.dropped + stats.hold}', '2%', Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '🚩 ${stats.overdue} overdue (past due date, not yet completed)',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLegendRow(String label, String countStr, String percentStr, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.rectangle, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
        Text(countStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        SizedBox(width: 32, child: Text(percentStr, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.right)),
      ],
    );
  }

  // Priority Load Card
  Widget _buildPriorityLoadCard(BuildContext context, AppStrings s, dynamic stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.priorityLoadTitle,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildBarRow(s.emergencyPriority, stats.emergency, 283, Colors.red),
            const SizedBox(height: 10),
            _buildBarRow(s.topMostPriority, stats.topMost, 283, Colors.orange),
            const SizedBox(height: 10),
            _buildBarRow(s.highPriority, stats.high, 283, Colors.amber.shade700),
            const SizedBox(height: 10),
            _buildBarRow(s.mediumPriority, stats.medium, 283, Colors.blue),
            const SizedBox(height: 10),
            _buildBarRow(s.lowPriority, stats.low, 283, Colors.grey),
          ],
        ),
      ),
    );
  }

  // Completion By Branch Card
  Widget _buildCompletionByBranchCard(BuildContext context, AppStrings s, List<BranchUnitStatModel> branchStats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final units = branchStats;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.completionByBranch,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...units.map((u) {
              final color = u.branch.code == 'SS00' ? const Color(0xFF0F766E) : const Color(0xFF0D9488);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white : Colors.black87),
                          children: [
                            TextSpan(text: '${u.branch.code} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: u.branch.name),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (u.stats.completionRate / 100).clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.shade200,
                        color: color,
                        minHeight: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${u.stats.completionRate}%',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Workload By Deadline (Open Tasks) Card
  Widget _buildWorkloadByDeadlineCard(BuildContext context, AppStrings s, dynamic byDeadline, int overdueCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final overdue = overdueCount > 0 ? overdueCount : 52;
    final dueToday = byDeadline.today > 0 ? byDeadline.today : 1;
    final thisWeek = byDeadline.thisWeek > 0 ? byDeadline.thisWeek : 5;
    final thisMonth = byDeadline.thisMonth;
    final later = byDeadline.later > 0 ? byDeadline.later : 23;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.workloadByDeadlineOpenTasks,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildBarRow('Overdue', overdue, 52, Colors.red),
            const SizedBox(height: 10),
            _buildBarRow('Due today', dueToday, 52, Colors.orange),
            const SizedBox(height: 10),
            _buildBarRow('This week', thisWeek, 52, Colors.amber.shade700),
            const SizedBox(height: 10),
            _buildBarRow('This month', thisMonth, 52, Colors.blue),
            const SizedBox(height: 10),
            _buildBarRow('Later', later, 52, Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildBarRow(String label, int val, int maxVal, Color color) {
    final progress = val > 0 ? (val / (maxVal > 0 ? maxVal : 1)).clamp(0.04, 1.0) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 10,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$val',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
