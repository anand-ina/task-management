import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../modules/meetings/screens/monthly_one_on_one_pending_screen.dart';
import '../../modules/meetings/screens/my_scheduled_meetings_screen.dart';
import '../../modules/organization/screens/organization_overview_screen.dart';
import '../../modules/settings/screens/settings_screen.dart';
import '../../modules/tasks/screens/all_tasks_screen.dart';
import '../../modules/tasks/screens/my_tasks_screen.dart';
import '../../modules/tasks/screens/recurring_tasks_screen.dart';
import '../../modules/approvals/screens/task_approvals_screen.dart';
import '../../modules/approvals/screens/escalations_screen.dart';
import '../../modules/approvals/screens/meeting_approvals_screen.dart';
import '../../modules/approvals/screens/budget_approvals_screen.dart';
import '../../modules/meetings/screens/meeting_calendar_screen.dart';
import '../../modules/events/screens/events_screen.dart';
import '../../modules/events/screens/events_calendar_screen.dart';
import '../../modules/reports/screens/reports_dashboard_screen.dart';
import '../../modules/todos/screens/todo_history_screen.dart';
import '../../modules/performance/screens/leaderboard_screen.dart';
import '../../modules/performance/screens/team_performance_screen.dart';
import '../../modules/fines/screens/fines_rewards_screen.dart';
import '../../modules/fines/screens/performance_settings_screen.dart';
import '../../modules/staff/screens/staff_screen.dart';
import '../../modules/sutra/screens/sutra_ai_screen.dart';
import '../../modules/preferences/screens/my_preferences_screen.dart';
import '../../modules/profile/screens/my_profile_screen.dart';
import '../../modules/faq/screens/faq_screen.dart';

class CustomLeftDrawer extends StatelessWidget {
  final String currentRoute;

