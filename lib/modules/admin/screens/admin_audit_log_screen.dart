import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/announcement_banner_wrapper.dart';
import '../bloc/admin_audit_bloc.dart';
import '../bloc/admin_audit_event.dart';
import '../bloc/admin_audit_state.dart';
import '../models/admin_audit_log_model.dart';

class AdminAuditLogScreen extends StatelessWidget {
  const AdminAuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminAuditBloc()..add(FetchAuditLogsEvent()),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (!didPop) await ExitConfirmationDialog.show(context);
        },
        child: const Scaffold(
          drawer: CustomLeftDrawer(currentRoute: '/admin/audit'),
          appBar: CustomAppBar(),
          body: AnnouncementBannerWrapper(child: _AuditLogBody()),
        ),
      ),
    );
  }
}

class _AuditLogBody extends StatelessWidget {
  const _AuditLogBody();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AdminAuditBloc, AdminAuditState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async => context.read<AdminAuditBloc>().add(FetchAuditLogsEvent()),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Total Count Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      s.auditLog,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    if (state is AdminAuditLoadedState) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.subtleBg(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${state.allLogs.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  s.auditLogSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 16),

                // Filter Dropdown
                if (state is AdminAuditLoadedState) ...[
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.border(context),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: state.selectedFilter,
                        isDense: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppColors.textSecondary(context),
                        ),
                        dropdownColor: AppColors.card(context),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text(s.allActivityFilter, style: const TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'login', child: Text(s.loginAction, style: const TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'logout', child: Text(s.logoutAction, style: const TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'password_change', child: Text(s.passwordChangedAction, style: const TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            context.read<AdminAuditBloc>().add(FilterAuditLogsEvent(val));
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (state is AdminAuditLoadingState)
                  Padding(
                    padding: const EdgeInsets.all(60),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state is AdminAuditErrorState)
                  Center(
                    child: Column(
                      children: [
                        Text(state.message, style: TextStyle(color: AppColors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => context.read<AdminAuditBloc>().add(FetchAuditLogsEvent()),
                          child: Text(s.retryButton),
                        ),
                      ],
                    ),
                  )
                else if (state is AdminAuditLoadedState)
                  _buildLogsCard(context, state.filteredLogs, s, isDark),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogsCard(
    BuildContext context,
    List<AdminAuditLogModel> logs,
    AppStrings s,
    bool isDark,
  ) {
    if (logs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border(context),
          ),
        ),
        child: Center(
          child: Text(
            s.noAuditLogsFound,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: logs.length,
        separatorBuilder: (_, index) => Divider(
          height: 1,
          color: AppColors.border(context),
        ),
        itemBuilder: (context, i) {
          final log = logs[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Action Badge
                _buildActionBadge(context, log.action, s, isDark),
                const SizedBox(width: 14),

                // Actor & Detail
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textPrimary(context),
                      ),
                      children: [
                        TextSpan(
                          text: log.actor,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (log.detail.isNotEmpty) ...[
                          TextSpan(
                            text: ' · ${log.detail}',
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 2),

                // Timestamp
                Text(
                  DateFormat('dd MMM, HH:mm').format(log.at.toLocal()),
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionBadge(BuildContext context, String action, AppStrings s, bool isDark) {
    Color bg;
    Color text;
    String label;
    IconData? icon;

    final lower = action.toLowerCase();
    if (lower.contains('login')) {
      bg = isDark ? AppColors.green900 : AppColors.greenLight;
      text = isDark ? AppColors.green300 : AppColors.green700;
      label = s.loginAction;
      icon = Icons.arrow_forward_rounded;
    } else if (lower.contains('logout')) {
      bg = AppColors.subtleBg(context);
      text = isDark ? AppColors.slate400 : AppColors.slate600;
      label = s.logoutAction;
      icon = Icons.arrow_back_rounded;
    } else if (lower.contains('password')) {
      bg = isDark ? AppColors.amber900 : AppColors.amberLight;
      text = isDark ? AppColors.amber300 : AppColors.amber800;
      label = s.passwordChangedAction;
      icon = Icons.key_rounded;
    } else {
      bg = isDark ? AppColors.blueDark : AppColors.blueLight;
      text = isDark ? AppColors.blueLight : AppColors.blue;
      label = action;
      icon = Icons.circle;
    }

    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: text,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
