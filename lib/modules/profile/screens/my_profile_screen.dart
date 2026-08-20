import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  Color _hexToColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) return const Color(0xFF1F9D57);
    try {
      String cleanHex = hex.replaceAll('#', '').replaceAll('0x', '').trim();
      if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
      return Color(int.parse(cleanHex, radix: 16));
    } catch (_) {
      return const Color(0xFF1F9D57);
    }
  }

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
        create: (_) => ProfileBloc()..add(LoadProfileEvent()),
        child: Scaffold(
          appBar: const CustomAppBar(),
          drawer: const CustomLeftDrawer(currentRoute: '/profile'),
          body: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state is ProfileLoadingState) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ProfileErrorState) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.message, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.read<ProfileBloc>().add(LoadProfileEvent()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              if (state is ProfileLoadedState) {
                final p = state.profile;
                final avatarColor = _hexToColor(p.avatarColor);

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Title
                      Text(
                        s.myProfileTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Top Card (Avatar, Name, Email, Badges)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: avatarColor,
                              child: Text(
                                p.initials.isNotEmpty ? p.initials : 'VA',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.email,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        p.roleLabel,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0F2FE),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        p.employmentType == 'non_teaching' ? 'Non-Teaching' : 'Teaching',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Two Side-by-Side Sections: Personal Info & Performance Stats
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 700;
                          final infoCard = _buildPersonalInfoCard(context, s, p, isDark);
                          final statsCard = _buildPerformanceStatsCard(context, s, p.stats, isDark);

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 5, child: infoCard),
                                const SizedBox(width: 16),
                                Expanded(flex: 5, child: statsCard),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              infoCard,
                              const SizedBox(height: 16),
                              statsCard,
                            ],
                          );
                        },
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

  Widget _buildPersonalInfoCard(BuildContext context, AppStrings s, dynamic p, bool isDark) {
    final rows = [
      {'label': s.fullNameLabel, 'val': p.name},
      {'label': s.emailLabel, 'val': p.email},
      {'label': s.departmentLabel, 'val': p.department},
      {'label': 'Designation', 'val': p.designation},
      {'label': s.branchLabel, 'val': p.branchName},
      {'label': 'Staff Type', 'val': p.employmentType == 'non_teaching' ? 'Non-Teaching' : 'Teaching'},
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
            s.personalInfoSection,
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
                padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildPerformanceStatsCard(BuildContext context, AppStrings s, dynamic stats, bool isDark) {
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
            s.performanceStatsSection,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 12),

          // 2 Rows x 3 Columns Stats Grid
          Row(
            children: [
              Expanded(child: _buildStatBox('${stats.total}', s.totalTasksStat, const Color(0xFFDC2626), isDark)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatBox('${stats.completed}', s.completedStatLabel, const Color(0xFF16A34A), isDark)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatBox('${stats.overdue}', s.overdueStatLabel, const Color(0xFFDC2626), isDark)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildStatBox('${stats.streak} days', s.currentStreakStat, const Color(0xFFD97706), isDark)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatBox('${stats.points}', s.totalPointsStat, const Color(0xFF7C3AED), isDark)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatBox('${stats.onTimeRate}%', s.onTimeRateStat, const Color(0xFF2563EB), isDark)),
            ],
          ),
          const SizedBox(height: 16),

          // Completion Rate Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.completionRateStat,
                style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
              ),
              Text(
                '${stats.completionRate}%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (stats.completionRate as int) / 100.0,
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label, Color valColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
