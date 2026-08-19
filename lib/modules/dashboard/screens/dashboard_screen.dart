import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/dialogs/todo_today_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../models/dashboard_stats.dart';
import '../models/team_performance.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(FetchDashboardDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentDateStr = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    final authState = context.watch<AuthBloc>().state;
    String userName = 'Vamsi';
    String roleName = 'DIRECTOR';
    String branchName = 'HEAD OFFICE';

    if (authState is AuthenticatedState) {
      userName = authState.userProfile.name;
      roleName = authState.userProfile.role.toUpperCase();
      branchName = authState.userProfile.branch?.name ?? 'HEAD OFFICE';
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await ExitConfirmationDialog.show(context);
        if (shouldExit) {
          // System exit is executed inside ExitConfirmationDialog
        }
      },
      child: Scaffold(
        drawer: const CustomLeftDrawer(currentRoute: '/dashboard'),
        appBar: const CustomAppBar(),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoadingState) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFB91C1C)),
              );
            }

            if (state is DashboardErrorState) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<DashboardBloc>().add(FetchDashboardDataEvent());
                      },
                      child: Text(s.retryButton),
                    ),
                  ],
                ),
              );
            }

            if (state is DashboardLoadedState) {
              final stats = state.dashboardData.stats;
              final performance = state.dashboardData.performance;
              final actionCenter = state.dashboardData.actionCenter;
              final teamData = state.teamData;

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<DashboardBloc>().add(FetchDashboardDataEvent());
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dynamic Header Banner
                      _buildHeaderBanner(
                        context,
                        s,
                        userName: userName,
                        roleName: roleName,
                        branchName: branchName,
                        currentDateStr: currentDateStr,
                        stats: stats,
                        actionCenter: actionCenter,
                      ),
                      const SizedBox(height: 24),

                      // Performance Section
                      Text(
                        s.performanceTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.performanceSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _buildPerformanceGrid(context, s, performance),
                      const SizedBox(height: 28),

                      // Tasks by Priority Section
                      Text(
                        s.tasksByPriority,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildPriorityGrid(context, s, stats),
                      const SizedBox(height: 28),

                      // Total Organisation Section
                      Row(
                        children: [
                          Text(
                            s.totalOrganisation,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.remove_red_eye_outlined, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  s.readOnlyTransparency,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildTotalOrgGrid(context, s, stats),
                      const SizedBox(height: 28),

                      // Team Section (Recent Activity & Team Analytics)
                      _buildTeamSection(context, s, teamData),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),

        // Floating Action Button for To-Do Today
        floatingActionButton: Stack(
          children: [
            FloatingActionButton(
              backgroundColor: const Color(0xFF0B132B),
              foregroundColor: Colors.white,
              onPressed: () => TodoTodayDialog.show(context),
              child: const Icon(Icons.calendar_month_rounded),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: const Text(
                  '2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(
    BuildContext context,
    AppStrings s, {
    required String userName,
    required String roleName,
    required String branchName,
    required String currentDateStr,
    required DashboardStats stats,
    required DashboardActionCenter actionCenter,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$roleName · $branchName',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Today',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  Text(
                    currentDateStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Namaste, $userName 🙏',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.dashboardSubtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 18),

          // Dynamic Stat Badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHeaderBadge(s.approvalsBadge(actionCenter.approvals)),
              _buildHeaderBadge(s.toStartBadge(stats.toBeStarted)),
              _buildHeaderBadge(s.inProgressBadge(stats.inProgress)),
              _buildHeaderBadge(s.overdueBadge(stats.overdue)),
              _buildHeaderBadge(s.completionBadge(stats.completionRate)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPerformanceGrid(
      BuildContext context, AppStrings s, DashboardPerformance performance) {
    final now = DateTime.now();
    final monthStr = DateFormat('MMMM yyyy').format(now);
    final dayStr = DateFormat('EEE d MMM').format(now);

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 900 ? 5 : (constraints.maxWidth > 600 ? 3 : 2);
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _buildProgressCard(s.dayWise, dayStr, performance.day, isDash: performance.day == null),
            _buildProgressCard(s.weekWise, 'This week', performance.week,
                isDash: performance.week == null),
            _buildProgressCard(s.monthWise, monthStr, performance.month ?? 0, color: Colors.amber),
            _buildProgressCard(s.quarterly, 'This quarter', performance.quarter ?? 0,
                color: const Color(0xFF1E3A8A)),
            _buildProgressCard(s.yearly, 'FY ${now.year - 1}–${now.year.toString().substring(2)}',
                performance.year ?? 0,
                color: Colors.green),
          ],
        );
      },
    );
  }

  Widget _buildProgressCard(String title, String subtitle, int? percent,
      {Color color = Colors.blue, bool isDash = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final val = percent ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isDash
                ? Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 6),
                    ),
                    child: const Center(
                      child: Text(
                        '—',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          value: (val / 100).clamp(0.0, 1.0),
                          backgroundColor: Colors.grey.shade200,
                          color: color,
                          strokeWidth: 6,
                        ),
                      ),
                      Text(
                        '$val%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityGrid(BuildContext context, AppStrings s, DashboardStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 900 ? 5 : (constraints.maxWidth > 600 ? 3 : 2);
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildCardWithTopBorder(
              '★★★★★',
              '${stats.emergency}',
              s.emergencyPriority,
              borderColor: Colors.red,
            ),
            _buildCardWithTopBorder(
              '★★★★',
              '${stats.topMost}',
              s.topMostPriority,
              borderColor: Colors.orange,
            ),
            _buildCardWithTopBorder(
              '★★★',
              '${stats.high}',
              s.highPriority,
              borderColor: Colors.amber,
            ),
            _buildCardWithTopBorder(
              '★★',
              '${stats.medium}',
              s.mediumPriority,
              borderColor: Colors.blue,
            ),
            _buildCardWithTopBorder(
              '★',
              '${stats.low}',
              s.lowPriority,
              borderColor: Colors.grey,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCardWithTopBorder(String stars, String count, String label,
      {required Color borderColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(color: borderColor, width: 3),
          left: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          right: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          bottom: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(stars, style: TextStyle(color: borderColor, fontSize: 10)),
          const SizedBox(height: 2),
          Text(
            count,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: borderColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalOrgGrid(BuildContext context, AppStrings s, DashboardStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 900 ? 5 : (constraints.maxWidth > 600 ? 3 : 2);
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard('${stats.total}', s.totalTasks,
                subtitle: 'FY ${DateTime.now().year - 1}–${DateTime.now().year.toString().substring(2)}',
                color: Colors.blue),
            _buildStatCard('${stats.completed}', s.completed,
                subtitle: '${stats.completionRate}% completion', color: Colors.green),
            _buildStatCard('${stats.inProgress}', s.inProgress, color: Colors.blue.shade700),
            _buildStatCard('${stats.overdue}', s.overdue, subtitle: 'Needs attention', color: Colors.red),
            _buildStatCard('${stats.dropped}', s.dropped, color: Colors.grey),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String val, String title, {String? subtitle, required Color color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              val,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSection(BuildContext context, AppStrings s, TeamData teamData) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              s.teamPerformance,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text('${teamData.teamSize} members', style: const TextStyle(fontSize: 10)),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Team Performance List & Login Analytics Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildTeamPerformanceCard(context, s, teamData.teamPerformance)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildLoginAnalyticsCard(context, s, teamData.loginGroups)),
                    ],
                  )
                : Column(
                    children: [
                      _buildTeamPerformanceCard(context, s, teamData.teamPerformance),
                      const SizedBox(height: 16),
                      _buildLoginAnalyticsCard(context, s, teamData.loginGroups),
                    ],
                  );
          },
        ),
      ],
    );
  }

  Widget _buildTeamPerformanceCard(
      BuildContext context, AppStrings s, List<TeamMemberPerformance> members) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.teamPerformance,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (members.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No team data available', style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.take(6).length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final m = members[index];
                  final rate = m.assigned > 0 ? ((m.done / m.assigned) * 100).round() : 0;

                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: _hexToColor(m.avatarColor),
                        child: Text(
                          m.initials,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${m.done} done / ${m.assigned} assigned',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$rate%',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginAnalyticsCard(
      BuildContext context, AppStrings s, List<dynamic> groups) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.teamLoginAnalyticsTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (groups.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No login analytics available', style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final label = group.label ?? '';
                  final colorHex = group.color ?? '#8a93a8';
                  final count = group.members?.length ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 4,
                          backgroundColor: _hexToColor(colorHex),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '$count',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    String cleanHex = hex.replaceAll('#', '');
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }
    return Color(int.parse(cleanHex, radix: 16));
  }
}
