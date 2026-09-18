import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/utils/network_connectivity_service.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/dialogs/no_internet_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../models/lookup_models.dart';
import '../models/ticket_insights_model.dart';
import '../repository/complaints_repository.dart';
import 'complaints_screen.dart';

class ComplaintsHistoryInsightsScreen extends StatefulWidget {
  const ComplaintsHistoryInsightsScreen({super.key});

  @override
  State<ComplaintsHistoryInsightsScreen> createState() => _ComplaintsHistoryInsightsScreenState();
}

class _ComplaintsHistoryInsightsScreenState extends State<ComplaintsHistoryInsightsScreen> {
  final ComplaintsRepository _repository = ComplaintsRepository();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedYear = 2026;
  int? _selectedBranchId; // null or 0 = All branches
  List<LookupBranchModel> _branches = [];
  TicketInsightsResponse _insights = const TicketInsightsResponse();
  bool _isLoading = true;
  String? _errorMessage;

  final List<int> _academicYears = [2026, 2025, 2024];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final hasNet = await NetworkConnectivityService().checkConnection();
    if (!hasNet && mounted) {
      NoInternetDialog.showForceLogout(context);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final branches = await _repository.getBranches();
      final insights = await _repository.getTicketInsights(
        year: _selectedYear,
        branchId: _selectedBranchId,
      );

      if (mounted) {
        setState(() {
          _branches = branches;
          _insights = insights;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _fetchInsightsOnly() async {
    final hasNet = await NetworkConnectivityService().checkConnection();
    if (!hasNet && mounted) {
      NoInternetDialog.showForceLogout(context);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final insights = await _repository.getTicketInsights(
        year: _selectedYear,
        branchId: _selectedBranchId,
      );

      if (mounted) {
        setState(() {
          _insights = insights;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
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
        drawer: const CustomLeftDrawer(currentRoute: '/complaints/history'),
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: SafeArea(
          child: RefreshIndicator(
            color: const Color(0xFF8B1D24),
            onRefresh: _fetchInsightsOnly,
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: Color(0xFF8B1D24)),
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
                        // Header: Title, Academic Year, Branch Selector, Back button
                        _buildHeader(s, isDark, isMobile),
                        const SizedBox(height: 16),

                        if (_errorMessage != null) ...[
                          _buildErrorBanner(_errorMessage!, isDark),
                          const SizedBox(height: 16),
                        ],

                        // Summary Stat Cards
                        _buildStatCardsRow(s, isDark),
                        const SizedBox(height: 20),

                        // Middle Visuals: Received Per Month (Stacked Bar Chart) & Complaints By Category
                        if (isMobile) ...[
                          _buildMonthlyChartCard(s, isDark),
                          const SizedBox(height: 16),
                          _buildCategoryProgressCard(s, isDark),
                        ] else ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: _buildMonthlyChartCard(s, isDark),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 5,
                                child: _buildCategoryProgressCard(s, isDark),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Bottom Section: Staff Table & Student/Family Container List
                        if (isMobile) ...[
                          _buildStaffTableCard(s, isDark),
                          const SizedBox(height: 16),
                          _buildStudentContainerListCard(s, isDark),
                        ] else ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: _buildStaffTableCard(s, isDark),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 5,
                                child: _buildStudentContainerListCard(s, isDark),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppStrings s, bool isDark, bool isMobile) {
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
                    s.voiceOfParentsAndStudents,
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.academicYearSubtitle(yearDisplay),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (!isMobile) ...[
              _buildHeaderControls(s, isDark),
            ],
          ],
        ),
        if (isMobile) ...[
          const SizedBox(height: 12),
          _buildHeaderControls(s, isDark),
        ],
      ],
    );
  }

  Widget _buildHeaderControls(AppStrings s, bool isDark) {
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
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedYear,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              items: yearOptions,
              onChanged: (val) {
                if (val != null && val != _selectedYear) {
                  setState(() {
                    _selectedYear = val;
                  });
                  _fetchInsightsOnly();
                }
              },
            ),
          ),
        ),

        // Branch Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: _selectedBranchId,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(s.allBranches, style: const TextStyle(fontSize: 12)),
                ),
                ..._branches.map((b) {
                  return DropdownMenuItem<int?>(
                    value: b.id,
                    child: Text(b.name, style: const TextStyle(fontSize: 12)),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedBranchId = val;
                });
                _fetchInsightsOnly();
              },
            ),
          ),
        ),

        // Back to tracker Button
        OutlinedButton.icon(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ComplaintsScreen()),
              );
            }
          },
          icon: const Icon(Icons.arrow_back_rounded, size: 14),
          label: Text(s.backToTracker, style: const TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? Colors.white70 : const Color(0xFF334155),
            side: BorderSide(color: isDark ? Colors.grey.shade700 : const Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  Widget _buildStatCardsRow(AppStrings s, bool isDark) {
    final totals = _insights.totals;

    final cards = [
      _buildStatCard(
        count: totals.total.toString(),
        label: s.statTotalReceived,
        accentColor: const Color(0xFF334155),
        isDark: isDark,
      ),
      _buildStatCard(
        count: totals.complaints.toString(),
        label: s.statComplaints,
        accentColor: const Color(0xFFEF4444),
        isDark: isDark,
      ),
      _buildStatCard(
        count: totals.feedback.toString(),
        label: s.statFeedback,
        accentColor: const Color(0xFF3B82F6),
        isDark: isDark,
      ),
      _buildStatCard(
        count: totals.appreciations.toString(),
        label: s.statAppreciations,
        accentColor: const Color(0xFF10B981),
        isDark: isDark,
      ),
      _buildStatCard(
        count: totals.pendingReward.toString(),
        label: s.statAwaitingDirectorApproval,
        accentColor: const Color(0xFFB91C1C),
        isDark: isDark,
      ),
      _buildStatCard(
        count: totals.avgDays != null ? '${totals.avgDays}d' : '—',
        label: s.statAvgTimeToResolve,
        accentColor: const Color(0xFF06B6D4),
        isDark: isDark,
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
  }) {
    return Container(
      width: 145,
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
              color: accentColor,
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
    );
  }

  Widget _buildMonthlyChartCard(AppStrings s, bool isDark) {
    final months = _insights.byMonth;

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
              height: 170,
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
                          height: (total * 18.0).clamp(20.0, 130.0),
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

  Widget _buildCategoryProgressCard(AppStrings s, bool isDark) {
    final categories = _insights.byCategory;
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
                      Text(
                        '${cat.count}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
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

  Widget _buildStaffTableCard(AppStrings s, bool isDark) {
    final staffList = _insights.byStaff;

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
          Row(
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
                horizontalMargin: 4,
                columnSpacing: 18,
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

  /// By Student / Family Card rendered as a container list (NOT a table format) per user instruction
  Widget _buildStudentContainerListCard(AppStrings s, bool isDark) {
    final students = _insights.byStudent;

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
                      fontSize: 10,
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
              padding: const EdgeInsets.symmetric(vertical: 24),
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
                final student = students[index];
                return _buildStudentContainerItem(student, s, isDark);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStudentContainerItem(InsightsStudentItem student, AppStrings s, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Student name, class badge
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF8B1D24).withOpacity(0.12),
                child: Text(
                  student.studentName.isNotEmpty ? student.studentName[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B1D24),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  student.studentName.isNotEmpty ? student.studentName : s.anonymousHint,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (student.classSection.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${s.classHeader} ${student.classSection}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Last activity timestamp
          if (student.lastAt.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
                const SizedBox(width: 4),
                Text(
                  '${s.lastActivityLabel}: ${_formatDate(student.lastAt)}',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Counts Pills Row
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildStudentPill(
                label: s.statComplaints,
                count: student.complaints,
                color: const Color(0xFFEF4444),
                isDark: isDark,
              ),
              _buildStudentPill(
                label: s.statFeedback,
                count: student.feedback,
                color: const Color(0xFF3B82F6),
                isDark: isDark,
              ),
              _buildStudentPill(
                label: s.statAppreciations,
                count: student.appreciations,
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentPill({
    required String label,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
