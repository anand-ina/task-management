import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../bloc/meetings_bloc.dart';
import '../bloc/meetings_event.dart';
import '../bloc/meetings_state.dart';
import '../models/meeting_model.dart';

class MyScheduledMeetingsScreen extends StatefulWidget {
  const MyScheduledMeetingsScreen({super.key});

  @override
  State<MyScheduledMeetingsScreen> createState() => _MyScheduledMeetingsScreenState();
}

class _MyScheduledMeetingsScreenState extends State<MyScheduledMeetingsScreen> {
  int _selectedTabIndex = 0; // 0: All, 1: Initiated by Me, 2: Received by Me

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => MeetingsBloc()..add(FetchMyScheduledMeetingsEvent()),
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
          drawer: const CustomLeftDrawer(currentRoute: '/my-meetings'),
          appBar: const CustomAppBar(),
          body: BlocBuilder<MeetingsBloc, MeetingsState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<MeetingsBloc>().add(FetchMyScheduledMeetingsEvent());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.myScheduledMeetings,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  s.meetingsOrganizeOrInvitedSubtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.notifications_active_outlined, size: 14, color: Colors.amber),
                            label: Text(s.previewRemindersButton, style: const TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Segmented Tab Control
                      if (state is MyScheduledMeetingsLoadedState) ...[
                        Builder(
                          builder: (context) {
                            final meetings = state.meetings;
                            final initiated = meetings.where((m) => m.isOrganizer == true).length;
                            final received = meetings.where((m) => m.isOrganizer != true).length;
                            final total = meetings.length;

                            return Container(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildTabPill(
                                    title: '${s.allTab} $total',
                                    isSelected: _selectedTabIndex == 0,
                                    onTap: () => setState(() => _selectedTabIndex = 0),
                                  ),
                                  _buildTabPill(
                                    title: '${s.initiatedByMe} $initiated',
                                    isSelected: _selectedTabIndex == 1,
                                    onTap: () => setState(() => _selectedTabIndex = 1),
                                  ),
                                  _buildTabPill(
                                    title: '${s.receivedByMe} $received',
                                    isSelected: _selectedTabIndex == 2,
                                    onTap: () => setState(() => _selectedTabIndex = 2),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],

                      // State Handling
                      if (state is MeetingsLoadingState)
                        const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
                        )
                      else if (state is MeetingsErrorState)
                        Center(
                          child: Column(
                            children: [
                              Text(state.message, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<MeetingsBloc>().add(FetchMyScheduledMeetingsEvent());
                                },
                                child: Text(s.retryButton),
                              ),
                            ],
                          ),
                        )
                      else if (state is MyScheduledMeetingsLoadedState)
                        _buildMeetingsList(context, s, state.meetings)
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

  Widget _buildTabPill({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0F172A) : const Color(0xFF0F172A))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingsList(BuildContext context, AppStrings s, List<MeetingItemModel> meetings) {
    final filtered = meetings.where((m) {
      if (_selectedTabIndex == 1) return m.isOrganizer == true;
      if (_selectedTabIndex == 2) return m.isOrganizer != true;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text('No meetings found.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return _buildMeetingCard(context, s, filtered[index]);
      },
    );
  }

  Widget _buildMeetingCard(BuildContext context, AppStrings s, MeetingItemModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Blue Strip Accent
              Container(
                width: 4,
                color: const Color(0xFF1E3A8A),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meeting Title
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Time & Location
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatMeetingDate(item.startsAt)} · ${item.location ?? "Online"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Organizer
                      Text(
                        'Organizer: ${item.organizer ?? "Vamsi"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Invitee Chips
                      if (item.invitees.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: item.invitees.map((inv) {
                            final isAccepted = (inv.response ?? '').toLowerCase() == 'accepted';
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isAccepted
                                    ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${inv.name}${isAccepted ? " ✓" : ""}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isAccepted
                                      ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D))
                                      : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 14),

                      // Action Buttons Row
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: Row(
                              children: [
                                const Icon(Icons.videocam_outlined, size: 14, color: Color(0xFF0F172A)),
                                const SizedBox(width: 4),
                                Text(
                                  s.joinMarkAttendedButton,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: () {},
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF16A34A)),
                                const SizedBox(width: 4),
                                Text(
                                  s.meetingHappenedButton,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: () {},
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              s.reminderButton,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMeetingDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${weekdays[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }
}
