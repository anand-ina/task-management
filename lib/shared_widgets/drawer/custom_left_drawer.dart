import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/localization/app_strings.dart';
import '../../modules/admin/screens/admin_audit_log_screen.dart';
import '../../modules/admin/screens/admin_branches_departments_screen.dart';
import '../../modules/admin/screens/admin_reporting_structure_screen.dart';
import '../../modules/admin/screens/admin_roles_permissions_screen.dart';
import '../../modules/admin/screens/admin_section_screen.dart';
import '../../modules/approvals/screens/budget_approvals_screen.dart';
import '../../modules/approvals/screens/escalations_screen.dart';
import '../../modules/approvals/screens/meeting_approvals_screen.dart';
import '../../modules/approvals/screens/task_approvals_screen.dart';
import '../../modules/audits/screens/audits_screen.dart';
import '../../modules/auth/bloc/auth_bloc.dart';
import '../../modules/auth/bloc/auth_state.dart';
import '../../modules/complaints/screens/complaints_history_insights_screen.dart';
import '../../modules/complaints/screens/complaints_screen.dart';
import '../../modules/complaints/screens/suggestion_box_entry_screen.dart';
import '../../modules/dashboard/screens/dashboard_screen.dart';
import '../../modules/events/screens/events_calendar_screen.dart';
import '../../modules/events/screens/events_screen.dart';
import '../../modules/faq/screens/faq_screen.dart';
import '../../modules/fines/screens/fines_rewards_screen.dart';
import '../../modules/fines/screens/performance_settings_screen.dart';
import '../../modules/meetings/screens/meeting_calendar_screen.dart';
import '../../modules/meetings/screens/monthly_one_on_one_pending_screen.dart';
import '../../modules/meetings/screens/my_scheduled_meetings_screen.dart';
import '../../modules/organization/screens/admin_org_chart_screen.dart';
import '../../modules/organization/screens/my_reporting_structure_screen.dart';
import '../../modules/organization/screens/organization_overview_screen.dart';
import '../../modules/performance/screens/leaderboard_screen.dart';
import '../../modules/performance/screens/team_performance_screen.dart';
import '../../modules/preferences/screens/my_preferences_screen.dart';
import '../../modules/profile/screens/my_profile_screen.dart';
import '../../modules/reports/screens/reports_dashboard_screen.dart';
import '../../modules/reports/screens/status_reports_screen.dart';
import '../../modules/responsibilities/screens/my_responsibilities_screen.dart';
import '../../modules/staff/screens/staff_screen.dart';
import '../../modules/sutra/screens/sutra_ai_screen.dart';
import '../../modules/tasks/screens/all_tasks_screen.dart';
import '../../modules/tasks/screens/my_tasks_screen.dart';
import '../../modules/tasks/screens/recurring_tasks_screen.dart';
import '../../modules/todos/screens/today_screen.dart';
import '../../modules/todos/screens/todo_history_screen.dart';

class CustomLeftDrawer extends StatelessWidget {
  final String currentRoute;

  const CustomLeftDrawer({super.key, this.currentRoute = '/dashboard'});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final authState = context.watch<AuthBloc>().state;
    bool isAdmin = false;
    bool isDirector = false;
    bool isPrincipal = false;
    bool isAcademicExecutive = false;

    String roleTitle = s.directorRole;
    String roleScope = s.directorBadgeScope;

