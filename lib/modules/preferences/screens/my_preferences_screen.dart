import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../bloc/preferences_bloc.dart';
import '../bloc/preferences_event.dart';
import '../bloc/preferences_state.dart';

class MyPreferencesScreen extends StatelessWidget {
  const MyPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await ExitConfirmationDialog.show(context);
        if (shouldExit) {
          // Handled inside exit dialog
        }
      },
      child: BlocProvider(
        create: (_) => PreferencesBloc()..add(LoadPreferencesEvent()),
        child: Scaffold(
          appBar: const CustomAppBar(),
          drawer: const CustomLeftDrawer(currentRoute: '/my-preferences'),
          body: BlocBuilder<PreferencesBloc, PreferencesState>(
            builder: (context, state) {
              if (state is PreferencesLoadingState) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is PreferencesErrorState) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.message, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.read<PreferencesBloc>().add(LoadPreferencesEvent()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              if (state is PreferencesLoadedState) {
                final userProfile = state.data.userProfile;
                final pref = state.data.preferences;

                final permissionsList = [
                  'approval.decide', 'branch.switch', 'event.view', 'fine.config', 'fine.issue',
                  'fine.view', 'meeting.view', 'perf.settings', 'perf.view', 'report.create',
                  'report.submit', 'report.unlock', 'report.view', 'scope.campus', 'scope.department',
                  'scope.org', 'scope.team', 'staff.manage', 'staff.view', 'task.acknowledge',
                  'task.complete', 'task.create', 'task.update', 'task.view', 'todo.manage'
                ];

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Title & Subtitle
                      Row(
                        children: [
                          Icon(Icons.settings_outlined, size: 22, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          const SizedBox(width: 8),
                          Text(
                            s.myPreferencesTitle,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.myPreferencesSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Top Row: Profile Card & Permissions Card
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 700;
                          final profileCard = _buildProfileCard(context, s, userProfile, isDark);
                          final permissionsCard = _buildPermissionsCard(context, s, permissionsList, isDark);

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 5, child: profileCard),
                                const SizedBox(width: 16),
                                Expanded(flex: 5, child: permissionsCard),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              profileCard,
                              const SizedBox(height: 16),
                              permissionsCard,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Daily Digest Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Text('☀️', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.dailyDigestHeader,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.dailyDigestSubtitle,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Switch.adaptive(
                              value: pref.dailyDigest,
                              activeTrackColor: Colors.green,
                              onChanged: (val) {
                                context.read<PreferencesBloc>().add(ToggleDailyDigestEvent(val));
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Group 1: Task Operations
                      _buildNotificationGroupTable(
                        context,
                        s,
                        title: s.taskOperationsHeader,
                        subtitle: '6 notification types',
                        types: [
                          'Task Assigned',
                          'Task Overdue',
                          'Task Status Changed',
                          'Task Completed',
                          'Target Date Changed',
                          'Files Attached for Review'
                        ],
                        pref: pref,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),

                      // Group 2: Meetings & Events
                      _buildNotificationGroupTable(
                        context,
                        s,
                        title: s.meetingsEventsHeader,
                        subtitle: '4 notification types',
                        types: [
                          'Meeting Reminder',
                          'Event Reminder',
                          'Reward',
                          'Fine'
                        ],
                        pref: pref,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),

                      // Group 3: Reports
                      _buildNotificationGroupTable(
                        context,
                        s,
                        title: s.prefReportsHeader,
                        subtitle: '4 notification types',
                        types: [
                          'DSR Reminder (5:30 PM)',
                          'WSR Due',
                          'MSR Due',
                          'Escalation Raised'
                        ],
                        pref: pref,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AppStrings s, dynamic profile, bool isDark) {
    final rows = [
      {'label': 'Name', 'val': profile.name.isNotEmpty ? profile.name : 'Vamsi'},
      {'label': 'Email', 'val': profile.email.isNotEmpty ? profile.email : 'vamsi@samskar.edu'},
      {'label': 'Role', 'val': profile.role.isNotEmpty ? profile.role : 'Director'},
      {'label': 'Department', 'val': 'Administration'},
      {'label': 'Branch', 'val': 'Head Office'},
      {'label': 'Task Creator', 'val': 'Yes'},
    ];

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
            s.profileCardHeader,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: rows.map((r) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r['label']!,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
                    ),
                    Text(
                      r['val']!,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
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

  Widget _buildPermissionsCard(BuildContext context, AppStrings s, List<String> permissions, bool isDark) {
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
            s.yourPermissionsHeader,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: permissions.map((p) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationGroupTable(
    BuildContext context,
    AppStrings s, {
    required String title,
    required String subtitle,
    required List<String> types,
    required dynamic pref,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                // Table Header Row
                TableRow(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  ),
                  children: [
                    _buildHeaderCell(s.notificationTypeHeader, isDark),
                    _buildHeaderCell(s.inAppChannel, isDark),
                    _buildHeaderCell(s.emailChannel, isDark),
                    _buildHeaderCell(s.smsChannel, isDark),
                    _buildHeaderCell(s.whatsappChannel, isDark),
                    _buildHeaderCell(s.pushChannel, isDark),
                  ],
                ),
                // Table Rows for each notification type
                ...types.map((type) {
                  final ch = pref.channels[type];
                  final inapp = ch?.inapp ?? true;
                  final email = ch?.email ?? true;
                  final sms = ch?.sms ?? false;
                  final whatsapp = ch?.whatsapp ?? true;
                  final push = ch?.push ?? true;

                  return TableRow(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      _buildSwitchCell(context, type, 'inapp', inapp),
                      _buildSwitchCell(context, type, 'email', email),
                      _buildSwitchCell(context, type, 'sms', sms),
                      _buildSwitchCell(context, type, 'whatsapp', whatsapp),
                      _buildSwitchCell(context, type, 'push', push),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildSwitchCell(BuildContext context, String type, String channel, bool val) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Center(
        child: Switch.adaptive(
          value: val,
          activeTrackColor: Colors.green,
          onChanged: (newVal) {
            context.read<PreferencesBloc>().add(
                  ToggleChannelEvent(notificationType: type, channel: channel, value: newVal),
                );
          },
        ),
      ),
    );
  }
}
