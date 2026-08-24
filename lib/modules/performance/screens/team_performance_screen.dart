import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../bloc/performance_bloc.dart';
import '../bloc/performance_event.dart';
import '../bloc/performance_state.dart';
import '../models/team_performance_model.dart';

class TeamPerformanceScreen extends StatelessWidget {
  const TeamPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return BlocProvider(
      create: (context) => PerformanceBloc()..add(FetchTeamPerformanceEvent()),
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
          drawer: const CustomLeftDrawer(currentRoute: '/team-performance'),
          appBar: const CustomAppBar(),
          body: BlocBuilder<PerformanceBloc, PerformanceState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<PerformanceBloc>().add(FetchTeamPerformanceEvent());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state is PerformanceLoadingState)
                        const Padding(
                          padding: EdgeInsets.all(60),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
                        )
                      else if (state is PerformanceErrorState)
                        Center(
                          child: Column(
                            children: [
                              Text(state.message, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => context.read<PerformanceBloc>().add(FetchTeamPerformanceEvent()),
                                child: Text(s.retryButton),
                              ),
                            ],
                          ),
                        )
                      else if (state is TeamPerformanceLoadedState) ...[
                        // Dark Teal Header Banner
                        _buildHeaderBanner(context, s, state.data),
                        const SizedBox(height: 16),

                        // Totals Summary Tiles Grid
                        _buildTotalsTiles(context, s, state.data.totals),
                        const SizedBox(height: 24),

                        // Workload & Delivery Table Section
                        _buildWorkloadTable(context, s, state.data.members),
                        const SizedBox(height: 24),

                        // By Department Section
                        _buildByDepartment(context, s, state.data.departments),
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

  Widget _buildHeaderBanner(BuildContext context, AppStrings s, TeamPerformanceModel data) {
    final totals = data.totals;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF115E59), // Dark Teal fill matching Image 4
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERFORMANCE',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.2),
          ),
          const SizedBox(height: 4),
          Text(
            s.teamPerformanceTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            '${totals.teamSize} members · ${totals.assigned} assignments · ${totals.done} completed · ${totals.overdue} overdue',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsTiles(BuildContext context, AppStrings s, TeamTotalsModel totals) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tiles = [
      {'val': '${totals.teamSize}', 'title': s.teamSizeLabel, 'sub': 'members in your scope', 'color': Colors.black87},
      {'val': '${totals.assigned}', 'title': s.assignmentsLabel, 'sub': 'across all members', 'color': Colors.blue},
      {'val': '${totals.done}', 'title': s.completedLabel, 'sub': '${totals.completion}% completion', 'color': Colors.green},
      {'val': '${totals.inProgress}', 'title': s.inProgressLabel, 'sub': 'work underway', 'color': Colors.blue},
      {'val': '${totals.overdue}', 'title': s.overdueHeader, 'sub': 'needs attention', 'color': Colors.red},
      {'val': '${totals.onTime}%', 'title': s.onTimeLabel, 'sub': 'of completed work', 'color': Colors.green},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final crossCount = isWide ? 6 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 80,
          ),
          itemCount: tiles.length,
          itemBuilder: (context, index) {
            final t = tiles[index];
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t['val'] as String,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : (t['color'] as Color),
                    ),
                  ),
                  Text(
                    t['title'] as String,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                  Text(
                    t['sub'] as String,
                    style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white54 : Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWorkloadTable(BuildContext context, AppStrings s, List<TeamMemberModel> members) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              s.workloadDeliveryHeader,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.workloadDeliverySubtitle,
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (members.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No team member performance data found.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 1000),
              child: DataTable(
                headingRowHeight: 38,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 60,
                horizontalMargin: 12,
                columnSpacing: 18,
                columns: [
                  const DataColumn(label: Text('#', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text(s.memberHeader, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text(s.assignedHeader, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text(s.doneHeader, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text(s.completionHeader, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text(s.inProgressLabel.toUpperCase(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text(s.toStartLabel.toUpperCase(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text(s.overdueHeader, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text(s.dueTodayHeader, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text(s.emgHighHeader, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text(s.droppedHeader, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text(s.onTimeHeader, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text(s.avgDaysHeader, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey))),
                ],
                rows: List.generate(members.length, (index) {
                  final m = members[index];
                  final compRate = m.assigned > 0 ? ((m.done / m.assigned) * 100).toInt() : 0;

                  return DataRow(
                    cells: [
                      DataCell(Text('${index + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DataCell(Row(
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: _hexToColor(m.avatarColor),
                            child: Text(
                              m.initials,
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '${m.designation ?? m.role ?? "Member"} · ${m.department}${m.branchCode != null ? " · ${m.branchCode}" : ""}',
                                style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white54 : Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      )),
                      DataCell(Text('${m.assigned}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold))),
                      DataCell(Text('${m.done}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)))),
                      DataCell(Row(
                        children: [
                          SizedBox(
                            width: 50,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: compRate / 100.0,
                                minHeight: 6,
                                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F172A)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('$compRate%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      )),
                      DataCell(Text('${m.inProgress}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF0284C7)))),
                      DataCell(Text('${m.toBeStarted}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF0284C7)))),
                      DataCell(Text(
                        '${m.overdue}',
                        style: TextStyle(fontSize: 11.5, color: m.overdue > 0 ? const Color(0xFFDC2626) : Colors.grey),
                      )),
                      DataCell(Text('${m.dueToday}', style: const TextStyle(fontSize: 11.5))),
                      DataCell(Text(
                        '${m.emergencyHighOpen}',
                        style: TextStyle(fontSize: 11.5, color: m.emergencyHighOpen > 0 ? const Color(0xFFDC2626) : Colors.grey),
                      )),
                      DataCell(Text('${m.dropped}', style: const TextStyle(fontSize: 11.5))),
                      DataCell(Text('${m.onTime}%', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)))),
                      DataCell(Text(m.avgDays > 0 ? '${m.avgDays}' : '—', style: const TextStyle(fontSize: 11))),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildByDepartment(BuildContext context, AppStrings s, List<DepartmentSummaryModel> departments) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              s.byDepartmentHeader,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              s.byDepartmentSubtitle,
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (departments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No department summary data found.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: departments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final dep = departments[index];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        dep.department,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${dep.members} members',
                        style: TextStyle(fontSize: 9, color: isDark ? Colors.white54 : Colors.grey.shade500),
                      ),
                      const Spacer(),
                      Text(
                        '${dep.done} done',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${dep.assigned} assigned',
                        style: TextStyle(fontSize: 9, color: isDark ? Colors.white54 : Colors.grey.shade600),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${dep.completion}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${dep.overdue} od',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: dep.overdue > 0 ? const Color(0xFFDC2626) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: dep.completion / 100.0,
                      minHeight: 8,
                      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
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
