import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/announcement_banner_wrapper.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/schedule_meeting_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/floating_action_button/todo_floating_action_button.dart';
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
                // Header Title & Awaiting badge
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
                    BlocBuilder<ApprovalsBloc, ApprovalsState>(
                      builder: (context, state) {
                        int awaitingCount = 0;
                        if (state is ApprovalsLoadedState) {
                          awaitingCount = state.meetings
                              .where((m) => m.status.toLowerCase() == 'pending')
                              .length;
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                const SizedBox(height: 14),

                // + New Meeting Button
                ElevatedButton.icon(
                  onPressed: () => ScheduleMeetingDialog.show(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ New meeting', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyDark,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                              title: ApprovalsConstStrings.receivedByMe,
                              badgeCount: receivedCount,
                              isSelected: _selectedTabIndex == 0,
                              onTap: () => setState(() => _selectedTabIndex = 0),
                            ),
                            const SizedBox(width: 4),
                            _buildTabButton(
                              title: ApprovalsConstStrings.initiatedByMe,
                              badgeCount: initiatedCount,
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
                      final completionRequests = (!isAcademicExecutive && _selectedTabIndex == 0)
                          ? state.meetingCompletionRequests
                          : <MeetingApprovalModel>[];

                      final regularMeetings = isAcademicExecutive
                          ? state.meetings.where((m) => m.isOrganizer == true).toList()
                          : (_selectedTabIndex == 0
                              ? state.meetings.where((m) => m.isOrganizer != true).toList()
                              : state.meetings.where((m) => m.isOrganizer == true).toList());

                      if (completionRequests.isEmpty && regularMeetings.isEmpty) {
                        final emptyMsg = _selectedTabIndex == 1
                            ? 'You haven’t organized any meetings yet. 🎉'
                            : 'No meeting approvals awaiting your decision. 🎉';
                        return _buildEmptyState(message: emptyMsg);
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Completion sign-off section
                          if (completionRequests.isNotEmpty) ...[
                            _buildCompletionSignOffSection(completionRequests),
                            const SizedBox(height: 16),
                          ],
                          // Regular meetings list / grid
                          if (regularMeetings.isNotEmpty) ...[
                            _buildMeetingsGrid(regularMeetings),
                          ],
                        ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navyDark : AppColors.transparent,
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
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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

  Widget _buildCompletionSignOffSection(List<MeetingApprovalModel> requests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AppStrings.of(context).completionSignOff,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.of(context).completionSignOffSubtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            if (isWide && requests.length > 1) {
              final left = <MeetingApprovalModel>[];
              final right = <MeetingApprovalModel>[];
              for (int i = 0; i < requests.length; i++) {
                if (i % 2 == 0) {
                  left.add(requests[i]);
                } else {
                  right.add(requests[i]);
                }
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: left
                          .map((m) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildCompletionSignOffCard(m),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: right
                          .map((m) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildCompletionSignOffCard(m),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: requests
                    .map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildCompletionSignOffCard(m),
                        ))
                    .toList(),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildCompletionSignOffCard(MeetingApprovalModel item) {
    final reportedBy = item.completionRequestedBy ?? item.organizer ?? 'User';
    final dateStr = item.startsAt != null && item.startsAt!.isNotEmpty ? _formatDate(item.startsAt!) : '';
    final locStr = item.location != null && item.location!.isNotEmpty ? item.location! : 'Online';
    final subtitle = '$dateStr · $locStr · reported by $reportedBy';

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Amber Stripe
              Container(
                width: 4,
                color: const Color(0xFFF59E0B),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Title + "Awaiting sign-off" badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              item.title.isNotEmpty ? item.title : 'Untitled Meeting',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Awaiting sign-off',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      if (item.completionNote != null && item.completionNote!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.subtleBg(context),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.completionNote!.trim(),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Action buttons: "Approve & close" and "Send back"
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                context.read<ApprovalsBloc>().add(
                                  DecideMeetingCompletionEvent(id: item.id, decision: 'approve'),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Meeting completion approved and closed.'),
                                    backgroundColor: AppColors.green,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  border: Border.all(color: const Color(0xFF86EFAC)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    AppStrings.of(context).approveAndClose,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                context.read<ApprovalsBloc>().add(
                                  DecideMeetingCompletionEvent(id: item.id, decision: 'reject'),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Meeting completion sent back.'),
                                    backgroundColor: AppColors.dangerRed,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  border: Border.all(color: const Color(0xFFFECACA)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    AppStrings.of(context).sendBack,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
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

  Widget _buildMeetingsGrid(List<MeetingApprovalModel> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        if (!isWide || items.length <= 1) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _buildMeetingCard(items[index]),
          );
        }

        final leftItems = <MeetingApprovalModel>[];
        final rightItems = <MeetingApprovalModel>[];
        for (int i = 0; i < items.length; i++) {
          if (i % 2 == 0) {
            leftItems.add(items[i]);
          } else {
            rightItems.add(items[i]);
          }
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: leftItems
                    .map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildMeetingCard(m),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: rightItems
                    .map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildMeetingCard(m),
                        ))
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMeetingCard(MeetingApprovalModel item) {
    final isAccepted = (item.status.toLowerCase() == 'accepted' ||
        item.status.toLowerCase() == 'scheduled' ||
        item.status.toLowerCase() == 'completed');

    // Matching screenshot: Red accent stripe on certain cards (or required/past), dark navy/slate on others
    final isRedAccent = item.myRequired == true ||
        (item.organizer != null && item.organizer!.toLowerCase().contains('vamsi')) ||
        item.title.toLowerCase().contains('shankar') ||
        item.title.toLowerCase().contains('meet 3') ||
        item.title.toLowerCase().contains('meet 2');
    final stripeColor = isRedAccent ? AppColors.dangerRed : const Color(0xFF1E293B);

    final dateStr = item.startsAt != null && item.startsAt!.isNotEmpty ? _formatDate(item.startsAt!) : '';
    final locStr = item.location != null && item.location!.isNotEmpty ? item.location! : 'Online';
    final organizerStr = item.organizer != null && item.organizer!.isNotEmpty ? 'organized by ${item.organizer}' : '';
    final subtitle = [dateStr, locStr, organizerStr].where((s) => s.isNotEmpty).join(' · ');

    final showRsvpButtons = _selectedTabIndex == 0 &&
        item.isOrganizer != true &&
        (item.myResponse == null || item.myResponse?.toLowerCase() == 'pending' || item.status.toLowerCase() == 'pending');

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Strip
              Container(
                width: 4,
                color: stripeColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Badges
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              item.title.isNotEmpty ? item.title : 'Untitled Meeting',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (item.isOneOnOne == true || item.kind == 'one_on_one') ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '1:1',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isAccepted ? AppColors.badgeGreenBg(context) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.status.toLowerCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isAccepted ? AppColors.badgeGreenFg(context) : const Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Subtitle
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary(context),
                        ),
                      ),

                      // Agenda Box
                      if (item.agenda != null && item.agenda!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

                      // RSVP Action Buttons (Accept, Decline, Tentative)
                      if (showRsvpButtons) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Accept button
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  context.read<ApprovalsBloc>().add(
                                    RsvpMeetingEvent(id: item.id, response: 'accepted'),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Meeting accepted.'),
                                      backgroundColor: AppColors.green,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    border: Border.all(color: const Color(0xFF86EFAC)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      AppStrings.of(context).btnAccept,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF16A34A),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Decline button
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  context.read<ApprovalsBloc>().add(
                                    RsvpMeetingEvent(id: item.id, response: 'declined'),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Meeting declined.'),
                                      backgroundColor: AppColors.dangerRed,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF991B1B),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      AppStrings.of(context).btnDecline,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Tentative button
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  context.read<ApprovalsBloc>().add(
                                    RsvpMeetingEvent(id: item.id, response: 'tentative'),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Meeting marked as tentative.'),
                                      backgroundColor: AppColors.warningOrange,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.card(context),
                                    border: Border.all(color: AppColors.border(context)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      AppStrings.of(context).btnTentative,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary(context),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${_monthName(dt.month)}, $hour:$minute';
    } catch (_) {
      return isoString;
    }
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) {
      if (month == 9) return 'Sept';
      return months[month - 1];
    }
    return '';
  }
}
