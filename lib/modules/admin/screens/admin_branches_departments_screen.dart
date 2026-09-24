import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/announcement_banner_wrapper.dart';
import '../bloc/admin_access_bloc.dart';
import '../bloc/admin_access_event.dart';
import '../bloc/admin_access_state.dart';
import '../models/admin_branch_model.dart';
import '../models/admin_department_model.dart';

class AdminBranchesDepartmentsScreen extends StatefulWidget {
  const AdminBranchesDepartmentsScreen({super.key});

  @override
  State<AdminBranchesDepartmentsScreen> createState() =>
      _AdminBranchesDepartmentsScreenState();
}

class _AdminBranchesDepartmentsScreenState
    extends State<AdminBranchesDepartmentsScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _newDeptController = TextEditingController();
  int? _editingBranchId;
  int? _editingDeptId;
  final TextEditingController _editCodeController = TextEditingController();
  final TextEditingController _editBranchNameController = TextEditingController();
  final TextEditingController _editDeptNameController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _branchNameController.dispose();
    _newDeptController.dispose();
    _editCodeController.dispose();
    _editBranchNameController.dispose();
    _editDeptNameController.dispose();
    super.dispose();
  }

  void _startEditBranch(AdminBranchModel branch) {
    setState(() {
      _editingBranchId = branch.id;
      _editingDeptId = null;
      _editCodeController.text = branch.code;
      _editBranchNameController.text = branch.name;
    });
  }

  void _cancelEditBranch() => setState(() => _editingBranchId = null);

  void _saveBranch(BuildContext context, int id) {
    final code = _editCodeController.text.trim();
    final name = _editBranchNameController.text.trim();
    if (code.isNotEmpty && name.isNotEmpty) {
      context.read<AdminAccessBloc>().add(UpdateBranchEvent(id: id, code: code, name: name));
    }
    setState(() => _editingBranchId = null);
  }

  void _startEditDept(AdminDepartmentModel dept) {
    setState(() {
      _editingDeptId = dept.id;
      _editingBranchId = null;
      _editDeptNameController.text = dept.name;
    });
  }

  void _cancelEditDept() => setState(() => _editingDeptId = null);

  void _saveDept(BuildContext context, int id) {
    final name = _editDeptNameController.text.trim();
    if (name.isNotEmpty) {
      context.read<AdminAccessBloc>().add(UpdateDepartmentEvent(id: id, name: name));
    }
    setState(() => _editingDeptId = null);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => AdminAccessBloc()..add(FetchAdminAccessEvent()),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          await ExitConfirmationDialog.show(context);
        },
        child: Scaffold(
          drawer: const CustomLeftDrawer(currentRoute: '/admin/access'),
          appBar: const CustomAppBar(),
          body: AnnouncementBannerWrapper(
            child: BlocBuilder<AdminAccessBloc, AdminAccessState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () async =>
                    context.read<AdminAccessBloc>().add(FetchAdminAccessEvent()),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.branchesAndDepartments,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.branchesAndDepartmentsSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (state is AdminAccessLoadingState)
                        const Padding(
                          padding: EdgeInsets.all(60),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (state is AdminAccessErrorState)
                        Center(
                          child: Column(
                            children: [
                              Text(state.message, style: TextStyle(color: AppColors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => context.read<AdminAccessBloc>().add(FetchAdminAccessEvent()),
                                child: Text(s.retryButton),
                              ),
                            ],
                          ),
                        )
                      else if (state is AdminAccessLoadedState)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 900;
                            if (isWide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildBranchesCard(context, s, state)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildDepartmentsCard(context, s, state)),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                _buildBranchesCard(context, s, state),
                                const SizedBox(height: 20),
                                _buildDepartmentsCard(context, s, state),
                              ],
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
          ),
        ),
      ),
    ),
  );
}

  // ─── BRANCHES CARD ──────────────────────────────────────────────────────────

  Widget _buildBranchesCard(BuildContext context, AppStrings s, AdminAccessLoadedState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(s.branchesHeader, '${state.branches.length}', isDark),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.branches.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final branch = state.branches[i];
              final isEditing = _editingBranchId == branch.id;
              final isExpanded = state.expandedBranchId == branch.id;
              return _rowContainer(isDark: isDark, isEditing: isEditing, child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: isEditing
                        ? _branchEditRow(context, s, branch, isDark)
                        : _branchViewRow(context, s, branch, isExpanded, isDark),
                  ),
                  if (isExpanded && !isEditing) _expandedUsers(isDark, isLoading: state.loadingBranchUsers, children: state.branchUsers.map((u) => _userRow(u.name, u.initials, u.avatarColor, '${u.roleLabel} · ${u.department} · ${u.email}', isDark)).toList()),
                ],
              ));
            },
          ),
          const SizedBox(height: 16),
          _addBranchRow(context, s, isDark),
        ],
      ),
    );
  }

  Widget _branchViewRow(BuildContext context, AppStrings s, AdminBranchModel b, bool isExpanded, bool isDark) {
    return Row(children: [
      _codeTag(b.code, isDark),
      const SizedBox(width: 10),
      Expanded(child: Text(b.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)))),
      const SizedBox(width: 8),
      _usersToggle(b.users, isExpanded, isDark, onTap: () => context.read<AdminAccessBloc>().add(ToggleBranchUsersEvent(b.id))),
      const SizedBox(width: 8),
      _editBtn(s.editButton, isDark, onPressed: () => _startEditBranch(b)),
    ]);
  }

  Widget _branchEditRow(BuildContext context, AppStrings s, AdminBranchModel b, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        SizedBox(width: 80, height: 50, child: _editField(_editCodeController, s.codePlaceholder, isDark, autofocus: true)),
        const SizedBox(width: 8),
        Expanded(child: SizedBox(height: 50, child: _editField(_editBranchNameController, s.branchNamePlaceholder, isDark))),
      ]),
      const SizedBox(height: 8),
      _saveCancelRow(s, onCancel: _cancelEditBranch, onSave: () => _saveBranch(context, b.id), isDark: isDark),
    ]);
  }

  Widget _addBranchRow(BuildContext context, AppStrings s, bool isDark) {
    return Row(children: [
      SizedBox(width: 80, height: 50, child: _addField(_codeController, s.codePlaceholder, isDark)),
      const SizedBox(width: 8),
      Expanded(child: SizedBox(height: 50, child: _addField(_branchNameController, s.branchNamePlaceholder, isDark))),
      const SizedBox(width: 8),
      SizedBox(height: 38, child: _addBtn(s.addButton, onPressed: () {
        final code = _codeController.text.trim();
        final name = _branchNameController.text.trim();
        if (code.isNotEmpty && name.isNotEmpty) {
          context.read<AdminAccessBloc>().add(AddBranchEvent(code: code, name: name));
          _codeController.clear();
          _branchNameController.clear();
        }
      })),
    ]);
  }

  // ─── DEPARTMENTS CARD ───────────────────────────────────────────────────────

  Widget _buildDepartmentsCard(BuildContext context, AppStrings s, AdminAccessLoadedState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(s.departmentsHeader, '${state.departments.length}', isDark),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.departments.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final dept = state.departments[i];
              final isEditing = _editingDeptId == dept.id;
              final isExpanded = state.expandedDeptId == dept.id;
              return _rowContainer(isDark: isDark, isEditing: isEditing, child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: isEditing
                        ? _deptEditRow(context, s, dept, isDark)
                        : _deptViewRow(context, s, dept, isExpanded, isDark),
                  ),
                  if (isExpanded && !isEditing) _expandedUsers(isDark, isLoading: state.loadingDeptUsers, children: state.deptUsers.map((u) => _userRow(u.name, u.initials, u.avatarColor, '${u.designation} · ${u.branchCode} · ${u.email}', isDark)).toList()),
                ],
              ));
            },
          ),
          const SizedBox(height: 16),
          _addDeptRow(context, s, isDark),
        ],
      ),
    );
  }

  Widget _deptViewRow(BuildContext context, AppStrings s, AdminDepartmentModel d, bool isExpanded, bool isDark) {
    return Row(children: [
      Expanded(child: Text(d.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)))),
      const SizedBox(width: 8),
      _usersToggle(d.users, isExpanded, isDark, onTap: () => context.read<AdminAccessBloc>().add(ToggleDeptUsersEvent(d.id))),
      const SizedBox(width: 8),
      _editBtn(s.editButton, isDark, onPressed: () => _startEditDept(d)),
    ]);
  }

  Widget _deptEditRow(BuildContext context, AppStrings s, AdminDepartmentModel d, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: 36, child: _editField(_editDeptNameController, d.name, isDark, autofocus: true)),
      const SizedBox(height: 8),
      _saveCancelRow(s, onCancel: _cancelEditDept, onSave: () => _saveDept(context, d.id), isDark: isDark),
    ]);
  }

  Widget _addDeptRow(BuildContext context, AppStrings s, bool isDark) {
    return Row(children: [
      Expanded(child: SizedBox(height: 38, child: _addField(_newDeptController, s.newDepartmentPlaceholder, isDark))),
      const SizedBox(width: 8),
      SizedBox(height: 38, child: _addBtn(s.addButton, onPressed: () {
        final name = _newDeptController.text.trim();
        if (name.isNotEmpty) {
          context.read<AdminAccessBloc>().add(AddDepartmentEvent(name: name));
          _newDeptController.clear();
        }
      })),
    ]);
  }

  // ─── SHARED HELPERS ─────────────────────────────────────────────────────────

  Widget _card({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: child,
    );
  }

  Widget _cardHeader(String title, String count, bool isDark) {
    return Row(children: [
      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: AppColors.subtleBg(context), borderRadius: BorderRadius.circular(10)),
        child: Text(count, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context))),
      ),
    ]);
  }

  Widget _rowContainer({required bool isDark, required bool isEditing, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.subtleBg(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEditing ? (isDark ? AppColors.white : AppColors.black) : AppColors.border(context),
          width: isEditing ? 1.5 : 1.0,
        ),
      ),
      child: child,
    );
  }

  Widget _expandedUsers(bool isDark, {required bool isLoading, required List<Widget> children}) {
    return Column(children: [
      const Divider(height: 1),
      Container(
        padding: const EdgeInsets.all(10),
        color: AppColors.subtleBg(context),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : children.isEmpty
                ? Padding(padding: const EdgeInsets.all(8), child: Text('No linked users found.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)))
                : Column(children: children),
      ),
    ]);
  }

  Widget _userRow(String name, String initials, String? avatarColor, String subtitle, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        CircleAvatar(radius: 14, backgroundColor: _hexToColor(avatarColor), child: Text(initials, style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 10))),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
          Text(subtitle, style: TextStyle(fontSize: 10, color: AppColors.textSecondary(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  Widget _codeTag(String code, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: AppColors.subtleBg(context), borderRadius: BorderRadius.circular(4)),
      child: Text(code, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary(context))),
    );
  }

  Widget _usersToggle(int users, bool isExpanded, bool isDark, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.subtleBg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(isExpanded ? Icons.arrow_drop_down : Icons.arrow_right, size: 14, color: AppColors.grey600),
          Text('${users}u', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary(context))),
        ]),
      ),
    );
  }

  Widget _editBtn(String label, bool isDark, {required VoidCallback onPressed}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: AppColors.border(context)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary(context))),
    );
  }

  Widget _editField(TextEditingController ctrl, String hint, bool isDark, {bool autofocus = false}) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontSize: 12),
      autofocus: autofocus,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        isDense: true,
        filled: true,
        fillColor: AppColors.card(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: AppColors.border(context))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: AppColors.textPrimary(context), width: 1.5)),
      ),
    );
  }

  Widget _addField(TextEditingController ctrl, String hint, bool isDark) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        isDense: true,
        filled: true,
        fillColor: AppColors.card(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
      ),
    );
  }

  Widget _addBtn(String label, {required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.button(context),
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _saveCancelRow(AppStrings s, {required VoidCallback onCancel, required VoidCallback onSave, required bool isDark}) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      TextButton(
        onPressed: onCancel,
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        child: Text(s.cancelEditButton, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ),
      const SizedBox(width: 8),
      ElevatedButton(
        onPressed: onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.button(context),
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(s.saveButton, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    ]);
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) return AppColors.primaryNavy;
    try {
      String h = hex.replaceAll('#', '').replaceAll('0x', '').trim();
      if (h.length == 6) h = 'FF$h';
      return Color(int.parse(h, radix: 16));
    } catch (_) {
      return AppColors.primaryNavy;
    }
  }
}
