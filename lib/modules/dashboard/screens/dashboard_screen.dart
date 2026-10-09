import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/dialogs/tasks_due_today_dialog.dart';
import '../../../shared_widgets/floating_action_button/todo_floating_action_button.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../models/dashboard_stats.dart';
import '../models/team_performance.dart';
import '../models/recent_activity_model.dart';
import '../models/login_group_model.dart';
import '../../reports/screens/status_reports_screen.dart';
import '../../approvals/screens/task_approvals_screen.dart';
import '../../tasks/screens/all_tasks_screen.dart';
import '../../performance/screens/team_performance_screen.dart';
import '../../announcements/bloc/announcements_bloc.dart';
import '../../announcements/bloc/announcements_event.dart';
import '../../announcements/bloc/announcements_state.dart';
import '../../announcements/widgets/announcement_ticker_bar.dart';
import '../../../shared_widgets/animations/app_animations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _selectedActivityIndex;
  String _selectedPriorityFilter = 'All';
  final Set<int> _expandedGroupIndices = {3, 4};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      int? mineVal;
      bool hasMultiBranch = false;
      int? assignedBranchId;
      bool isManager = false;
      if (authState is AuthenticatedState) {
        final user = authState.userProfile;
        hasMultiBranch = user.hasMultiBranchAccess;
        assignedBranchId = user.assignedBranchId;
        isManager = user.isManager;
        if (!user.isDirector && !user.isPrincipal) {
          mineVal = 1;
        }
      }
      final dashState = context.read<DashboardBloc>().state;
      int? branchId;
      if (!isManager) {
        if (hasMultiBranch && dashState is DashboardLoadedState && dashState.selectedBranch != null && !dashState.selectedBranch!.isAll) {
          branchId = dashState.selectedBranch!.id;
        } else if (assignedBranchId != null && assignedBranchId > 0 && authState is AuthenticatedState && authState.userProfile.isPrincipal) {
          branchId = assignedBranchId;
        }
      }
      context.read<DashboardBloc>().add(FetchDashboardDataEvent(mine: mineVal, branchId: branchId));
      context.read<AnnouncementsBloc>().add(const FetchAnnouncementsEvent(fetchActiveOnly: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentDateStr = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    final authState = context.watch<AuthBloc>().state;
    String userName = 'User';
    String roleName = '';
    String branchName = 'HEAD OFFICE';

    bool isExecutive = false;
    if (authState is AuthenticatedState) {
      final user = authState.userProfile;
      userName = user.name.isNotEmpty ? user.name : (user.email.split('@').first);
      roleName = user.roleLabel.isNotEmpty ? user.roleLabel.toUpperCase() : user.role.toUpperCase();
      branchName = user.branch?.name ?? 'HEAD OFFICE';

      final role = user.role.toLowerCase();
      final roleLabel = user.roleLabel.toLowerCase();
      if (role.contains('principal') ||
          role.contains('center_head') ||
          role.contains('campus_head') ||
          role.contains('center head') ||
          role.contains('campus head') ||
          roleLabel.contains('principal') ||
          roleLabel.contains('center head') ||
          roleLabel.contains('campus head')) {
        // Center Head / Principal
      }
      if (roleLabel.contains('executive') ||
          role.contains('executive') ||
          role.contains('ae') ||
          roleLabel.contains('ae')) {
        isExecutive = true;
      }
    }

    final dashState = context.watch<DashboardBloc>().state;
    if (dashState is DashboardLoadedState && dashState.selectedBranch != null) {
      branchName = dashState.selectedBranch!.name;
    }


    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await ExitConfirmationDialog.show(context, isDashboard: true);
        if (shouldExit) {
          // Exit handled inside dialog
        }
      },
      child: Scaffold(
        drawer: const CustomLeftDrawer(currentRoute: '/dashboard'),
        appBar: const CustomAppBar(),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoadingState) {
              return _buildDashboardSkeleton(isDark);
            }

            if (state is DashboardErrorState) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final dashState = context.read<DashboardBloc>().state;
                        final auth = context.read<AuthBloc>().state;
                        final user = auth is AuthenticatedState ? auth.userProfile : null;
                        final isManager = user?.isManager ?? false;
                        final hasMulti = user?.hasMultiBranchAccess ?? false;
                        final assignedBranchId = user?.assignedBranchId;
                        int? bId;
                        if (!isManager) {
                          if (hasMulti && dashState is DashboardLoadedState && dashState.selectedBranch != null && !dashState.selectedBranch!.isAll) {
                            bId = dashState.selectedBranch!.id;
                          } else if (user?.isPrincipal == true && assignedBranchId != null && assignedBranchId > 0) {
                            bId = assignedBranchId;
                          }
                        }
                        final mineVal = (user?.isDirector == true || user?.isPrincipal == true) ? null : 1;
                        context.read<DashboardBloc>().add(FetchDashboardDataEvent(mine: mineVal, branchId: bId));
                      },
                      child: Text(s.retryButton),
                    ),
                  ],
                ),
              );
            }

            if (state is DashboardLoadedState) {
              final stats = state.dashboardData.stats;
              final actionCenter = state.dashboardData.actionCenter;
              final overdueByAge = state.dashboardData.overdueByAge;
              final myLogin = state.dashboardData.myLogin;
              final teamData = state.teamData;
              final timeline = state.dashboardData.timeline;

              return Column(
                children: [
                  BlocBuilder<AnnouncementsBloc, AnnouncementsState>(
                    builder: (context, aState) {
                      if (aState is AnnouncementsLoadedState && aState.activeAnnouncements.isNotEmpty) {
                        return AnnouncementTickerBar(announcements: aState.activeAnnouncements);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  Expanded(
                    child: RefreshIndicator(
                onRefresh: () async {
                  final dashState = context.read<DashboardBloc>().state;
                  final auth = context.read<AuthBloc>().state;
                  final user = auth is AuthenticatedState ? auth.userProfile : null;
                  final isManager = user?.isManager ?? false;
                  final hasMulti = user?.hasMultiBranchAccess ?? false;
                  final assignedBranchId = user?.assignedBranchId;
                  int? bId;
                  if (!isManager) {
                    if (hasMulti && dashState is DashboardLoadedState && dashState.selectedBranch != null && !dashState.selectedBranch!.isAll) {
                      bId = dashState.selectedBranch!.id;
                    } else if (user?.isPrincipal == true && assignedBranchId != null && assignedBranchId > 0) {
                      bId = assignedBranchId;
                    }
                  }
                  final mineVal = (user?.isDirector == true || user?.isPrincipal == true) ? null : 1;
                  context.read<DashboardBloc>().add(FetchDashboardDataEvent(mine: mineVal, branchId: bId));
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Banner Card
                      StaggeredSlideFade(
                        delay: Duration.zero,
                        child: _buildHeaderBanner(
                          context,
                          s,
                          userName: userName,
                          roleName: roleName,
                          branchName: branchName,
                          currentDateStr: currentDateStr,
                          stats: stats,
                          actionCenter: actionCenter,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Status Report Due Today Banner (shown when submitted is false, hidden when true)
                      if (timeline.isNotEmpty && !timeline.first.submitted) ...[
                        StaggeredSlideFade(
                          delay: const Duration(milliseconds: 50),
                          child: _buildStatusReportAlertCard(context, timeline.first),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Tasks by Priority Section
                      Text(
                        s.tasksByPriority,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPriorityGrid(context, s, stats, teamData.recentActivity),

                      // Action Center & Scheduled Meetings Row
                      StaggeredSlideFade(
                        delay: const Duration(milliseconds: 120),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 800;
                            return isWide
                                ? Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _buildActionCenterCard(context, s, actionCenter)),
                                      const SizedBox(width: 16),
                                      Expanded(child: _buildScheduledMeetingsCard(context, s, timeline)),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _buildActionCenterCard(context, s, actionCenter),
                                      const SizedBox(height: 16),
                                      _buildScheduledMeetingsCard(context, s, timeline),
                                    ],
                                  );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // My Login Activity & Overdue Tasks by Age Row
                      StaggeredSlideFade(
                        delay: const Duration(milliseconds: 180),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 800;
                            return isWide
                                ? Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _buildLoginActivityCard(context, s, myLogin)),
                                      const SizedBox(width: 16),
                                      Expanded(child: _buildOverdueByAgeCard(context, s, overdueByAge)),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _buildLoginActivityCard(context, s, myLogin),
                                      const SizedBox(height: 16),
                                      _buildOverdueByAgeCard(context, s, overdueByAge),
                                    ],
                                  );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Team Section (Only shown for non-executives)
                      if (!isExecutive) ...[
                        StaggeredSlideFade(
                          delay: const Duration(milliseconds: 240),
                          child: _buildTeamSection(context, s, teamData),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }

            return const SizedBox.shrink();
          },
        ),

        // Floating Action Button
        floatingActionButton: const TodoFloatingActionButton(),
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
    final nowTimeStr = DateFormat('HH:mm:ss').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E40AF),
          ],
        ),
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
          Text(
            '$roleName · $branchName',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

            const Spacer(),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                PulsingBadge(
                  duration: const Duration(milliseconds: 2400),
                  maxScale: 1.25,
                  minScale: 0.85,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF22C55E),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  currentDateStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  nowTimeStr,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
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
            _buildHeaderBadge(
              '✅ ${s.approvalsBadge(actionCenter.approvals)}',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TaskApprovalsScreen()),
              ),
            ),
            _buildHeaderBadge('📋 ${s.toReviewBadge(actionCenter.reviews)}'),
            _buildHeaderBadge(
              '☀️ ${s.toStartBadge(stats.toBeStarted)}',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AllTasksScreen()),
              ),
            ),
            _buildHeaderBadge('⏳ ${s.inProgressBadge(stats.inProgress)}'),
            _buildHeaderBadge(
              '⚑ ${s.overdueBadge(stats.overdue)}',
              isPulsing: stats.overdue > 0,
              accentColor: stats.overdue > 0 ? const Color(0xFFFCA5A5) : null,
              onTap: () => TasksDueTodayDialog.show(
                context,
                scope: 'all',
                customTitle: 'Overdue Tasks',
                overdue: true,
                badgeColor: Colors.red,
              ),
            ),
            _buildHeaderBadge('🎯 ${s.completionBadge(stats.completionRate)}'),
          ],
        ),
      ],
    ),
  );
}