    if (authState is AuthenticatedState) {
      final user = authState.userProfile;
      final roleLower = user.role.toLowerCase();
      final roleLabelLower = user.roleLabel.toLowerCase();

      if (roleLower.contains('admin') ||
          roleLabelLower.contains('admin') ||
          user.email.contains('admin')) {
        isAdmin = true;
        roleTitle = s.administratorRole;
        roleScope = s.administratorBadgeScope;
      } else if (roleLower.contains('director') ||
          roleLabelLower.contains('director')) {
        isDirector = true;
        roleTitle = s.directorRole;
        roleScope = s.directorBadgeScope;
      } else if (roleLower.contains('principal') ||
          roleLower.contains('center_head') ||
          roleLower.contains('campus_head') ||
          roleLower.contains('center head') ||
          roleLower.contains('campus head') ||
          roleLabelLower.contains('principal') ||
          roleLabelLower.contains('center head') ||
          roleLabelLower.contains('campus head')) {
        isPrincipal = true;
        roleTitle = s.centerHeadPrincipalRole;
        final visibleCount = (user.scope?.visibleUsers != null && user.scope!.visibleUsers!.isNotEmpty)
            ? user.scope!.visibleUsers!.length
            : 5;
        roleScope = s.centerHeadPrincipalScope(visibleCount);
      } else if (roleLower.contains('team_lead') ||
          roleLower.contains('team lead') ||
          roleLower.contains('lead') ||
          roleLabelLower.contains('team lead') ||
          roleLabelLower.contains('team_lead')) {
        roleTitle = s.teamLeadRole;
        roleScope = s.operationalScopeYourOwn;
      } else if (roleLower.contains('academic_executive') ||
          roleLower.contains('academic executive') ||
          roleLower.contains('executive') ||
          roleLower.contains('ae') ||
          roleLabelLower.contains('academic executive') ||
          roleLabelLower.contains('executive')) {
        isAcademicExecutive = true;
        roleTitle = s.academicExecutiveRole;
        roleScope = s.academicExecutiveScope;
      } else if (roleLower.contains('manager') ||
          roleLabelLower.contains('manager')) {
        roleTitle = s.managerRole;
        roleScope = s.operationalScopeYourOwn;
      } else {
        roleTitle = user.roleLabel.isNotEmpty ? user.roleLabel : s.directorRole;
        roleScope = s.operationalScopeYourOwn;
      }
    }

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0D1424) : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Logo Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset(
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                children: [
                  // ADMIN EXCLUSIVE SECTION (When Admin Logged In)
                  if (isAdmin) ...[
                    _buildSectionCard(
                      context,
                      title: s.administrationHeader,
                      children: [
                        _buildNavItem(
                          context,
                          icon: Icons.person_outline_rounded,
                          title: s.userManagement,
                          isSelected: currentRoute == '/staff',
                          onTap: () => _navigate(context, '/staff'),
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.folder_open_outlined,
                          title: s.branchesAndDepartments,
                          isSelected: currentRoute == '/admin/access',
                          onTap: () => _navigate(context, '/admin/access'),
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.alt_route_rounded,
                          title: s.reportingStructure,
                          isSelected: currentRoute == '/admin/reporting',
                          onTap: () => _navigate(context, '/admin/reporting'),
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.shield_outlined,
                          title: s.rolesAndPermissions,
                          isSelected: currentRoute == '/admin/roles',
                          onTap: () => _navigate(context, '/admin/roles'),
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.tag_rounded,
                          title: s.taskIdSettings,
                          isSelected: currentRoute == '/admin/task-ids',
                          onTap: () => _navigate(context, '/admin/task-ids'),
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.receipt_long_outlined,
                          title: s.auditLog,
                          isSelected: currentRoute == '/admin/audit',
                          onTap: () => _navigate(context, '/admin/audit'),
                        ),
                      ],
                    ),
                  ] else ...[
                    // ALL OTHER ROLES (Center Head / Principal, Team Lead, Academic Executive, Manager, Director)

                    // CARD 1: DASHBOARD & OVERVIEW
                    _buildSectionCard(
                      context,
                      children: [
                        _buildNavItem(
                          context,
                          icon: Icons.grid_view_rounded,
                          title: s.dashboard,
                          isSelected: currentRoute == '/dashboard',
                          onTap: () => _navigate(context, '/dashboard'),
                        ),
                        if (isDirector)
                          _buildNavItem(
                            context,
                            icon: Icons.table_chart_outlined,
                            title: s.organizationOverview,
                            isSelected: currentRoute == '/org-overview',
                            onTap: () => _navigate(context, '/org-overview'),
                          ),
                        if (isPrincipal)
                          _buildNavItem(
                            context,
                            icon: Icons.table_chart_outlined,
                            title: s.campusOverview,
                            isSelected: currentRoute == '/campus-overview' || currentRoute == '/org-overview',
                            onTap: () => _navigate(context, '/campus-overview'),
                          ),
                      ],
                    ),

                    // CARD 2: TASKS
                    _buildSectionCard(
                      context,
                      title: s.tasksHeader,
                      children: [
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
                      ],
                    ),

                    // CARD 3: COMPLAINTS & FEEDBACK
                    _buildSectionCard(
                      context,
                      title: s.complaintsAndFeedbackHeader,
                      children: [
                        _buildNavItem(
                          context,
                          icon: Icons.confirmation_number_outlined,
                          title: s.complaintsTracker,
                          isSelected: currentRoute == '/complaints',
                          onTap: () => _navigate(context, '/complaints'),
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.how_to_vote_outlined,
                          title: s.suggestionBoxEntry,
                          isSelected: currentRoute == '/complaints/suggestion-box',
                          onTap: () => _navigate(context, '/complaints/suggestion-box'),
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.view_headline_rounded,
                          title: s.historyAndInsights,
                          isSelected: currentRoute == '/complaints/history',
                          onTap: () => _navigate(context, '/complaints/history'),
                        ),
                      ],
                    ),

                    // CARD 4: REPORTS
                    _buildSectionCard(
                      context,
                      title: s.reportsHeader,
                      children: [
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
                      ],
                    ),

                    // CARD 5: TO-DO
                    _buildSectionCard(
                      context,
                      title: s.todoHeader,
                      children: [
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
                      ],
                    ),

                    // CARD 6: REQUESTS & APPROVALS
                    _buildSectionCard(
                      context,
                      title: s.approvalsHeader,
                      children: [
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
                      ],
                    ),

                    // CARD 7: MEETINGS
                    _buildSectionCard(
                      context,
                      title: s.meetingsHeader,
                      children: [
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
                      ],
                    ),

                    // CARD 8: EVENTS
                    _buildSectionCard(
                      context,
                      title: s.eventsHeader,
                      children: [
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
                      ],
                    ),

                    // CARD 9: PERFORMANCE
                    _buildSectionCard(
                      context,
                      title: s.performanceHeader,
                      children: [
                        _buildNavItem(
                          context,
                          icon: Icons.emoji_events_outlined,
                          title: s.leaderboard,
                          isSelected: currentRoute == '/leaderboard',
                          onTap: () => _navigate(context, '/leaderboard'),
                        ),
                        if (!isAcademicExecutive)
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
                      ],
                    ),

                    // CARD 10: ADMINISTRATION (Director Only)
                    if (isDirector)
                      _buildSectionCard(
                        context,
                        title: s.administrationHeader,
                        children: [
                          _buildNavItem(
                            context,
                            icon: Icons.person_outline_rounded,
                            title: s.userManagement,
                            isSelected: currentRoute == '/staff',
                            onTap: () => _navigate(context, '/staff'),
                          ),
                          _buildNavItem(
                            context,
                            icon: Icons.folder_open_outlined,
                            title: s.branchesAndDepartments,
                            isSelected: currentRoute == '/admin/access',
                            onTap: () => _navigate(context, '/admin/access'),
                          ),
                          _buildNavItem(
                            context,
                            icon: Icons.alt_route_rounded,
                            title: s.reportingStructure,
                            isSelected: currentRoute == '/admin/reporting',
                            onTap: () => _navigate(context, '/admin/reporting'),
                          ),
                          _buildNavItem(
                            context,
                            icon: Icons.shield_outlined,
                            title: s.rolesAndPermissions,
                            isSelected: currentRoute == '/admin/roles',
                            onTap: () => _navigate(context, '/admin/roles'),
                          ),
                          _buildNavItem(
                            context,
                            icon: Icons.tag_rounded,
                            title: s.taskIdSettings,
                            isSelected: currentRoute == '/admin/task-ids',
                            onTap: () => _navigate(context, '/admin/task-ids'),
                          ),
                          _buildNavItem(
                            context,
                            icon: Icons.receipt_long_outlined,
                            title: s.auditLog,
                            isSelected: currentRoute == '/admin/audit',
                            onTap: () => _navigate(context, '/admin/audit'),
                          ),
                        ],
                      ),

                    // CARD 11: ORGANIZATION
                    _buildSectionCard(
                      context,
                      title: s.organizationHeader,
                      children: [
                        _buildNavItem(
                          context,
                          icon: Icons.corporate_fare_rounded,
                          title: s.adminOrgChart,
                          isSelected: currentRoute == '/org-chart',
                          onTap: () => _navigate(context, '/org-chart'),
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.subdirectory_arrow_right_rounded,
                          title: s.myReportingStructure,
                          isSelected: currentRoute == '/my-reporting',
                          onTap: () => _navigate(context, '/my-reporting'),
                        ),
                      ],
                    ),

                    // CARD 12: ROLES & RESPONSIBILITIES
                    _buildSectionCard(
                      context,
                      title: s.rolesAndResponsibilitiesHeader,
                      children: [
                        _buildNavItem(
                          context,
                          icon: Icons.pie_chart_outline_rounded,
                          title: s.myResponsibilities,
                          isSelected: currentRoute == '/responsibilities',
                          onTap: () => _navigate(context, '/responsibilities'),
                        ),
                      ],
                    ),

                    // CARD 13: MY AUDITS
                    _buildSectionCard(
                      context,
                      title: s.myAuditsHeader,
                      children: [
                        _buildNavItem(
                          context,
                          icon: Icons.search_rounded,
                          title: s.asAnInternalAuditor,
                          isSelected: currentRoute == '/audits/auditor',
                          onTap: () => _navigate(context, '/audits/auditor'),
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.assignment_outlined,
                          title: s.asAnAuditee,
                          isSelected: currentRoute == '/audits/auditee',
                          onTap: () => _navigate(context, '/audits/auditee'),
                        ),
                      ],
                    ),

                    // CARD 14: AI & SETTINGS
                    _buildSectionCard(
                      context,
                      title: s.aiAndSettingsHeader,
                      children: [
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
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Role Footer Badge
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
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
                          roleTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          roleScope,
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

  Widget _buildSectionCard(
    BuildContext context, {
    String? title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : const Color(0xFFF1F5F9).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4, bottom: 6),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
          ],
          ...children,
        ],
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
    final activeBg = isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.35) : const Color(0xFFDBEAFE);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF1E3A8A))
                  : (iconColor ?? (isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF1E3A8A))
                      : (isDark ? Colors.white70 : const Color(0xFF334155)),
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
    final s = AppStrings.of(context);

    // Suggestion Box Entry
    if (route == '/complaints/suggestion-box') {
      if (currentRoute == '/complaints/suggestion-box') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const SuggestionBoxEntryScreen()),
      );
      return;
    }

    // Complaints & Feedback Module
    if (route == '/complaints') {
      if (currentRoute == '/complaints') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const ComplaintsScreen()),
      );
      return;
    }

    if (route == '/complaints/history') {
      if (currentRoute == '/complaints/history') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const ComplaintsHistoryInsightsScreen()),
      );
      return;
    }

    if (route == '/preferences') {
      if (currentRoute == '/preferences' || currentRoute == '/my-preferences') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      navigator.push(
        MaterialPageRoute(builder: (context) => const MyPreferencesScreen()),
      );
      return;
    }

    if (route == '/org-overview' || route == '/campus-overview') {
      if (currentRoute == '/org-overview' || currentRoute == '/campus-overview') {
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

    if (route == '/one-on-one-pending' || route == '/one-on-one') {
      if (currentRoute == '/one-on-one-pending' || currentRoute == '/one-on-one') {
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

    if (route == '/my-meetings' || route == '/meetings') {
      if (currentRoute == '/my-meetings' || currentRoute == '/meetings') {
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

    if (route == '/approvals/appreciations') {
      if (currentRoute == '/approvals/appreciations') {
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

    if (route == '/reports') {
      if (currentRoute == '/reports') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const StatusReportsScreen()),
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

    if (route == '/todo') {
      if (currentRoute == '/todo') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const TodayScreen()),
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

    if (route == '/admin/access') {
      if (currentRoute == '/admin/access') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(
          builder: (context) => const AdminBranchesDepartmentsScreen(),
        ),
      );
      return;
    }

    if (route == '/admin/reporting') {
      if (currentRoute == '/admin/reporting') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(
          builder: (context) => const AdminReportingStructureScreen(),
        ),
      );
      return;
    }

    if (route == '/admin/roles') {
      if (currentRoute == '/admin/roles') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(
          builder: (context) => const AdminRolesPermissionsScreen(),
        ),
      );
      return;
    }

    if (route == '/admin/task-ids') {
      if (currentRoute == '/admin/task-ids') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(
          builder: (context) => AdminSectionScreen(
            title: s.taskIdSettings,
            route: '/admin/task-ids',
            icon: Icons.tag_rounded,
          ),
        ),
      );
      return;
    }

    if (route == '/admin/audit') {
      if (currentRoute == '/admin/audit') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(
          builder: (context) => const AdminAuditLogScreen(),
        ),
      );
      return;
    }

    if (route == '/org-chart') {
      if (currentRoute == '/org-chart') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const AdminOrgChartScreen()),
      );
      return;
    }

    if (route == '/my-reporting') {
      if (currentRoute == '/my-reporting') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const MyReportingStructureScreen()),
      );
      return;
    }

    if (route == '/responsibilities') {
      if (currentRoute == '/responsibilities') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const MyResponsibilitiesScreen()),
      );
      return;
    }

    if (route == '/audits/auditor') {
      if (currentRoute == '/audits/auditor') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const AuditsScreen(isAuditee: false)),
      );
      return;
    }

    if (route == '/audits/auditee') {
      if (currentRoute == '/audits/auditee') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const AuditsScreen(isAuditee: true)),
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

    if (route == '/dashboard') {
      if (currentRoute == '/dashboard') {
        if (isDrawerOpen) navigator.pop();
        return;
      }
      if (isDrawerOpen) navigator.pop();
      if (navigator.canPop()) {
        navigator.popUntil((r) => r.isFirst);
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
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
