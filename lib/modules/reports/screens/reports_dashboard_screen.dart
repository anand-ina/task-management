import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../bloc/reports_bloc.dart';
import '../bloc/reports_event.dart';
import '../bloc/reports_state.dart';
import '../models/report_stats_model.dart';
import '../models/status_report_model.dart';

class ReportsDashboardScreen extends StatefulWidget {
  const ReportsDashboardScreen({super.key});

  @override
  State<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends State<ReportsDashboardScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: DSR, 2: WSR, 3: MSR

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => ReportsBloc()..add(FetchReportsDashboardEvent()),
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
          drawer: const CustomLeftDrawer(currentRoute: '/reports-dashboard'),
          appBar: const CustomAppBar(),
          body: BlocBuilder<ReportsBloc, ReportsState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<ReportsBloc>().add(FetchReportsDashboardEvent());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Title & Subtitle
                      Text(
                        s.reportsDashboardTitle,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your DSR / WSR / MSR status reports at a glance.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (state is ReportsLoadingState)
                        const Padding(
                          padding: EdgeInsets.all(60),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
                        )
                      else if (state is ReportsErrorState)
                        Center(
                          child: Column(
                            children: [
                              Text(state.message, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => context.read<ReportsBloc>().add(FetchReportsDashboardEvent()),
                                child: Text(s.retryButton),
                              ),
                            ],
                          ),
                        )
                      else if (state is ReportsDashboardLoadedState) ...[
                        // Top Summary Stat Cards Grid (Submitted Today, Total Reports, Submitted, Draft)
                        _buildTopStatCards(context, s, state.data.stats),
                        const SizedBox(height: 16),

                        // Secondary Stat Cards Row (Daily DSR, Weekly WSR, Monthly MSR)
                        _buildSecondaryStatCards(context, s, state.data.stats),
                        const SizedBox(height: 24),

                        // My Reports List Section (Replaces DSR Compliance)
                        _buildMyReportsSection(context, s, state.data.reports),
                      ] else
                        const SizedBox.shrink(),
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

  Widget _buildTopStatCards(BuildContext context, AppStrings s, ReportStatsModel stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cards = [
      {'title': s.submittedTodayLabel, 'value': stats.submittedToday, 'icon': Icons.mark_email_read_outlined, 'color': const Color(0xFF2563EB)},
      {'title': s.totalReportsLabel, 'value': stats.total, 'icon': Icons.calendar_month_outlined, 'color': Colors.grey.shade600},
      {'title': s.submittedLabel, 'value': stats.submitted, 'icon': Icons.check_rounded, 'color': const Color(0xFF0F172A)},
      {'title': s.draftLabel, 'value': stats.draft, 'icon': Icons.edit_outlined, 'color': Colors.grey.shade600},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final crossCount = isWide ? 4 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 80,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final c = cards[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(c['icon'] as IconData, size: 22, color: c['color'] as Color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${c['value']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          c['title'] as String,
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSecondaryStatCards(BuildContext context, AppStrings s, ReportStatsModel stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      {'title': s.dailyDsrLabel, 'value': stats.dsr, 'icon': Icons.wb_sunny_outlined, 'borderColor': const Color(0xFFD97706)},
      {'title': s.weeklyWsrLabel, 'value': stats.wsr, 'icon': Icons.calendar_month_outlined, 'borderColor': const Color(0xFF2563EB)},
      {'title': s.monthlyMsrLabel, 'value': stats.msr, 'icon': Icons.calendar_today_outlined, 'borderColor': const Color(0xFFDC2626)},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final crossCount = isWide ? 3 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 76,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final borderColor = item['borderColor'] as Color;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(color: borderColor, width: 4),
                  top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  right: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  Icon(item['icon'] as IconData, size: 22, color: borderColor),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item['value']}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        item['title'] as String,
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyReportsSection(BuildContext context, AppStrings s, List<dynamic> reportsRaw) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Parse reports into StatusReportItemModel list
    List<StatusReportItemModel> reports = [];
    for (var r in reportsRaw) {
      if (r is StatusReportItemModel) {
        reports.add(r);
      } else if (r is Map<String, dynamic>) {
        reports.add(StatusReportItemModel.fromJson(r));
      }
    }

    // Filter based on selected tab index
    List<StatusReportItemModel> filtered = reports;
    if (_selectedFilterIndex == 1) {
      filtered = reports.where((r) => r.type.toLowerCase() == 'dsr').toList();
    } else if (_selectedFilterIndex == 2) {
      filtered = reports.where((r) => r.type.toLowerCase() == 'wsr').toList();
    } else if (_selectedFilterIndex == 3) {
      filtered = reports.where((r) => r.type.toLowerCase() == 'msr').toList();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-header Title
          Text(
            'My Reports',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          // Tabs Row (All, DSR, WSR, MSR)
          Row(
            children: [
              _buildFilterTab('All', 0),
              const SizedBox(width: 16),
              _buildFilterTab('DSR', 1),
              const SizedBox(width: 16),
              _buildFilterTab('WSR', 2),
              const SizedBox(width: 16),
              _buildFilterTab('MSR', 3),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),

          // Reports List matching Image 1 mockup
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No reports found.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            )
          else
            Column(
              children: filtered.map((r) => _buildReportItemRow(context, s, r)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, int index) {
    final isSelected = _selectedFilterIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? (isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C))
                  : (isDark ? Colors.white60 : Colors.grey),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 30,
            color: isSelected ? (isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C)) : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildReportItemRow(BuildContext context, AppStrings s, StatusReportItemModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSubmitted = item.status.toLowerCase() == 'submitted';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Red Badge (DSR / WSR / MSR)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFB91C1C),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.type.toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title ?? (item.workCompleted ?? 'Report'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                if (item.workCompleted != null && item.workCompleted!.isNotEmpty)
                  Text(
                    item.workCompleted!,
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Right Status Pill (Draft amber or Submitted 🔒 green)
          Row(
            children: [
              Text(
                isSubmitted ? 'Submitted' : 'Draft',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSubmitted ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                ),
              ),
              if (item.isLocked) ...[
                const SizedBox(width: 4),
                const Icon(Icons.lock_outline_rounded, size: 12, color: Color(0xFF16A34A)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
