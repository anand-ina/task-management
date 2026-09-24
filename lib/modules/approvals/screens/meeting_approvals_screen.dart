import '../../../shared_widgets/floating_action_button/todo_floating_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/schedule_meeting_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/announcement_banner_wrapper.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/approvals_bloc.dart';
import '../bloc/approvals_event.dart';
import '../bloc/approvals_state.dart';
import '../constants/approvals_const_strings.dart';
import '../models/meeting_approval_model.dart';

class MeetingApprovalsScreen extends StatefulWidget {
  const MeetingApprovalsScreen({super.key});

  @override
  State<MeetingApprovalsScreen> createState() => _MeetingApprovalsScreenState();
}

class _MeetingApprovalsScreenState extends State<MeetingApprovalsScreen> {
  int _selectedTabIndex = 0; // 0: Received by Me, 1: Initiated by Me

  @override
  void initState() {
    super.initState();
    context.read<ApprovalsBloc>().add(FetchMeetingApprovalsDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final authState = context.watch<AuthBloc>().state;
    bool isAcademicExecutive = false;
    if (authState is AuthenticatedState) {
      final role = authState.userProfile.role.toLowerCase();
      final roleLabel = authState.userProfile.roleLabel.toLowerCase();
      if (role.contains('executive') || role.contains('ae') || roleLabel.contains('executive') || roleLabel.contains('ae')) {
        isAcademicExecutive = true;
      }
    }

    return Scaffold(
      floatingActionButton: const TodoFloatingActionButton(),
      drawer: const CustomLeftDrawer(currentRoute: '/approvals/meetings'),
      appBar: const CustomAppBar(),
      body: AnnouncementBannerWrapper(
        child: RefreshIndicator(
        onRefresh: () async {
          context.read<ApprovalsBloc>().add(FetchMeetingApprovalsDataEvent());
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title & + New Meeting Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    ApprovalsConstStrings.approvalsHeader,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      BlocBuilder<ApprovalsBloc, ApprovalsState>(
                        builder: (context, state) {
                          int awaitingCount = 0;
                          if (state is ApprovalsLoadedState) {
                            awaitingCount = state.meetings
                                .where((m) => m.status.toLowerCase() == 'pending')
                                .length;
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.subtleBorder(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$awaitingCount ${ApprovalsConstStrings.awaitingYou}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () => ScheduleMeetingDialog.show(context),
                        label: const Text('+ New Meeting', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.button(context),
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),

                ],
              ),
              const SizedBox(height: 6),
              Text(
                ApprovalsConstStrings.approvalsSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 16),

              // Segmented Pill Tabs (Received by Me & Initiated by Me)
              if (!isAcademicExecutive) ...[
                BlocBuilder<ApprovalsBloc, ApprovalsState>(
                  builder: (context, state) {
                    int receivedCount = 0;
                    int initiatedCount = 0;
                    if (state is ApprovalsLoadedState) {
                      final received = [
                        ...state.meetings.where((m) => m.isOrganizer != true),
                        ...state.meetingCompletionRequests,
                      ];
                      final initiated = state.meetings.where((m) => m.isOrganizer == true).toList();
                      receivedCount = received.length;
                      initiatedCount = initiated.length;
                    }
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.chipBg(context),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTabButton(
                            title: '${ApprovalsConstStrings.receivedByMe} ${receivedCount > 0 ? "($receivedCount)" : ""}'.trim(),
                            isSelected: _selectedTabIndex == 0,
                            onTap: () => setState(() => _selectedTabIndex = 0),
                          ),
                          const SizedBox(width: 4),
                          _buildTabButton(
                            title: '${ApprovalsConstStrings.initiatedByMe} ${initiatedCount > 0 ? "($initiatedCount)" : ""}'.trim(),
                            isSelected: _selectedTabIndex == 1,
                            onTap: () => setState(() => _selectedTabIndex = 1),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Content Body
              BlocBuilder<ApprovalsBloc, ApprovalsState>(
                builder: (context, state) {
                  if (state is ApprovalsLoadingState) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (state is ApprovalsErrorState) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Text(state.message),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => context
                                  .read<ApprovalsBloc>()
                                  .add(FetchMeetingApprovalsDataEvent()),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is ApprovalsLoadedState) {
                    final filtered = isAcademicExecutive
                        ? state.meetings.where((m) => m.isOrganizer == true).toList()
                        : (_selectedTabIndex == 0
                            ? [
                                ...state.meetings.where((m) => m.isOrganizer != true),
                                ...state.meetingCompletionRequests,
                              ]
                            : state.meetings.where((m) => m.isOrganizer == true).toList());

                    if (filtered.isEmpty) {
                      final emptyMsg = _selectedTabIndex == 1
                          ? 'You haven’t organized any meetings yet. 🎉'
                          : 'No meeting approvals awaiting your decision. 🎉';
                      return _buildEmptyState(message: emptyMsg);
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildMeetingCard(filtered[index]);
                      },
                    );
                  }

                  return _buildEmptyState();
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildTabButton({
    required String title,
    int badgeCount = 0,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.navyDark
              : AppColors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.white : AppColors.textSecondary(context),
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.slate700 : AppColors.slate200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.white : AppColors.textPrimary(context),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({String? message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.grey),
            const SizedBox(height: 12),
            Text(
              message ?? ApprovalsConstStrings.noMeetingApprovals,
              style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingCard(MeetingApprovalModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAccepted = (item.status.toLowerCase() == 'accepted' ||
        item.status.toLowerCase() == 'scheduled' ||
        item.status.toLowerCase() == 'completed');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border(context),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.title.isNotEmpty ? item.title : 'Untitled Meeting',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: isAccepted ? AppColors.badgeGreenBg(context) : AppColors.badgeYellowBg(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.status.toLowerCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isAccepted ? AppColors.badgeGreenFg(context) : AppColors.badgeYellowFg(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Date, Location, Organizer Metadata
          Text(
            '${item.startsAt != null && item.startsAt!.isNotEmpty ? _formatDate(item.startsAt!) : ""}${item.location != null && item.location!.isNotEmpty ? " · ${item.location}" : " · In person"}${item.organizer != null && item.organizer!.isNotEmpty ? " · organized by ${item.organizer}" : ""}',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(context),
            ),
          ),

          // Agenda / Note Box
          if (item.agenda != null && item.agenda!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.subtleBg(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.agenda!.trim(),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day} ${_monthName(dt.month)}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
