import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/dropdowns/searchable_filter_dropdown.dart';
import '../../../shared_widgets/floating_action_button/todo_floating_action_button.dart';
import '../bloc/task_id_settings_bloc.dart';
import '../bloc/task_id_settings_event.dart';
import '../bloc/task_id_settings_state.dart';
import '../models/task_id_settings_model.dart';

class TaskIdSettingsScreen extends StatelessWidget {
  const TaskIdSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TaskIdSettingsBloc()..add(const FetchTaskIdSettingsEvent()),
      child: const _TaskIdSettingsView(),
    );
  }
}

class _TaskIdSettingsView extends StatelessWidget {
  const _TaskIdSettingsView();

  Future<void> _handleResetBranch(
    BuildContext context,
    AppStrings s,
    TaskCounterBranch branch,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          s.resetConfirmTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(s.resetConfirmMessage('${branch.code} · ${branch.name}')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancelButton),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF991B1B),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.resetTo0001),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<TaskIdSettingsBloc>().add(
            ResetBranchCounterEvent(
              branchId: branch.branchId,
              branchCode: branch.code,
            ),
          );
    }
  }

  Future<void> _handleResetAll(BuildContext context, AppStrings s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          s.resetAllConfirmTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(s.resetAllConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancelButton),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF991B1B),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.resetEveryBranch),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<TaskIdSettingsBloc>().add(const ResetAllCountersEvent());
    }
  }

  Color _hexToColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF132A50);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await ExitConfirmationDialog.show(context);
      },
      child: Scaffold(
        floatingActionButton: const TodoFloatingActionButton(),
        drawer: const CustomLeftDrawer(currentRoute: '/admin/task-ids'),
        appBar: const CustomAppBar(),
        body: BlocConsumer<TaskIdSettingsBloc, TaskIdSettingsState>(
          listener: (context, state) {
            if (state is TaskIdSettingsLoadedState && state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: const Color(0xFF16A34A),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is TaskIdSettingsLoadingState || state is TaskIdSettingsInitialState) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF0F172A)),
              );
            }

            if (state is TaskIdSettingsErrorState) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context
                            .read<TaskIdSettingsBloc>()
                            .add(const FetchTaskIdSettingsEvent()),
                        child: Text(s.retryButton),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is TaskIdSettingsLoadedState) {
              return RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<TaskIdSettingsBloc>()
                      .add(const FetchTaskIdSettingsEvent());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Screen Title & Subtitle
                      Text(
                        s.taskIdSettings,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.taskIdSettingsSubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Card 1: Counter per Branch
                      _buildCounterSection(context, s, state.counterData, isDark),
                      const SizedBox(height: 24),

                      // Card 2: Complaints Desk — Who Receives Tickets
                      _buildComplaintsDeskSection(
                        context,
                        s,
                        state.ticketSettings,
                        state.assignees,
                        isDark,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildCounterSection(
    BuildContext context,
    AppStrings s,
    TaskCounterResponse counterData,
    bool isDark,
  ) {
    final branches = counterData.branches;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            s.counterPerBranch,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.counterPerBranchSubtitle,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? Colors.white60 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 16),

          // Container List for Branches (clean card/container list, NOT a table)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: branches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final branch = branches[index];
              return _buildBranchCounterContainer(context, s, branch, isDark);
            },
          ),
          const SizedBox(height: 20),

          // Reset Every Branch Button
          ElevatedButton.icon(
            onPressed: () => _handleResetAll(context, s),
            icon: const Icon(Icons.restart_alt_rounded, size: 16),
            label: Text(s.resetEveryBranch),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCounterContainer(
    BuildContext context,
    AppStrings s,
    TaskCounterBranch branch,
    bool isDark,
  ) {
    final lastUsedFormatted = branch.lastNo.toString().padLeft(4, '0');
    final lastResetText =
        branch.resetAt != null ? branch.resetAt!.split('T').first : '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Branch Code & Name + Reset Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  branch.code,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  branch.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _handleResetBranch(context, s, branch),
                icon: const Icon(Icons.restart_alt_rounded, size: 14),
                label: Text(s.resetTo0001),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white70 : const Color(0xFF334155),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Metrics (Last Used, Next Task ID, Last Reset)
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  label: s.lastUsed,
                  value: lastUsedFormatted,
                  isDark: isDark,
                ),
              ),
              Expanded(
                flex: 2,
                child: _buildMetricItem(
                  label: s.nextTaskId,
                  value: branch.next,
                  isDark: isDark,
                  isHighlighted: true,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  label: s.lastReset,
                  value: lastResetText,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required bool isDark,
    bool isHighlighted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
            color: isHighlighted
                ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B))
                : (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildComplaintsDeskSection(
    BuildContext context,
    AppStrings s,
    TicketSettingsResponse ticketSettings,
    List<AssigneeLookupItem> assignees,
    bool isDark,
  ) {
    final ticketBranches = ticketSettings.branches;
    final fallbackOwnerName = ticketSettings.effectiveFallback;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            s.complaintsDeskTitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.complaintsDeskSubtitle,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? Colors.white60 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 16),

          // Container List for Branch Ticket Owners
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ticketBranches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final branch = ticketBranches[index];
              return _buildTicketBranchContainer(
                context,
                s,
                branch,
                assignees,
                isDark,
              );
            },
          ),
          const SizedBox(height: 12),

          // Fallback Row Container
          _buildFallbackOwnerContainer(
            context,
            s,
            ticketSettings.defaultOwnerId,
            fallbackOwnerName,
            assignees,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTicketBranchContainer(
    BuildContext context,
    AppStrings s,
    TicketBranchSetting setting,
    List<AssigneeLookupItem> assignees,
    bool isDark,
  ) {
    final automaticLabel =
        '${s.automaticCurrentlyPrefix} ${setting.effectiveOwner}';

    final dropdownItems = <SearchableDropdownItem<int?>>[
      SearchableDropdownItem<int?>(
        value: null,
        label: automaticLabel,
      ),
      ...assignees.map((a) {
        return SearchableDropdownItem<int?>(
          value: a.id,
          label: a.name,
          subtitle: a.department,
          leading: CircleAvatar(
            radius: 12,
            backgroundColor: _hexToColor(a.avatarColor),
            child: Text(
              a.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 500;

          final branchTitle = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                setting.code,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '·',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  setting.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

          final dropdownWidget = SearchableFilterDropdown<int?>(
            value: setting.defaultOwnerId,
            hint: automaticLabel,
            searchHint: s.searchStaffPlaceholder,
            maxVisibleCount: 4,
            isExpanded: true,
            minPopupWidth: 280,
            items: dropdownItems,
            onChanged: (newOwnerId) {
              context.read<TaskIdSettingsBloc>().add(
                    UpdateBranchTicketOwnerEvent(
                      branchId: setting.branchId,
                      ownerId: newOwnerId,
                    ),
                  );
            },
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                branchTitle,
                const SizedBox(height: 10),
                dropdownWidget,
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(flex: 3, child: branchTitle),
                const SizedBox(width: 14),
                Expanded(flex: 4, child: dropdownWidget),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildFallbackOwnerContainer(
    BuildContext context,
    AppStrings s,
    int? defaultOwnerId,
    String fallbackOwnerName,
    List<AssigneeLookupItem> assignees,
    bool isDark,
  ) {
    final automaticLabel =
        '${s.automaticCurrentlyPrefix} $fallbackOwnerName';

    final dropdownItems = <SearchableDropdownItem<int?>>[
      SearchableDropdownItem<int?>(
        value: null,
        label: automaticLabel,
      ),
      ...assignees.map((a) {
        return SearchableDropdownItem<int?>(
          value: a.id,
          label: a.name,
          subtitle: a.department,
          leading: CircleAvatar(
            radius: 12,
            backgroundColor: _hexToColor(a.avatarColor),
            child: Text(
              a.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 500;

          final titleWidget = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.allBranches,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '· ${s.fallbackLabel}',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
            ],
          );

          final dropdownWidget = SearchableFilterDropdown<int?>(
            value: defaultOwnerId,
            hint: automaticLabel,
            searchHint: s.searchStaffPlaceholder,
            maxVisibleCount: 4,
            isExpanded: true,
            minPopupWidth: 280,
            items: dropdownItems,
            onChanged: (newOwnerId) {
              context.read<TaskIdSettingsBloc>().add(
                    UpdateFallbackTicketOwnerEvent(ownerId: newOwnerId),
                  );
            },
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleWidget,
                const SizedBox(height: 10),
                dropdownWidget,
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(flex: 3, child: titleWidget),
                const SizedBox(width: 14),
                Expanded(flex: 4, child: dropdownWidget),
              ],
            );
          }
        },
      ),
    );
  }
}