Widget _buildHeaderBadge(String label, {VoidCallback? onTap, bool isPulsing = false, Color? accentColor}) {
  final badge = Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: accentColor != null ? accentColor.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: accentColor != null ? accentColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.15)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: accentColor ?? Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget result = badge;
  if (isPulsing) {
    result = PulsingBadge(
      duration: const Duration(milliseconds: 2400),
      maxScale: 1.08,
      minScale: 0.96,
      child: result,
    );
  }

  if (onTap != null) {
    return ScaleTap(
      onTap: onTap,
      child: result,
    );
  }
  return result;
}

  Widget _buildPriorityGrid(BuildContext context, AppStrings s, DashboardStats stats, List<RecentActivityItem> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final count = constraints.maxWidth > 900 ? 5 : (constraints.maxWidth > 600 ? 3 : 3);
            return GridView.count(
              crossAxisCount: count,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 135,
              children: [
                StaggeredSlideFade(
                  delay: Duration.zero,
                  child: _buildCardWithTopBorder(
                    '★★★★★',
                    '${stats.emergency}',
                    s.emergencyPriority,
                    borderColor: Colors.red,
                    isSelected: _selectedPriorityFilter == s.emergencyPriority,
                    onTap: () {
                      setState(() {
                        _selectedPriorityFilter = (_selectedPriorityFilter == s.emergencyPriority) ? 'All' : s.emergencyPriority;
                      });
                      TasksDueTodayDialog.show(
                        context,
                        scope: 'all',
                        activeOnly: true,
                        customTitle: '${s.emergencyPriority} tasks',
                        priority: 'emergency',
                        badgeColor: Colors.red,
                      );
                    },
                  ),
                ),
                StaggeredSlideFade(
                  delay: const Duration(milliseconds: 40),
                  child: _buildCardWithTopBorder(
                    '★★★★',
                    '${stats.topMost}',
                    s.topMostPriority,
                    borderColor: Colors.orange,
                    isSelected: _selectedPriorityFilter == s.topMostPriority,
                    onTap: () {
                      setState(() {
                        _selectedPriorityFilter = (_selectedPriorityFilter == s.topMostPriority) ? 'All' : s.topMostPriority;
                      });
                      TasksDueTodayDialog.show(
                        context,
                        scope: 'all',
                        activeOnly: true,
                        customTitle: '${s.topMostPriority} tasks',
                        priority: 'top_most',
                        badgeColor: Colors.orange,
                      );
                    },
                  ),
                ),
                StaggeredSlideFade(
                  delay: const Duration(milliseconds: 80),
                  child: _buildCardWithTopBorder(
                    '★★★',
                    '${stats.high}',
                    s.highPriority,
                    borderColor: Colors.amber.shade700,
                    isSelected: _selectedPriorityFilter == s.highPriority,
                    onTap: () {
                      setState(() {
                        _selectedPriorityFilter = (_selectedPriorityFilter == s.highPriority) ? 'All' : s.highPriority;
                      });
                      TasksDueTodayDialog.show(
                        context,
                        scope: 'all',
                        activeOnly: true,
                        customTitle: '${s.highPriority} tasks',
                        priority: 'high',
                        badgeColor: Colors.amber.shade700,
                      );
                    },
                  ),
                ),
                StaggeredSlideFade(
                  delay: const Duration(milliseconds: 120),
                  child: _buildCardWithTopBorder(
                    '★★',
                    '${stats.medium}',
                    s.mediumPriority,
                    borderColor: Colors.blue,
                    isSelected: _selectedPriorityFilter == s.mediumPriority,
                    onTap: () {
                      setState(() {
                        _selectedPriorityFilter = (_selectedPriorityFilter == s.mediumPriority) ? 'All' : s.mediumPriority;
                      });
                      TasksDueTodayDialog.show(
                        context,
                        scope: 'all',
                        activeOnly: true,
                        customTitle: '${s.mediumPriority} tasks',
                        priority: 'medium',
                        badgeColor: Colors.blue,
                      );
                    },
                  ),
                ),
                StaggeredSlideFade(
                  delay: const Duration(milliseconds: 160),
                  child: _buildCardWithTopBorder(
                    '★',
                    '${stats.low}',
                    s.lowPriority,
                    borderColor: Colors.grey,
                    isSelected: _selectedPriorityFilter == s.lowPriority,
                    onTap: () {
                      setState(() {
                        _selectedPriorityFilter = (_selectedPriorityFilter == s.lowPriority) ? 'All' : s.lowPriority;
                      });
                      TasksDueTodayDialog.show(
                        context,
                        scope: 'all',
                        activeOnly: true,
                        customTitle: '${s.lowPriority} tasks',
                        priority: 'low',
                        badgeColor: Colors.grey,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),

      ],
    );
  }

  Widget _buildCardWithTopBorder(
    String stars,
    String count,
    String label, {
    required Color borderColor,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final intCount = int.tryParse(count) ?? 0;
    final isEmergency = (borderColor == Colors.red || borderColor == Colors.orange) && intCount > 0;

    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? borderColor
              : (isDark ? const Color(0xFF334155) : Colors.grey.shade300),
          width: isSelected ? 1.6 : 0.8,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : (isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.035),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 3.5,
              child: Container(
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(stars, style: TextStyle(color: borderColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  AnimatedCountText(
                    value: intCount,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: borderColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isEmergency && borderColor == Colors.red) {
      cardContent = PulsingBadge(
        duration: const Duration(milliseconds: 2600),
        maxScale: 1.03,
        minScale: 0.98,
        child: cardContent,
      );
    }

    return ScaleTap(
      onTap: onTap,
      scaleDown: 0.95,
      child: cardContent,
    );
  }

  Widget _buildActionCenterCard(
      BuildContext context, AppStrings s, DashboardActionCenter actionCenter) {
    final maxCount = [
      actionCenter.approvals,
      actionCenter.overdue,
      actionCenter.dueToday,
      actionCenter.emergencyHigh,
    ].reduce((a, b) => a > b ? a : b);

    final approvalsProgress = (maxCount > 0 && actionCenter.approvals > 0)
        ? (actionCenter.approvals / maxCount).clamp(0.0, 1.0)
        : 0.0;
    final overdueProgress = (maxCount > 0 && actionCenter.overdue > 0)
        ? (actionCenter.overdue / maxCount).clamp(0.0, 1.0)
        : 0.0;
    final dueTodayProgress = (maxCount > 0 && actionCenter.dueToday > 0)
        ? (actionCenter.dueToday / maxCount).clamp(0.0, 1.0)
        : 0.0;
    final emergencyHighProgress = (maxCount > 0 && actionCenter.emergencyHigh > 0)
        ? (actionCenter.emergencyHigh / maxCount).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.actionCenterTitle,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                Text(
                  s.clickRowToOpen,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionCenterRow(
              s.approvalsToReview,
              '${actionCenter.approvals}',
              approvalsProgress,
              Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TaskApprovalsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _buildActionCenterRow(
              s.overdueTasks,
              '${actionCenter.overdue}',
              overdueProgress,
              Colors.red,
              onTap: () => TasksDueTodayDialog.show(
                context,
                scope: 'all',
                customTitle: 'Overdue Tasks',
                overdue: true,
                badgeColor: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            _buildActionCenterRow(
              s.dueToday,
              '${actionCenter.dueToday}',
              dueTodayProgress,
              Colors.amber,
              onTap: () => TasksDueTodayDialog.show(
                context,
                scope: 'all',
                customTitle: s.tasksDueTodayTitle,
                period: 'day',
                badgeColor: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            _buildActionCenterRow(
              s.emergencyHighOpen,
              '${actionCenter.emergencyHigh}',
              emergencyHighProgress,
              Colors.red.shade700,
              onTap: () => TasksDueTodayDialog.show(
                context,
                scope: 'all',
                customTitle: 'Emergency + High (open)',
                priority: 'emergency',
                badgeColor: Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCenterRow(String label, String countStr, double progress, Color color, {VoidCallback? onTap}) {
    final intCount = int.tryParse(countStr) ?? 0;
    final isUrgent = (color == Colors.red || color == Colors.red.shade700) && intCount > 0;

    return ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                isUrgent
                    ? PulsingBadge(
                        duration: const Duration(milliseconds: 2400),
                        maxScale: 1.08,
                        minScale: 0.96,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: AnimatedCountText(
                            value: intCount,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                          ),
                        ),
                      )
                    : AnimatedCountText(
                        value: intCount,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                      ),
              ],
            ),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, animatedVal, _) {
                return Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: animatedVal.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.8),
                            color,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
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

  Widget _buildStatusReportAlertCard(BuildContext context, DashboardTimelineItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.blue.shade900 : const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const PulsingBadge(
            duration: Duration(milliseconds: 2400),
            maxScale: 1.2,
            minScale: 0.9,
            child: Text('📝', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                ),
                children: [
                  const TextSpan(
                    text: 'Status report due today: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: '${item.title} · reminder 5:30 PM, deadline 6:00 PM',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          ScaleTap(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatusReportsScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'File now →',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledMeetingsCard(
      BuildContext context, AppStrings s, List<DashboardTimelineItem> timeline) {
    final currentDateStr = DateFormat('Thu d MMM').format(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Container(
        constraints: const BoxConstraints(minHeight: 180),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.myScheduledMeetings.toUpperCase(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                Text(
                  'Today · $currentDateStr',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (timeline.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Text(
                    s.noMeetingsScheduled,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              )
            else
              Column(
                children: timeline.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  String timeStr = '17:30';
                  try {
                    final dt = DateTime.parse(item.at);
                    timeStr = DateFormat('HH:mm').format(dt);
                  } catch (_) {}

                  return StaggeredSlideFade(
                    delay: Duration(milliseconds: 35 * index),
                    child: ScaleTap(
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.location,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.kind == 'report' ? 'Auto' : item.kind,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginActivityCard(
      BuildContext context, AppStrings s, DashboardMyLogin myLogin) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.myLoginActivityTitle,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLoginStatItem('${myLogin.today}', s.loginsToday, Colors.green),
                _buildLoginStatItem(myLogin.activeTodayHoursMinutes, s.activeTodaySpan, Colors.red.shade700),
                _buildLoginStatItem(myLogin.firstToday, s.firstLoginToday, Colors.black87),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLoginStatItem('${myLogin.thisWeek}', s.loginsThisWeek, Colors.green),
                _buildLoginStatItem(myLogin.activeWeekHoursMinutes, s.activeThisWeekSpan, Colors.teal),
                _buildLoginStatItem('${myLogin.activeDaysWeek}/7', s.activeDays, Colors.amber.shade800),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${s.lastLoginLabel}: ${myLogin.lastLogin} · ${s.activeSpanNotice}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginStatItem(String val, String label, Color color) {
    final intVal = int.tryParse(val);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        intVal != null
            ? AnimatedCountText(
                value: intVal,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
              )
            : Text(
                val,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildOverdueByAgeCard(
      BuildContext context, AppStrings s, DashboardOverdueByAge overdueByAge) {
    final maxCount = [
      overdueByAge.d1_3,
      overdueByAge.d4_7,
      overdueByAge.d8_14,
      overdueByAge.d15p,
    ].reduce((a, b) => a > b ? a : b);
    final denom = maxCount > 0 ? maxCount : 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.overdueTasksByAgeTitle,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                Text(
                  s.clickRowToOpen,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              s.overdueTasksByAgeSubtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildAgeRow(
              s.days1To3,
              overdueByAge.d1_3,
              (overdueByAge.d1_3 > 0) ? (overdueByAge.d1_3 / denom).clamp(0.05, 1.0) : 0.0,
              Colors.amber,
              onTap: () => TasksDueTodayDialog.show(
                context,
                scope: 'all',
                overdueAge: '1_3',
                customTitle: '${s.overdueTasks} (${s.days1To3})',
                badgeColor: Colors.amber,
              ),
            ),
            const SizedBox(height: 10),
            _buildAgeRow(
              s.days4To7,
              overdueByAge.d4_7,
              (overdueByAge.d4_7 > 0) ? (overdueByAge.d4_7 / denom).clamp(0.05, 1.0) : 0.0,
              Colors.orange,
              onTap: () => TasksDueTodayDialog.show(
                context,
                scope: 'all',
                overdueAge: '4_7',
                customTitle: '${s.overdueTasks} (${s.days4To7})',
                badgeColor: Colors.orange,
              ),
            ),
            const SizedBox(height: 10),
            _buildAgeRow(
              s.days8To14,
              overdueByAge.d8_14,
              (overdueByAge.d8_14 > 0) ? (overdueByAge.d8_14 / denom).clamp(0.05, 1.0) : 0.0,
              Colors.red.shade400,
              onTap: () => TasksDueTodayDialog.show(
                context,
                scope: 'all',
                overdueAge: '8_14',
                customTitle: '${s.overdueTasks} (${s.days8To14})',
                badgeColor: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 10),
            _buildAgeRow(
              s.days15Plus,
              overdueByAge.d15p,
              (overdueByAge.d15p > 0) ? (overdueByAge.d15p / denom).clamp(0.05, 1.0) : 0.0,
              Colors.red.shade700,
              onTap: () => TasksDueTodayDialog.show(
                context,
                scope: 'all',
                overdueAge: '15p',
                customTitle: '${s.overdueTasks} (${s.days15Plus})',
                badgeColor: Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeRow(String label, int count, double progress, Color color, {VoidCallback? onTap}) {
    final isCritical = color == Colors.red.shade700 && count > 0;

    return ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 82,
              child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, animatedVal, _) {
                  return Container(
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: animatedVal.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withValues(alpha: 0.75),
                              color,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.35),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
            isCritical
                ? PulsingBadge(
                    duration: const Duration(milliseconds: 2400),
                    maxScale: 1.08,
                    minScale: 0.96,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: AnimatedCountText(
                        value: count,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                  )
                : SizedBox(
                    width: 24,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedCountText(
                        value: count,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
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
              s.myTeam,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text('${teamData.teamSize} ${s.membersLabel}', style: const TextStyle(fontSize: 10)),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Recent Activity with inline accordion dropdown details
        _buildRecentActivityList(context, s, teamData.recentActivity),
        const SizedBox(height: 24),

        // Team Performance & Team Login Analytics Row
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

  Widget _buildRecentActivityList(
      BuildContext context, AppStrings s, List<RecentActivityItem> activities) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${s.recentActivityTitle.toUpperCase()} · ${s.teamWide} · ${s.clickRowForDetails}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (activities.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No recent activity', style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final act = activities[index];
                  final isSelected = index == _selectedActivityIndex;

                  return StaggeredSlideFade(
                    delay: Duration(milliseconds: (index.clamp(0, 8)) * 30),
                    child: Column(
                    children: [
                      ScaleTap(
                        scaleDown: 0.98,
                        onTap: () {
                          setState(() {
                            _selectedActivityIndex = isSelected ? null : index;
                          });
                        },
                        child: Container(
                          color: isSelected
                              ? (isDark ? Colors.white12 : Colors.blue.shade50.withValues(alpha: 0.5))
                              : Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: _hexToColor(act.avatarColor),
                                child: Text(
                                  act.initials.isNotEmpty ? act.initials : (act.actor.isNotEmpty ? act.actor[0] : 'U'),
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '${act.actor} ',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(text: act.note),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                act.taskNo,
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                              const SizedBox(width: 6),
                              AnimatedRotation(
                                turns: isSelected ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOutCubic,
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: isSelected ? const Color(0xFF2563EB) : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOutCubic,
                        child: isSelected
                            ? Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${act.taskNo} · ${act.title}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            TasksDueTodayDialog.show(
                                              context,
                                              customTitle: '${act.taskNo} · ${act.title}',
                                              searchQuery: act.taskNo,
                                              badgeColor: Colors.blue,
                                            );
                                          },
                                          icon: const Icon(Icons.open_in_new, size: 11),
                                          label: Text(s.viewTask, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        Chip(
                                          label: Text(act.priority, style: TextStyle(fontSize: 9.5, color: Colors.amber.shade800, fontWeight: FontWeight.bold)),
                                          backgroundColor: Colors.amber.shade50,
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        Chip(
                                          label: Text('${act.status} · ${act.progress}%', style: const TextStyle(fontSize: 9.5, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                                          backgroundColor: Colors.blue.shade50,
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        Chip(
                                          label: Text(act.branchCode.isNotEmpty ? act.branchCode : 'SS00', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                                          backgroundColor: isDark ? Colors.white12 : Colors.grey.shade100,
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ],
                                    ),
                                    if (act.description.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        act.description,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: isDark ? Colors.white70 : Colors.black87,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    const Divider(height: 1),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 18,
                                      runSpacing: 8,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(s.dueLabel, style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
                                            Text(
                                              (act.dueDate == null || act.dueDate!.isEmpty) ? '—' : act.dueDate!,
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(s.completedLabel, style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
                                            Text(
                                              (act.completedDate == null || act.completedDate!.isEmpty) ? act.at : act.completedDate!,
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(s.branchLabel, style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
                                            Text(
                                              act.branchName,
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
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

  Widget _buildTeamPerformanceCard(
      BuildContext context, AppStrings s, List<TeamMemberPerformance> members) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScaleTap(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TeamPerformanceScreen()),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.teamPerformance.toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (members.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No team performance data available', style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.take(6).length,
                separatorBuilder: (context, index) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final m = members[index];
                  final rate = m.assigned > 0 ? ((m.done / m.assigned) * 100).round() : 0;
                  final progress = m.assigned > 0 ? (m.done / m.assigned).clamp(0.0, 1.0) : 0.0;

                  return ScaleTap(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TeamPerformanceScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Row(
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
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '${m.done} done',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal),
                                    ),
                                    Text(
                                      ' / ${m.assigned} assigned',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0.0, end: progress),
                                  duration: const Duration(milliseconds: 750),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, animVal, _) {
                                    return Container(
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: animVal,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                                            ),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AnimatedCountText(
                                value: rate,
                                suffix: '%',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                              Text(
                                '${m.onTime}% on time',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
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

  Widget _buildLoginAnalyticsCard(
      BuildContext context, AppStrings s, List<LoginGroupItem> groups) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${s.teamLoginAnalyticsTitle.toUpperCase()} · ${s.clickGroupForMembers}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (groups.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No login analytics data available', style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final label = group.label;
                  final colorHex = group.color;
                  final count = group.members.length;
                  final isExpanded = _expandedGroupIndices.contains(index);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      children: [
                        ScaleTap(
                          scaleDown: 0.98,
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedGroupIndices.remove(index);
                              } else {
                                _expandedGroupIndices.add(index);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 5,
                                  backgroundColor: _hexToColor(colorHex),
                                ),
                                const SizedBox(width: 10),
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
                                const SizedBox(width: 6),
                                AnimatedRotation(
                                  turns: isExpanded ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOutCubic,
                                  child: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Expanded Member List with Smooth Animation
                        AnimatedSize(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeInOutCubic,
                          child: isExpanded && group.members.isNotEmpty
                              ? Column(
                                  children: [
                                    const Divider(height: 1),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Column(
                                        children: group.members.map((m) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 12,
                                                  backgroundColor: _hexToColor(m.color),
                                                  child: Text(
                                                    m.initials.isNotEmpty
                                                        ? m.initials
                                                        : (m.name.isNotEmpty ? m.name[0] : 'U'),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  m.name,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
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

  Widget _buildDashboardSkeleton(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Skeleton
          AnimatedShimmerBox(
            width: double.infinity,
            height: 140,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: 16),
          // Section Title Skeleton
          AnimatedShimmerBox(
            width: 140,
            height: 20,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          // Priority Grid Skeleton
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 135,
            children: List.generate(
              3,
              (_) => AnimatedShimmerBox(
                width: double.infinity,
                height: 135,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Action Center Skeleton
          AnimatedShimmerBox(
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) {
      return const Color(0xFF3B82F6);
    }
    try {
      String cleanHex = hex.replaceAll('#', '').replaceAll('0x', '').trim();
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      return Color(int.parse(cleanHex, radix: 16));
    } catch (_) {
      return const Color(0xFF3B82F6);
    }
  }
}
