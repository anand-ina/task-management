import '../../../shared_widgets/floating_action_button/todo_floating_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/raise_escalation_dialog.dart';
import '../../../shared_widgets/dialogs/task_detail_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/announcement_banner_wrapper.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/approvals_bloc.dart';
import '../bloc/approvals_event.dart';
import '../bloc/approvals_state.dart';
import '../constants/approvals_const_strings.dart';
import '../models/escalation_model.dart';

class EscalationsScreen extends StatefulWidget {
  const EscalationsScreen({super.key});

  @override
  State<EscalationsScreen> createState() => _EscalationsScreenState();
}

class _EscalationsScreenState extends State<EscalationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ApprovalsBloc>().add(FetchEscalationsDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    bool isAcademicExecutive = false;
    bool isTeamLead = false;
    if (authState is AuthenticatedState) {
      final role = authState.userProfile.role.toLowerCase();
      final roleLabel = authState.userProfile.roleLabel.toLowerCase();
      if (role.contains('executive') || role.contains('ae') || roleLabel.contains('executive') || roleLabel.contains('ae')) {
        isAcademicExecutive = true;
      }
      if (roleLabel.contains('team lead') || roleLabel.contains('tl') || role.contains('team_lead') || role.contains('tl')) {
        isTeamLead = true;
      }
    }
    bool isReadOnlyUser = isAcademicExecutive || isTeamLead;

    return Scaffold(
      floatingActionButton: const TodoFloatingActionButton(),
      drawer: const CustomLeftDrawer(currentRoute: '/approvals/escalations'),
      appBar: const CustomAppBar(),
      body: AnnouncementBannerWrapper(
        child: RefreshIndicator(
        onRefresh: () async {
          context.read<ApprovalsBloc>().add(FetchEscalationsDataEvent());
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title & + Raise escalation Button
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
                          int totalCount = 0;
                          if (state is ApprovalsLoadedState) {
                            totalCount = state.escalations.length;
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.subtleBorder(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$totalCount',
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
                        onPressed: () async {
                          final res = await RaiseEscalationDialog.show(context);
                          if (res == true && context.mounted) {
                            context.read<ApprovalsBloc>().add(FetchEscalationsDataEvent());
                          }
                        },
                        label: const Text('+ Raise escalation', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.button(context),
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      )
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
                                  .add(FetchEscalationsDataEvent()),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is ApprovalsLoadedState) {
                    final items = state.escalations;

                    if (items.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildEscalationCard(items[index], isAcademicExecutive, isReadOnlyUser);
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



  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.flag_outlined, size: 48, color: AppColors.textSecondary(context).withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              ApprovalsConstStrings.noEscalations,
              style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEscalationCard(EscalationModel item, bool isAcademicExecutive, bool isReadOnlyUser) {
    final typeLabel = item.type == 'date_change'
        ? AppStrings.of(context).targetDateChange
        : _capitalize(item.type ?? 'Escalation');

    final proposedDateText = item.proposedDate != null && item.proposedDate!.isNotEmpty
        ? ' · new date ${_formatProposedDate(item.proposedDate!)}'
        : '';

    final raisedByText = item.raisedBy != null && item.raisedBy!.isNotEmpty
        ? ' · raised by ${item.raisedBy}'
        : '';

    final createdAtText = item.createdAt != null && item.createdAt!.isNotEmpty
        ? ' · ${_formatDate(item.createdAt!)}'
        : '';

    final subtitleText = '${item.title ?? ""}$raisedByText$createdAtText$proposedDateText'.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: (item.taskId != null && item.taskId! > 0)
          ? () async {
              await TaskDetailDialog.show(
                context,
                taskId: item.taskId!,
                isReadOnly: isReadOnlyUser,
                canCloneTask: true,
                showOnlyCloneAndCancel: true,
              );
              if (mounted) {
                context.read<ApprovalsBloc>().add(FetchEscalationsDataEvent());
              }
            }
          : null,
      child: Container(
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
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Strip (Red accent line as in screenshot)
              Container(
                width: 4,
                color: AppColors.primaryRed,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (item.taskNo != null && item.taskNo!.isNotEmpty) ...[
                            Text(
                              item.taskNo!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (item.priority != null && item.priority!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.badgeYellowBg(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _capitalize(item.priority!),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.badgeYellowFg(context),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.badgeOrangeBg(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.badgeOrangeFg(context),
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (item.taskId != null && item.taskId! > 0)
                            InkWell(
                              onTap: () async {
                                await TaskDetailDialog.show(
                                  context,
                                  taskId: item.taskId!,
                                  isReadOnly: isReadOnlyUser,
                                  canCloneTask: true,
                                  showOnlyCloneAndCancel: true,
                                );
                                if (mounted) {
                                  context.read<ApprovalsBloc>().add(FetchEscalationsDataEvent());
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View →',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.linkBlue(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Subtitle Text
                      if (subtitleText.isNotEmpty)
                        Text(
                          subtitleText.startsWith('·') ? subtitleText.substring(1).trim() : subtitleText,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary(context),
                          ),
                        ),

                      // Reason Box
                      if (item.reason != null && item.reason!.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.subtleBg(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.reason}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ),
                      ],

                      // Action Buttons (Resolve · Approve, Reject)
                      if (!isAcademicExecutive && item.status.toLowerCase() == 'pending') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  context.read<ApprovalsBloc>().add(
                                    DecideEscalationEvent(id: item.id, decision: 'approve'),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Escalation resolved and approved.'),
                                      backgroundColor: AppColors.green,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF86EFAC)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    AppStrings.of(context).resolveApprove,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  context.read<ApprovalsBloc>().add(
                                    DecideEscalationEvent(id: item.id, decision: 'deny'),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Escalation request rejected.'),
                                      backgroundColor: AppColors.red,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFFCA5A5)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    AppStrings.of(context).btnReject,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFB91C1C),
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
    ),
  );
}

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day} ${_monthName(dt.month)}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  String _formatProposedDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day} ${_monthName(dt.month)} ${dt.year.toString().substring(2)}';
    } catch (_) {
      return isoString;
    }
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
