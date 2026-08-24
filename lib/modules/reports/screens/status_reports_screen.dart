import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/dialogs/new_status_report_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../bloc/status_reports_bloc.dart';
import '../bloc/status_reports_event.dart';
import '../bloc/status_reports_state.dart';
import '../models/status_report_model.dart';

class StatusReportsScreen extends StatefulWidget {
  const StatusReportsScreen({super.key});

  @override
  State<StatusReportsScreen> createState() => _StatusReportsScreenState();
}

class _StatusReportsScreenState extends State<StatusReportsScreen> {
  int _selectedTabIndex = 0; // 0: All, 1: Daily (DSR), 2: Weekly (WSR), 3: Monthly (MSR)

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => StatusReportsBloc()..add(FetchStatusReportsEvent()),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldExit = await ExitConfirmationDialog.show(context);
          if (shouldExit) {
            // Handled in exit dialog
          }
        },
        child: Scaffold(
          drawer: const CustomLeftDrawer(currentRoute: '/reports'),
          appBar: const CustomAppBar(),
          body: BlocBuilder<StatusReportsBloc, StatusReportsState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<StatusReportsBloc>().add(FetchStatusReportsEvent());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Subtitle + New Report Button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.myStatusReports,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  s.myStatusReportsSubtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final shouldReload = await NewStatusReportDialog.show(context);
                              if (shouldReload == true && context.mounted) {
                                context.read<StatusReportsBloc>().add(FetchStatusReportsEvent());
                              }
                            },
                             label: Text(s.newReportButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tabs Bar (All, Daily DSR, Weekly WSR, Monthly MSR)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTabItem('All', 0),
                            const SizedBox(width: 16),
                            _buildTabItem(s.dailyDsr, 1),
                            const SizedBox(width: 16),
                            _buildTabItem(s.weeklyWsr, 2),
                            const SizedBox(width: 16),
                            _buildTabItem(s.monthlyMsr, 3),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Content State
                      if (state is StatusReportsLoadingState)
                        const Padding(
                          padding: EdgeInsets.all(60),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
                        )
                      else if (state is StatusReportsErrorState)
                        Center(
                          child: Column(
                            children: [
                              Text(state.message, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => context.read<StatusReportsBloc>().add(FetchStatusReportsEvent()),
                                child: Text(s.retryButton),
                              ),
                            ],
                          ),
                        )
                      else if (state is StatusReportsLoadedState)
                        _buildReportsList(context, s, state.reports)
                      else
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

  Widget _buildTabItem(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
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
            width: 40,
            color: isSelected ? (isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C)) : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList(BuildContext context, AppStrings s, List<StatusReportItemModel> reports) {
    List<StatusReportItemModel> filtered = reports;

    if (_selectedTabIndex == 1) {
      filtered = reports.where((r) => r.type.toLowerCase() == 'dsr').toList();
    } else if (_selectedTabIndex == 2) {
      filtered = reports.where((r) => r.type.toLowerCase() == 'wsr').toList();
    } else if (_selectedTabIndex == 3) {
      filtered = reports.where((r) => r.type.toLowerCase() == 'msr').toList();
    }

    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text('No status reports submitted yet.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Column(
      children: filtered.map((item) => _buildReportCard(context, s, item)).toList(),
    );
  }

  Widget _buildReportCard(BuildContext context, AppStrings s, StatusReportItemModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSubmitted = item.status.toLowerCase() == 'submitted';
    final dateStr = _formatReportDate(item.periodDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row (DSR badge + Title + Status Pill + Locked Pill + Period Date)
          Row(
            children: [
              // Type Badge (DSR / WSR / MSR)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFB91C1C),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.type.toUpperCase(),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 3),

              // Title: DSR · 21 Aug 2026
              Text(
                '${item.type.toUpperCase()} · $dateStr',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 3),

              // Status Badge (● Draft or ● Submitted)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSubmitted
                          ? const Color(0xFFDCFCE7)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isSubmitted ? const Color(0xFF16A34A) : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isSubmitted ? 'Submitted' : 'Draft',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: isSubmitted ? const Color(0xFF15803D) : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.isLocked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.lock_outline_rounded, size: 10, color: Colors.grey),
                          SizedBox(width: 2),
                          Text(
                            'Locked',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Locked Badge


              // const Spacer(),

              // Period Date on Right
              Text(
                'Period: $dateStr',
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Body text snippet
          Text(
            item.workCompleted ?? item.title ?? 'No details provided.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Footer Row
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSubmitted
                    ? 'Submitted ${_formatSubmittedAt(item.submittedAt)}'
                    : 'Draft',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
               if (item.isLocked)
                Text(
                  s.lockedContactDirector,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatReportDate(String dateIso) {
    try {
      final dt = DateTime.parse(dateIso);
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return dateIso;
    }
  }

  String _formatSubmittedAt(String? dateIso) {
    if (dateIso == null || dateIso.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateIso);
      return DateFormat('d MMM, HH:mm').format(dt);
    } catch (_) {
      return dateIso;
    }
  }
}
