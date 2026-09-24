import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/utils/network_connectivity_service.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/dialogs/no_internet_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/announcement_banner_wrapper.dart';
import '../../../shared_widgets/dropdowns/searchable_filter_dropdown.dart';
import '../bloc/complaints_bloc.dart';
import '../bloc/complaints_event.dart';
import '../bloc/complaints_state.dart';
import '../models/lookup_models.dart';
import '../models/ticket_insights_model.dart';
import 'appreciations_screen.dart';
import 'complaints_screen.dart';
import 'source_complaints_screen.dart';

class ComplaintsHistoryInsightsScreen extends StatefulWidget {
  const ComplaintsHistoryInsightsScreen({super.key});

  @override
  State<ComplaintsHistoryInsightsScreen> createState() => _ComplaintsHistoryInsightsScreenState();
}

class _ComplaintsHistoryInsightsScreenState extends State<ComplaintsHistoryInsightsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedYear = 2026;
  int? _selectedBranchId; // null = All branches
  final List<int> _academicYears = [2026, 2025, 2024];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDashboard();
    });
  }

  Future<void> _fetchDashboard() async {
    final hasNet = await NetworkConnectivityService().checkConnection();
    if (!hasNet && mounted) {
      NoInternetDialog.showForceLogout(context);
      return;
    }

    if (mounted) {
      context.read<ComplaintsBloc>().add(
            FetchComplaintsDashboardEvent(
              year: _selectedYear,
              branchId: _selectedBranchId,
            ),
          );
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '—';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('d MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatMonth(String monthStr) {
    if (monthStr.isEmpty) return '';
    try {
      final parts = monthStr.split('-');
      if (parts.length == 2) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final dt = DateTime(year, month, 1);
        return DateFormat('MMM').format(dt);
      }
      return monthStr;
    } catch (_) {
      return monthStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 800;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await ExitConfirmationDialog.show(context);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: const CustomAppBar(),
        drawer: const CustomLeftDrawer(currentRoute: '/complaints/dashboard'),
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: AnnouncementBannerWrapper(
          child: SafeArea(
            child: BlocBuilder<ComplaintsBloc, ComplaintsState>(
            builder: (context, state) {
              TicketInsightsResponse insights = const TicketInsightsResponse();
              List<LookupBranchModel> branches = [];
              bool isLoading = false;
              String? errorMessage;

              if (state is ComplaintsLoadingState) {
                isLoading = true;
              } else if (state is ComplaintsDashboardLoadedState) {
                insights = state.insights;
                branches = state.branches;
                isLoading = state.isLoading;
                errorMessage = state.errorMessage;
              } else if (state is ComplaintsLoadedState) {
                branches = state.branches;
              }

              return RefreshIndicator(
                color: const Color(0xFF8B1D24),
                onRefresh: _fetchDashboard,
                child: isLoading && insights.byMonth.isEmpty && insights.totals.total == 0
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 20,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Title, Subtitle, Academic Year, Searchable Branch, All tickets
                            _buildHeader(s, isDark, isMobile, branches),
                            const SizedBox(height: 16),

                            if (errorMessage != null) ...[
                              _buildErrorBanner(errorMessage, isDark),
                              const SizedBox(height: 16),
                            ],

                            // Row 1: 5 Stat Cards (Open right now, Past target date, From parents, From students, From staff)
                            _buildTopRowStatCards(insights.totals, s, isDark),
                            const SizedBox(height: 12),

                            // Row 2: 6 Stat Cards (Total received, Complaints, Feedback, Appreciations, Awaiting Director approval, Avg. days)
                            _buildSecondRowStatCards(insights.totals, s, isDark),
                            const SizedBox(height: 20),

                            // Middle Visuals: Stacked Bar Chart & Category Progress
                            if (isMobile) ...[
                              _buildMonthlyChartCard(insights.byMonth, s, isDark),
                              const SizedBox(height: 16),
                              _buildCategoryProgressCard(insights.byCategory, s, isDark),
                            ] else ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: _buildMonthlyChartCard(insights.byMonth, s, isDark),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 5,
                                    child: _buildCategoryProgressCard(insights.byCategory, s, isDark),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 20),

                            // Bottom Section: BY STUDENT / FAMILY Table
                            _buildStudentFamilyTableCard(insights.byStudent, s, isDark),
                            const SizedBox(height: 20),

                            // BY STAFF MEMBER Table (if staff insights exist)
                            if (insights.byStaff.isNotEmpty) ...[
                              _buildStaffTableCard(insights.byStaff, s, isDark),
                              const SizedBox(height: 20),
                            ],

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

  Widget _buildHeader(
    AppStrings s,
    bool isDark,
    bool isMobile,
    List<LookupBranchModel> branches,
  ) {
    final yearDisplay = '$_selectedYear–${(_selectedYear + 1).toString().substring(2)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.complaintsAndFeedbacksDashboard,
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.complaintsDashboardSubtitle(yearDisplay),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (!isMobile) ...[
              _buildHeaderControls(s, isDark, branches),
            ],
          ],
        ),
        if (isMobile) ...[
          const SizedBox(height: 12),
          _buildHeaderControls(s, isDark, branches),
        ],
      ],
    );
  }

  Widget _buildHeaderControls(
    AppStrings s,
    bool isDark,
    List<LookupBranchModel> branches,
  ) {
    final yearOptions = _academicYears.map((y) {
      final label = '$y–${(y + 1).toString().substring(2)}';
      return DropdownMenuItem<int>(
        value: y,
        child: Text(label, style: const TextStyle(fontSize: 12)),
      );
    }).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Year Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedYear,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              items: yearOptions,
              onChanged: (val) {
                if (val != null && val != _selectedYear) {
                  setState(() {
                    _selectedYear = val;
                  });
                  _fetchDashboard();
                }
              },
            ),
          ),
        ),

        // Searchable Branch Dropdown
        SearchableFilterDropdown<int?>(
          value: _selectedBranchId,
          hint: s.allBranches,
          searchHint: 'Search branch...',
          items: [
            SearchableDropdownItem<int?>(value: null, label: s.allBranches),
            ...branches.map(
              (b) => SearchableDropdownItem<int?>(value: b.id, label: b.name),
            ),
          ],
          onChanged: (val) {
            setState(() {
              _selectedBranchId = val;
            });
            _fetchDashboard();
          },
        ),

        // "All tickets" Button
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ComplaintsScreen()),
            );
          },
          icon: const Icon(Icons.confirmation_number_outlined, size: 15),
          label: Text(
            s.allTicketsButton,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade400.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Row 1: 5 Stat Cards (Open right now, Past target date, From parents, From students, From staff)
  Widget _buildTopRowStatCards(InsightsTotalsItem totals, AppStrings s, bool isDark) {
    final cards = [
      _buildStatCard(
        count: totals.open.toString(),
        label: s.openRightNow,
        accentColor: const Color(0xFF10B981),
        isDark: isDark,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ComplaintsScreen(initialStatusTab: 'open'),
            ),
          );
        },
      ),
      _buildStatCard(
        count: totals.overdue.toString(),
        label: s.pastTargetDate,
        accentColor: const Color(0xFFEF4444),
        isDark: isDark,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ComplaintsScreen(initialStatusTab: 'overdue'),
            ),
          );
        },
      ),
      _buildStatCard(
        count: totals.fromParents.toString(),
        label: s.fromParents,
        accentColor: const Color(0xFFF59E0B),
        isDark: isDark,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SourceComplaintsScreen(source: 'parent'),
            ),
          );
        },
      ),
      _buildStatCard(
        count: totals.fromStudents.toString(),
        label: s.fromStudents,
        accentColor: const Color(0xFF3B82F6),
        isDark: isDark,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SourceComplaintsScreen(source: 'student'),
            ),
          );
        },
      ),
      _buildStatCard(
        count: totals.fromStaff.toString(),
        label: s.fromStaff,
        accentColor: const Color(0xFF8B5CF6),
        isDark: isDark,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SourceComplaintsScreen(source: 'staff'),
            ),
          );
        },
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cards
            .map((card) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: card,
                ))
            .toList(),
      ),
    );
  }

  /// Row 2: 6 Stat Cards (Total received, Complaints, Feedback, Appreciations, Awaiting Director approval, Avg. days to resolve)
  Widget _buildSecondRowStatCards(InsightsTotalsItem totals, AppStrings s, bool isDark) {
    final cards = [
      _buildStatCard(
        count: totals.total.toString(),
        label: s.statTotalReceived,
        accentColor: const Color(0xFF334155),
        isDark: isDark,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ComplaintsScreen(initialStatusTab: 'all'),
            ),
          );
        },
      ),
      _buildStatCard(
        count: totals.complaints.toString(),
        label: s.statComplaints,
        accentColor: const Color(0xFFEF4444),
        isDark: isDark,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ComplaintsScreen(initialTypeFilter: 'complaint'),
            ),
          );
        },
      ),
      _buildStatCard(
        count: totals.feedback.toString(),
        label: s.statFeedback,
        accentColor: const Color(0xFF3B82F6),
        isDark: isDark,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ComplaintsScreen(initialTypeFilter: 'feedback'),
            ),
          );
        },
      ),
      _buildStatCard(
        count: totals.appreciations.toString(),
        label: s.statAppreciations,
        accentColor: const Color(0xFF10B981),
        isDark: isDark,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AppreciationsScreen(),
            ),
          );
        },
      ),
      _buildStatCard(
        count: totals.pendingReward.toString(),
        label: s.statAwaitingDirectorApproval,
        accentColor: const Color(0xFFB91C1C),
        isDark: isDark,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AppreciationsScreen(),
            ),
          );
        },
      ),
      _buildStatCard(
        count: totals.avgDays != null ? '${totals.avgDays}d' : '—',
        label: s.avgDaysToResolve,
        accentColor: const Color(0xFF06B6D4),
        isDark: isDark,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ComplaintsScreen(initialStatusTab: 'resolved'),
            ),
          );
        },
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cards
            .map((card) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: card,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildStatCard({
    required String count,
    required String label,
    required Color accentColor,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 148,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 3,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: accentColor == const Color(0xFF334155) && isDark ? Colors.white : accentColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.2,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChartCard(List<InsightsMonthItem> months, AppStrings s, bool isDark) {
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
          // Title and Legend Header
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                s.receivedPerMonth,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendItem('●', const Color(0xFFEF4444), s.statComplaints, isDark),
                  const SizedBox(width: 8),
                  _buildLegendItem('●', const Color(0xFF3B82F6), s.statFeedback, isDark),
                  const SizedBox(width: 8),
                  _buildLegendItem('●', const Color(0xFF10B981), s.statAppreciations, isDark),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Chart Area
          if (months.isEmpty)
            Container(
              height: 160,
              alignment: Alignment.center,
              child: Text(
                s.noDataAvailable,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            )
          else
            SizedBox(
              height: 190,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: months.map((m) {
                  final total = m.total;
                  final monthLabel = _formatMonth(m.month);

                  return Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (total > 0)
                          Text(
                            '$total',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        const SizedBox(height: 4),

                        // Stacked Bar
                        Container(
                          width: 24,
                          height: (total * 22.0).clamp(20.0, 130.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              // Appreciations (Green - Top)
                              if (m.appreciations > 0)
                                Expanded(
                                  flex: m.appreciations,
                                  child: Container(color: const Color(0xFF10B981)),
                                ),
                              // Feedback (Blue - Middle)
                              if (m.feedback > 0)
                                Expanded(
                                  flex: m.feedback,
                                  child: Container(color: const Color(0xFF3B82F6)),
                                ),
                              // Complaints (Red - Bottom)
                              if (m.complaints > 0)
                                Expanded(
                                  flex: m.complaints,
                                  child: Container(color: const Color(0xFFEF4444)),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          monthLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String dot, Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(dot, style: TextStyle(color: color, fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryProgressCard(List<InsightsCategoryItem> categories, AppStrings s, bool isDark) {
    final maxCount = categories.isNotEmpty
        ? categories.map((e) => e.count).reduce((a, b) => a > b ? a : b)
        : 1;

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
          Text(
            s.complaintsByCategory,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 18),

          if (categories.isEmpty)
            Container(
              height: 160,
              alignment: Alignment.center,
              child: Text(
                s.noDataAvailable,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            )
          else
            Column(
              children: categories.map((cat) {
                final ratio = maxCount > 0 ? (cat.count / maxCount).clamp(0.05, 1.0) : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          cat.category,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Container(
                                  height: 8,
                                  width: constraints.maxWidth * ratio,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${cat.count}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  /// BY STUDENT / FAMILY Table matching the exact screenshot
  Widget _buildStudentFamilyTableCard(List<InsightsStudentItem> students, AppStrings s, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.byStudentFamily,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                ),
              ),
              if (students.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${students.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (students.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  s.noDataAvailable,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: students.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final st = students[index];
                final initial = st.studentName.isNotEmpty
                    ? st.studentName.trim()[0].toUpperCase()
                    : '?';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0E7FF),
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF3730A3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    st.studentName.isNotEmpty ? st.studentName : '—',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (st.classSection.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEDE9FE),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      st.classSection,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white70 : const Color(0xFF6D28D9),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (st.lastAt.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 10, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${s.lastRecordedLabel}: ${_formatDate(st.lastAt)}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 3),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        alignment: WrapAlignment.end,
                        children: [
                          _buildCountBadge(st.complaints, const Color(0xFFEF4444), isDark),
                          _buildCountBadge(st.feedback, const Color(0xFF3B82F6), isDark),
                          _buildCountBadge(st.appreciations, const Color(0xFF10B981), isDark),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStaffTableCard(List<InsightsStaffItem> staffList, AppStrings s, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.byStaffMemberDirectorOnly,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (staffList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  s.noDataAvailable,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 42,
                dataRowMaxHeight: 46,
                horizontalMargin: 8,
                columnSpacing: 22,
                columns: [
                  DataColumn(
                    label: Text(
                      s.staffHeader,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      s.statAppreciations.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      s.statComplaints.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      s.statFeedback.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
                rows: staffList.map((st) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          st.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      DataCell(_buildCountBadge(st.appreciations, const Color(0xFF10B981), isDark)),
                      DataCell(_buildCountBadge(st.complaints, const Color(0xFFEF4444), isDark)),
                      DataCell(_buildCountBadge(st.feedback, const Color(0xFF3B82F6), isDark)),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