  const CustomLeftDrawer({super.key, this.currentRoute = '/dashboard'});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0D1424) : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Logo Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/circle-logo.png',
                    width: 32,
                    height: 32,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB91C1C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Samskar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                      Text(
                        'TASK MANAGER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Navigation Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _buildNavItem(
                    context,
                    icon: Icons.grid_view_rounded,
                    title: s.dashboard,
                    isSelected: currentRoute == '/dashboard',
                    onTap: () => _navigate(context, '/dashboard'),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.table_chart_outlined,
                    title: s.organizationOverview,
                    isSelected: currentRoute == '/org-overview',
                    onTap: () => _navigate(context, '/org-overview'),
                  ),
                  const SizedBox(height: 12),

                  // TASKS
                  _buildSectionHeader(context, s.tasksHeader),
                  _buildNavItem(
                    context,
                    icon: Icons.check_circle_outline,
                    title: s.allTasks,
                    isSelected: currentRoute == '/tasks',
                    onTap: () => _navigate(context, '/tasks'),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.check_box_outlined,
                    title: s.myTasks,
                    isSelected: currentRoute == '/my-tasks',
                    onTap: () => _navigate(context, '/my-tasks'),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.autorenew_rounded,
                    title: s.recurringTasks,
                    isSelected: currentRoute == '/recurring',
                    onTap: () => _navigate(context, '/recurring'),
                  ),
                  const SizedBox(height: 12),

                  // APPROVALS
                  _buildSectionHeader(context, s.approvalsHeader),
                  _buildNavItem(
                    context,
                    icon: Icons.check_circle_rounded,
                    title: s.taskApprovals,
                    iconColor: Colors.green,
                    isSelected: currentRoute == '/approvals/tasks',
                    onTap: () => _navigate(context, '/approvals/tasks'),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.outlined_flag_rounded,
                    title: s.escalations,
                    isSelected: currentRoute == '/approvals/escalations',
                    onTap: () => _navigate(context, '/approvals/escalations'),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.calendar_today_rounded,
                    title: s.meetingApprovals,
                    isSelected: currentRoute == '/approvals/meetings',
                    onTap: () => _navigate(context, '/approvals/meetings'),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.currency_rupee_rounded,
                    title: s.budgetApprovals,
                    isSelected: currentRoute == '/approvals/budget',
                    onTap: () => _navigate(context, '/approvals/budget'),
                  ),
                  const SizedBox(height: 12),

                  // MEETINGS
                  _buildSectionHeader(context, s.meetingsHeader),
                  _buildNavItem(
                    context,
                    icon: Icons.person_outline_rounded,
                    title: s.monthlyOneOnOnePending,
                    isSelected: currentRoute == '/one-on-one-pending' || currentRoute == '/one-on-one',
                    onTap: () => _navigate(context, '/one-on-one-pending'),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.access_time_rounded,
                    title: s.myScheduledMeetings,
                    isSelected: currentRoute == '/my-meetings' || currentRoute == '/meetings',
                    onTap: () => _navigate(context, '/my-meetings'),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.calendar_month_outlined,
                    title: s.meetingCalendar,
                    isSelected: currentRoute == '/meetings-calendar',
                    onTap: () => _navigate(context, '/meetings-calendar'),
                  ),
                  const SizedBox(height: 12),

                  // EVENTS
                  _buildSectionHeader(context, s.eventsHeader),
                  _buildNavItem(
                    context,
                    icon: Icons.star_border_rounded,
                    title: s.events,
                    isSelected: currentRoute == '/events',
                    onTap: () => _navigate(context, '/events'),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.calendar_today_outlined,
                    title: s.eventsCalendar,
                    isSelected: currentRoute == '/events-calendar',
                    onTap: () => _navigate(context, '/events-calendar'),
                  ),
                  const SizedBox(height: 12),

                  // REPORTS
                  _buildSectionHeader(context, s.reportsHeader),
                  _buildNavItem(
                    context,
                    icon: Icons.article_outlined,
                    title: s.statusReports,
                    isSelected: currentRoute == '/reports',
                    onTap: () => _navigate(context, '/reports'),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.bar_chart_rounded,
                    title: s.reportsDashboard,
                    isSelected: currentRoute == '/reports-dashboard',
                    onTap: () => _navigate(context, '/reports-dashboard'),
                  ),
                  const SizedBox(height: 12),

                  // TO-DO
                  _buildSectionHeader(context, s.todoHeader),
                  _buildNavItem(
                    context,
                    icon: Icons.pie_chart_outline_rounded,
                    title: s.today,
                    isSelected: currentRoute == '/todo',
                    onTap: () => _navigate(context, '/todo'),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.history_rounded,
                    title: s.history,
                    isSelected: currentRoute == '/todo-history',
                    onTap: () => _navigate(context, '/todo-history'),
                  ),
                  const SizedBox(height: 12),

                  // PERFORMANCE
                  _buildSectionHeader(context, s.performanceHeader),
                  _buildNavItem(
                    context,
                    icon: Icons.emoji_events_outlined,
                    title: s.leaderboard,
                    isSelected: currentRoute == '/leaderboard',
                    onTap: () => _navigate(context, '/leaderboard'),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.people_alt_outlined,
                    title: s.teamPerformance,
                    isSelected: currentRoute == '/team-performance',
                    onTap: () => _navigate(context, '/team-performance'),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.diamond_outlined,
                    title: s.finesAndRewards,
                    isSelected: currentRoute == '/fines-rewards' || currentRoute == '/fines',
                    onTap: () => _navigate(context, '/fines-rewards'),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.settings_outlined,
                    title: s.settings,
                    isSelected: currentRoute == '/performance-settings' || currentRoute == '/perf-settings',
                    onTap: () => _navigate(context, '/performance-settings'),
                  ),
                  const SizedBox(height: 12),

                  // ORGANIZATION
                  _buildSectionHeader(context, s.organizationHeader),
                  _buildNavItem(
                    context,
                    icon: Icons.people_outline_rounded,
                    title: s.staff,
                    isSelected: currentRoute == '/staff',
                    onTap: () => _navigate(context, '/staff'),
                  ),
                  const SizedBox(height: 12),

                  // AI & SETTINGS
                  _buildSectionHeader(context, s.aiAndSettingsHeader),
                  _buildNavItem(
                    context,
                    icon: Icons.auto_awesome_rounded,
                    title: s.sutraAi,
                    iconColor: Colors.amber,
                    isSelected: currentRoute == '/sutra',
                    onTap: () => _navigate(context, '/sutra'),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.tune_rounded,
                    title: s.myPreferences,
                    isSelected: currentRoute == '/my-preferences' || currentRoute == '/preferences',
                    onTap: () => _navigate(context, '/my-preferences'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Director Footer Badge
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.directorRole,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          s.directorBadgeScope,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? const Color(0xFFB91C1C)
                  : (iconColor ?? (isDark ? Colors.white70 : Colors.black87)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFFB91C1C)
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    final navigator = Navigator.of(context);
    final isDrawerOpen = Scaffold.maybeOf(context)?.isDrawerOpen ?? false;

    if (route == '/preferences') {
      if (currentRoute == '/preferences') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      navigator.push(
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      );
      return;
    }

    if (route == '/org-overview') {
      if (currentRoute == '/org-overview') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const OrganizationOverviewScreen()),
      );
      return;
    }

    if (route == '/tasks') {
      if (currentRoute == '/tasks') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const AllTasksScreen()),
      );
      return;
    }

    if (route == '/my-tasks') {
      if (currentRoute == '/my-tasks') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const MyTasksScreen()),
      );
      return;
    }

    if (route == '/recurring') {
      if (currentRoute == '/recurring') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const RecurringTasksScreen()),
      );
      return;
    }

    if (route == '/one-on-one-pending') {
      if (currentRoute == '/one-on-one-pending') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const MonthlyOneOnOnePendingScreen()),
      );
      return;
    }

    if (route == '/my-meetings') {
      if (currentRoute == '/my-meetings') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const MyScheduledMeetingsScreen()),
      );
      return;
    }

    if (route == '/meetings-calendar') {
      if (currentRoute == '/meetings-calendar') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const MeetingCalendarScreen()),
      );
      return;
    }

    if (route == '/approvals/tasks') {
      if (currentRoute == '/approvals/tasks') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const TaskApprovalsScreen()),
      );
      return;
    }

    if (route == '/approvals/escalations') {
      if (currentRoute == '/approvals/escalations') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const EscalationsScreen()),
      );
      return;
    }

    if (route == '/approvals/meetings') {
      if (currentRoute == '/approvals/meetings') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const MeetingApprovalsScreen()),
      );
      return;
    }

    if (route == '/approvals/budget') {
      if (currentRoute == '/approvals/budget') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const BudgetApprovalsScreen()),
      );
      return;
    }

    if (route == '/events') {
      if (currentRoute == '/events') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const EventsScreen()),
      );
      return;
    }

    if (route == '/events-calendar') {
      if (currentRoute == '/events-calendar') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const EventsCalendarScreen()),
      );
      return;
    }

    if (route == '/reports-dashboard') {
      if (currentRoute == '/reports-dashboard') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const ReportsDashboardScreen()),
      );
      return;
    }

    if (route == '/todo-history') {
      if (currentRoute == '/todo-history') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const TodoHistoryScreen()),
      );
      return;
    }

    if (route == '/leaderboard') {
      if (currentRoute == '/leaderboard') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
      );
      return;
    }

    if (route == '/team-performance') {
      if (currentRoute == '/team-performance') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const TeamPerformanceScreen()),
      );
      return;
    }

    if (route == '/fines-rewards' || route == '/fines') {
      if (currentRoute == '/fines-rewards' || currentRoute == '/fines') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const FinesRewardsScreen()),
      );
      return;
    }

    if (route == '/performance-settings' || route == '/perf-settings') {
      if (currentRoute == '/performance-settings' || currentRoute == '/perf-settings') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const PerformanceSettingsScreen()),
      );
      return;
    }

    if (route == '/staff') {
      if (currentRoute == '/staff') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const StaffScreen()),
      );
      return;
    }

    if (route == '/sutra') {
      if (currentRoute == '/sutra') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const SutraAiScreen()),
      );
      return;
    }

    if (route == '/my-preferences' || route == '/preferences') {
      if (currentRoute == '/my-preferences' || currentRoute == '/preferences') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const MyPreferencesScreen()),
      );
      return;
    }

    if (route == '/profile') {
      if (currentRoute == '/profile') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const MyProfileScreen()),
      );
      return;
    }

    if (route == '/faq') {
      if (currentRoute == '/faq') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const FaqScreen()),
      );
      return;
    }

    if (isDrawerOpen) {
      navigator.pop();
    }

    if (navigator.canPop()) {
      navigator.popUntil((r) => r.isFirst);
    }
  }
}
