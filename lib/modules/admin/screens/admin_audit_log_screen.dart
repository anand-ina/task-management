import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
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
          body: _AuditLogBody(),
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
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    if (state is AdminAuditLoadedState) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${state.allLogs.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
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
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),

                // Filter Dropdown
                if (state is AdminAuditLoadedState) ...[
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: state.selectedFilter,
                        isDense: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                  const Padding(
                    padding: EdgeInsets.all(60),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF0F172A)),
                    ),
                  )
                else if (state is AdminAuditErrorState)
                  Center(
                    child: Column(
                      children: [
                        Text(state.message, style: const TextStyle(color: Colors.red)),
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
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Center(
          child: Text(
            s.noAuditLogsFound,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.grey.shade500,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: logs.length,
        separatorBuilder: (_, index) => Divider(
          height: 1,
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        itemBuilder: (context, i) {
          final log = logs[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Action Badge
                _buildActionBadge(log.action, s, isDark),
                const SizedBox(width: 14),

                // Actor & Detail
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
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
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionBadge(String action, AppStrings s, bool isDark) {
    Color bg;
    Color text;
    String label;
    IconData? icon;

    final lower = action.toLowerCase();
    if (lower.contains('login')) {
      bg = isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7);
      text = isDark ? const Color(0xFF34D399) : const Color(0xFF15803D);
      label = s.loginAction;
      icon = Icons.arrow_forward_rounded;
    } else if (lower.contains('logout')) {
      bg = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
      text = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
      label = s.logoutAction;
      icon = Icons.arrow_back_rounded;
    } else if (lower.contains('password')) {
      bg = isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
      text = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
      label = s.passwordChangedAction;
      icon = Icons.key_rounded;
    } else {
      bg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE);
      text = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);
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
