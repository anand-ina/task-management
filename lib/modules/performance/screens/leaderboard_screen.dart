import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../bloc/performance_bloc.dart';
import '../bloc/performance_event.dart';
import '../bloc/performance_state.dart';
import '../models/leaderboard_model.dart';
import '../models/ledger_model.dart';
import '../repository/performance_repository.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return BlocProvider(
      create: (context) => PerformanceBloc()..add(FetchLeaderboardEvent()),
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
          drawer: const CustomLeftDrawer(currentRoute: '/leaderboard'),
          appBar: const CustomAppBar(),
          body: BlocBuilder<PerformanceBloc, PerformanceState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<PerformanceBloc>().add(FetchLeaderboardEvent());
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
                                onPressed: () => context.read<PerformanceBloc>().add(FetchLeaderboardEvent()),
                                child: Text(s.retryButton),
                              ),
                            ],
                          ),
                        )
                      else if (state is LeaderboardLoadedState) ...[
                        // Header Red Banner
                        _buildHeaderBanner(context, s, state.data),
                        const SizedBox(height: 20),

                        // Team Leaderboard Table Section
                        _buildTeamLeaderboard(context, s, state.data.members),
                        const SizedBox(height: 24),

                        // My Points Ledger Table Section
                        _buildMyPointsLedger(context, s, state.data.ledger),
                        const SizedBox(height: 24),

                        // Achievement Badges Grid
                        _buildAchievementBadges(context, s),
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

  Widget _buildHeaderBanner(BuildContext context, AppStrings s, LeaderboardDashboardData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFC2410C), // Red-Orange banner fill matching Image 2
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
            s.leaderboardTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            '${s.leaderboardSubtitle} · You: ${data.me.points} pts · ${data.me.done} done',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLeaderboard(BuildContext context, AppStrings s, List<LeaderboardMemberModel> members) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              s.teamLeaderboardHeader,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 2),
            Text(
              s.teamLeaderboardSubtitle,
              style: TextStyle(fontSize: 9, color: isDark ? Colors.white54 : Colors.black45),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 720),
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 54,
                horizontalMargin: 16,
                columnSpacing: 24,
                columns: [
                  const DataColumn(label: Text('#', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text(s.memberHeader, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text(s.departmentHeader, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text(s.doneHeader, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text(s.assignedHeader, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text(s.overdueHeader, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text(s.pointsHeader, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                ],
                rows: List.generate(members.length, (index) {
                  final m = members[index];
                  final isTop3 = index < 3;

                  return DataRow(
                    cells: [
                      DataCell(Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isTop3 ? const Color(0xFFB91C1C) : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      )),
                      DataCell(Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: _hexToColor(m.avatarColor),
                            child: Text(
                              m.initials,
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            m.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      )),
                      DataCell(Text(
                        m.department,
                        style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54),
                      )),
                      DataCell(Text(
                        '${m.done}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                      )),
                      DataCell(Text('${m.assigned}', style: const TextStyle(fontSize: 10))),
                      DataCell(Text(
                        '${m.overdue}',
                        style: TextStyle(
                          fontSize: 10,
                          color: m.overdue > 0 ? const Color(0xFFDC2626) : Colors.grey,
                        ),
                      )),
                      DataCell(Text(
                        '${m.points}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      )),
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

  Widget _buildMyPointsLedger(BuildContext context, AppStrings s, LedgerModel ledger) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              s.myPointsLedgerHeader,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${s.runningBalanceLabel} · ${ledger.total} pts total',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 700),
              child: DataTable(
                headingRowHeight: 38,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 50,
                horizontalMargin: 16,
                columnSpacing: 30,
                columns: [
                  const DataColumn(label: Text('DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text(s.reasonHeader, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                  const DataColumn(label: Text('TASK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text(s.changeHeader, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text(s.balanceHeader, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                ],
                rows: ledger.rows.map((row) {
                  final isNegative = row.points < 0;

                  return DataRow(
                    cells: [
                      DataCell(Text(_formatLedgerDate(row.createdAt), style: const TextStyle(fontSize: 12))),
                      DataCell(Text(row.reason, style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)))),
                      DataCell(Text(row.taskNo ?? '—', style: const TextStyle(fontSize: 12, color: Colors.grey))),
                      DataCell(Text(
                        '${row.points}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isNegative ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                        ),
                      )),
                      DataCell(Text(
                        '${row.balance}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementBadges(BuildContext context, AppStrings s) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final badges = [
      {'title': 'Streak Master', 'desc': '5+ consecutive on-time completions', 'icon': Icons.local_fire_department_rounded, 'earned': true},
      {'title': 'Speed Demon', 'desc': 'Complete a task before deadline', 'icon': Icons.bolt_rounded, 'earned': false},
      {'title': 'Bullseye', 'desc': '100% weekly completion', 'icon': Icons.track_changes_rounded, 'earned': false},
      {'title': 'Team Player', 'desc': 'Completed a multi-assignee task', 'icon': Icons.handshake_rounded, 'earned': true},
      {'title': 'Zero Overdue', 'desc': 'No overdue for an entire month', 'icon': Icons.stars_rounded, 'earned': false},
      {'title': 'Branch Champ', 'desc': 'Highest branch completion rate', 'icon': Icons.emoji_events_rounded, 'earned': false},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.achievementBadgesHeader,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),

        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 3 : 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 80,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final b = badges[index];
                final isEarned = b['earned'] as bool;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        b['icon'] as IconData,
                        size: 26,
                        color: isEarned ? const Color(0xFFD97706) : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b['title'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              b['desc'] as String,
                              style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white54 : Colors.black45),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isEarned
                              ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isEarned ? 'Earned' : 'Locked',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isEarned
                                ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D))
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  String _formatLedgerDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year.toString().substring(2)}';
    } catch (_) {
      return isoString;
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
