import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../bloc/reports_bloc.dart';
import '../bloc/reports_event.dart';
import '../bloc/reports_state.dart';
import '../models/report_compliance_model.dart';
import '../models/report_stats_model.dart';

class ReportsDashboardScreen extends StatefulWidget {
  const ReportsDashboardScreen({super.key});

  @override
  State<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends State<ReportsDashboardScreen> {
  final Set<String> _expandedDayKeys = {};

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
                      // Title
                      Text(
                        s.reportsDashboardTitle,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                        // Top Summary Stat Cards Grid
                        _buildTopStatCards(context, s, state.data.stats),
                        const SizedBox(height: 16),

                        // Secondary Stat Cards Row
                        _buildSecondaryStatCards(context, s, state.data.stats),
                        const SizedBox(height: 24),

                        // DSR Compliance Section
                        _buildDsrComplianceSection(context, s, state.data.compliance),
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
      {'title': s.submittedTodayLabel, 'value': stats.submittedToday, 'icon': Icons.stars_rounded, 'color': Colors.red},
      {'title': s.totalReportsLabel, 'value': stats.total, 'icon': Icons.description_outlined, 'color': Colors.grey},
      {'title': s.submittedLabel, 'value': stats.submitted, 'icon': Icons.check_circle_outline_rounded, 'color': Colors.green},
      {'title': s.draftLabel, 'value': stats.draft, 'icon': Icons.edit_note_rounded, 'color': Colors.grey},
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
                  Icon(c['icon'] as IconData, size: 24, color: c['color'] as Color),
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
      {'title': s.dailyDsrLabel, 'value': stats.dsr, 'icon': Icons.light_mode_outlined, 'color': Colors.amber},
      {'title': s.weeklyWsrLabel, 'value': stats.wsr, 'icon': Icons.calendar_month_outlined, 'color': Colors.blue},
      {'title': s.monthlyMsrLabel, 'value': stats.msr, 'icon': Icons.calendar_today_outlined, 'color': Colors.red},
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
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(item['icon'] as IconData, size: 22, color: item['color'] as Color),
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

  Widget _buildDsrComplianceSection(BuildContext context, AppStrings s, ReportComplianceModel compliance) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title & Subtitle
        Row(
          children: [
            Text(
              s.dsrComplianceHeader,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.dsrComplianceSubtitle,
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black45),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Compliance Days List
        if (compliance.days.isEmpty)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: Text('No compliance data available.', style: TextStyle(color: Colors.grey))),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: compliance.days.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final dayItem = compliance.days[index];
                final isExpanded = _expandedDayKeys.contains(dayItem.day);

                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedDayKeys.remove(dayItem.day);
                          } else {
                            _expandedDayKeys.add(dayItem.day);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            // Day formatted text e.g. Thu 20 Aug
                            SizedBox(
                              width: 100,
                              child: Text(
                                _formatComplianceDay(dayItem.day),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Progress Bar
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: dayItem.rate / 100.0,
                                  minHeight: 8,
                                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Stats text e.g. 0 filed · 26 missed 0%
                            Text(
                              '${dayItem.filed} ${s.filedLabel} · ${dayItem.missed} ${s.missedLabel}   ${dayItem.rate.toInt()}%',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Expand Arrow
                            Icon(
                              isExpanded ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Expanded Missed Users Chips Section
                    if (isExpanded && dayItem.missedUsers.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: dayItem.missedUsers.map((user) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: _hexToColor(user.avatarColor),
                                    child: Text(
                                      user.initials,
                                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${user.name} · ${user.department}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  String _formatComplianceDay(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${weekdays[dt.weekday - 1]} ${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]}';
    } catch (_) {
      return dateStr;
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
