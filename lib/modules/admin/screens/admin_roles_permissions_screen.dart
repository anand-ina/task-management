import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../bloc/admin_roles_bloc.dart';
import '../bloc/admin_roles_event.dart';
import '../bloc/admin_roles_state.dart';
import '../models/admin_role_model.dart';
import '../models/admin_permission_model.dart';

class AdminRolesPermissionsScreen extends StatelessWidget {
  const AdminRolesPermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminRolesBloc()..add(FetchRolesEvent()),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (!didPop) await ExitConfirmationDialog.show(context);
        },
        child: Scaffold(
          drawer: const CustomLeftDrawer(currentRoute: '/admin/roles'),
          appBar: const CustomAppBar(),
          body: const _RolesBody(),
        ),
      ),
    );
  }
}

class _RolesBody extends StatelessWidget {
  const _RolesBody();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AdminRolesBloc, AdminRolesState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async =>
              context.read<AdminRolesBloc>().add(FetchRolesEvent()),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                s.rolesAndPermissions,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              if (state is AdminRolesLoadedState) ...[
                                const SizedBox(width: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    s.rolesCount(state.roles.length),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.rolesAndPermissionsSubtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddRoleDialog(context, s, isDark),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                       label: Text(s.addRoleButton,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (state is AdminRolesLoadingState)
                  const Padding(
                    padding: EdgeInsets.all(60),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF0F172A))),
                  )
                else if (state is AdminRolesErrorState)
                  Center(
                    child: Column(
                      children: [
                        Text(state.message,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => context
                              .read<AdminRolesBloc>()
                              .add(FetchRolesEvent()),
                          child: Text(s.retryButton),
                        ),
                      ],
                    ),
                  )
                else if (state is AdminRolesLoadedState)
                  if (state.roles.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(s.noRolesFound,
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade500)),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.roles.length,
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final role = state.roles[index];
                        final isExpanded =
                            state.expandedRoleId == role.id;
                        final pendingPerms =
                            state.pendingPermissions[role.id] ??
                                Set<String>.from(role.permissions);
                        return _RoleCard(
                          role: role,
                          allPermissions: state.allPermissions,
                          isExpanded: isExpanded,
                          pendingPerms: pendingPerms,
                          isDark: isDark,
                          s: s,
                        );
                      },
                    )
                else
                  const SizedBox.shrink(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddRoleDialog(
      BuildContext context, AppStrings s, bool isDark) {
    final labelCtrl = TextEditingController();
    final keyCtrl = TextEditingController();
    final levelCtrl = TextEditingController(text: '5');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          s.addRoleTitle,
          style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(ctrl: labelCtrl, label: s.roleLabelField, isDark: isDark),
            const SizedBox(height: 12),
            _DialogField(ctrl: keyCtrl, label: s.roleKeyField, isDark: isDark),
            const SizedBox(height: 12),
            _DialogField(ctrl: levelCtrl, label: s.roleLevelField, isDark: isDark, keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancelEditButton),
          ),
          ElevatedButton(
            onPressed: () {
              final label = labelCtrl.text.trim();
              final name = keyCtrl.text.trim();
              final level = int.tryParse(levelCtrl.text.trim()) ?? 5;
              if (label.isNotEmpty && name.isNotEmpty) {
                context.read<AdminRolesBloc>().add(
                      AddRoleEvent(label: label, name: name, level: level),
                    );
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
            ),
            child: Text(s.addButton),
          ),
        ],
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.ctrl,
    required this.label,
    required this.isDark,
    this.keyboardType = TextInputType.text,
  });
  final TextEditingController ctrl;
  final String label;
  final bool isDark;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(
          fontSize: 13, color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.grey.shade600),
        isDense: true,
        filled: true,
        fillColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.allPermissions,
    required this.isExpanded,
    required this.pendingPerms,
    required this.isDark,
    required this.s,
  });

  final AdminRoleModel role;
  final List<AdminPermissionModel> allPermissions;
  final bool isExpanded;
  final Set<String> pendingPerms;
  final bool isDark;
  final AppStrings s;

  Color get _levelColor {
    switch (role.level) {
      case 1: return const Color(0xFF7C3AED);
      case 2: return const Color(0xFF1D4ED8);
      case 3: return const Color(0xFF0891B2);
      case 4: return const Color(0xFF059669);
      case 5: return const Color(0xFF64748B);
      default: return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? const Color(0xFF0F172A)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isExpanded ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          // Role row header
          InkWell(
            onTap: () => context
                .read<AdminRolesBloc>()
                .add(ToggleRoleExpandEvent(role.id)),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Level badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _levelColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _levelColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      'L${role.level}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _levelColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Label · name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          role.name,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Permissions count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${role.permissions.length} ${s.permissionsLabel}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white60 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Users count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${role.users} ${s.usersLabel}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white60 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: isDark ? Colors.white60 : Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),

          // Expanded permissions grid
          if (isExpanded) ...[
            Divider(
                height: 1,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Permissions grid (3 columns)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 3.5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: allPermissions.length,
                    itemBuilder: (context, i) {
                      final perm = allPermissions[i];
                      final checked = pendingPerms.contains(perm.code);
                      return InkWell(
                        onTap: () => context.read<AdminRolesBloc>().add(
                              TogglePermissionEvent(
                                  roleId: role.id, permCode: perm.code),
                            ),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: checked
                                ? const Color(0xFF0F172A).withOpacity(0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: checked
                                  ? const Color(0xFF0F172A).withOpacity(0.4)
                                  : (isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                checked
                                    ? Icons.check_box_rounded
                                    : Icons.check_box_outline_blank_rounded,
                                size: 14,
                                color: checked
                                    ? const Color(0xFF0F172A)
                                    : (isDark
                                        ? Colors.white38
                                        : Colors.grey.shade400),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  perm.code,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: checked
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF334155),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Save / Cancel buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => context
                            .read<AdminRolesBloc>()
                            .add(ToggleRoleExpandEvent(role.id)),
                        child: Text(s.cancelEditButton,
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          context.read<AdminRolesBloc>().add(
                                SaveRolePermissionsEvent(
                                  roleId: role.id,
                                  permissions: pendingPerms.toList(),
                                ),
                              );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        child: Text(s.savePermissionsButton,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
