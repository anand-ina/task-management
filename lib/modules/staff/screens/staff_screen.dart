import '../../../shared_widgets/floating_action_button/todo_floating_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/announcement_banner_wrapper.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/add_staff_dialog.dart';
import '../../../shared_widgets/dialogs/edit_user_dialog.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared_widgets/dialogs/temporary_password_dialog.dart';
import '../../../shared_widgets/dialogs/remove_staff_dialog.dart';
import '../bloc/staff_bloc.dart';
import '../bloc/staff_event.dart';
import '../bloc/staff_state.dart';
import '../models/staff_model.dart';
import '../repository/staff_repository.dart';
import '../../../shared_widgets/dropdowns/searchable_filter_dropdown.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedDepartmentIdFilter;
  String? _selectedStaffTypeFilter;
  int? _selectedRoleFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => StaffBloc()..add(FetchStaffEvent()),
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
          floatingActionButton: const TodoFloatingActionButton(),
          drawer: const CustomLeftDrawer(currentRoute: '/staff'),
          appBar: const CustomAppBar(),
          body: AnnouncementBannerWrapper(
            child: BlocBuilder<StaffBloc, StaffState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<StaffBloc>().add(FetchStaffEvent());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Builder(
                        builder: (context) {
                          final missingContactCount = state is StaffLoadedState
                              ? state.data.staffList.where((st) => st.hasMissingContact).length
                              : 0;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        Text(
                                          s.userManagement,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        if (state is StaffLoadedState) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${state.data.staffList.length} users',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                          if (missingContactCount > 0)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0xFF78350F).withOpacity(0.4)
                                                    : const Color(0xFFFEF3C7),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text('⚠️ ', style: TextStyle(fontSize: 11)),
                                                  Text(
                                                    '$missingContactCount missing contact',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: isDark
                                                          ? const Color(0xFFFDE68A)
                                                          : const Color(0xFFD97706),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Create and edit users, set roles, email, phone & branch, and manage passwords.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (state is StaffLoadedState) ...[
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    AddStaffDialog.show(
                                      context,
                                      departments: state.data.departments,
                                      roles: state.data.roles,
                                      branches: state.data.branches,
                                    );
                                  },
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text(
                                    '+ Add User',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.button(context),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      if (state is StaffLoadingState)
                        const Padding(
                          padding: EdgeInsets.all(60),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (state is StaffErrorState)
                        Center(
                          child: Column(
                            children: [
                              Text(state.message, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => context.read<StaffBloc>().add(FetchStaffEvent()),
                                child: Text(s.retryButton),
                              ),
                            ],
                          ),
                        )
                      else if (state is StaffLoadedState) ...[
                        // Search & Filters Bar
                        _buildFiltersBar(context, s, state.data),
                        const SizedBox(height: 20),

                        // Staff Cards Grid
                        _buildStaffGrid(context, s, state.data),
                      ] else
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

  Widget _buildFiltersBar(BuildContext context, AppStrings s, StaffOverviewData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final searchBox = SizedBox(
      width: 240,
      height: 38,
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() {}),
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: s.searchStaffPlaceholder,
          hintStyle: const TextStyle(fontSize: 12),
          prefixIcon: const Icon(Icons.search, size: 16),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          isDense: true,
          filled: true,
          fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        searchBox,
        SearchableFilterDropdown<int?>(
          value: _selectedDepartmentIdFilter,
          hint: s.departmentLabel,
          searchHint: 'Search department...',
          items: [
            const SearchableDropdownItem<int?>(value: null, label: 'All Departments'),
            ...data.departments.map(
              (d) => SearchableDropdownItem<int?>(value: d.id, label: d.name),
            ),
          ],
          onChanged: (val) => setState(() => _selectedDepartmentIdFilter = val),
        ),
        SearchableFilterDropdown<String?>(
          value: _selectedStaffTypeFilter,
          hint: s.staffTypeHeader,
          searchHint: 'Search staff type...',
          items: [
            const SearchableDropdownItem<String?>(value: null, label: 'All Staff Types'),
            SearchableDropdownItem<String?>(value: 'teaching', label: s.teachingOption),
            SearchableDropdownItem<String?>(value: 'non_teaching', label: s.nonTeachingOption),
          ],
          onChanged: (val) => setState(() => _selectedStaffTypeFilter = val),
        ),
        SearchableFilterDropdown<int?>(
          value: _selectedRoleFilter,
          hint: s.rbacRoleHeader,
          searchHint: 'Search role...',
          items: [
            const SearchableDropdownItem<int?>(value: null, label: 'All Roles'),
            ...data.roles.map(
              (r) => SearchableDropdownItem<int?>(
                value: r.id,
                label: r.label.isNotEmpty ? r.label : r.name,
              ),
            ),
          ],
          onChanged: (val) => setState(() => _selectedRoleFilter = val),
        ),
        if (_searchController.text.isNotEmpty ||
            _selectedDepartmentIdFilter != null ||
            _selectedStaffTypeFilter != null ||
            _selectedRoleFilter != null)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedDepartmentIdFilter = null;
                _selectedStaffTypeFilter = null;
                _selectedRoleFilter = null;
              });
            },
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('Reset', style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildStaffGrid(BuildContext context, AppStrings s, StaffOverviewData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final staffList = data.staffList;

    // Filter staff list
    final query = _searchController.text.trim().toLowerCase();
    final filtered = staffList.where((staff) {
      if (query.isNotEmpty) {
        final matchesName = staff.name.toLowerCase().contains(query);
        final matchesEmail = staff.email.toLowerCase().contains(query);
        if (!matchesName && !matchesEmail) return false;
      }
      if (_selectedDepartmentIdFilter != null && staff.departmentId != _selectedDepartmentIdFilter) {
        return false;
      }
      if (_selectedStaffTypeFilter != null && staff.employmentType != _selectedStaffTypeFilter) {
        return false;
      }
      if (_selectedRoleFilter != null) {
        final selectedRole = data.roles.where((r) => r.id == _selectedRoleFilter).firstOrNull;
        if (selectedRole != null) {
          final matchesName = staff.roleName.toLowerCase() == selectedRole.name.toLowerCase();
          final matchesLabel = staff.roleLabel.toLowerCase() == selectedRole.label.toLowerCase();
          if (!matchesName && !matchesLabel) return false;
        }
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('No staff members found.', style: TextStyle(color: Colors.grey))),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossCount = 1;
        if (width > 1100) {
          crossCount = 4;
        } else if (width > 800) {
          crossCount = 3;
        } else if (width > 550) {
          crossCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 310,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final staff = filtered[index];
            final isCreator = staff.isTaskCreator;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _hexToColor(staff.avatarColor),
                    child: Text(
                      staff.initials,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Name
                  Text(
                    staff.name,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),

                  // Department
                  Text(
                    staff.department,
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 6),

                  // Role Badge e.g. EXECUTOR vs CREATOR
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isCreator
                          ? (isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFEDD5))
                          : (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isCreator ? 'CREATOR' : 'EXECUTOR',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: isCreator
                            ? (isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C))
                            : (isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Designation / Role Label
                  Text(
                    staff.designation ?? staff.roleLabel,
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Status Pills (password pending | no mobile | @username)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (staff.isPasswordPending)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF78350F).withOpacity(0.3) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'password pending',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      if (staff.hasMissingContact)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF7F1D1D).withOpacity(0.3) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'no mobile',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.3) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          staff.handle,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Action Buttons Row (Edit | Reset PW | Remove)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          EditUserDialog.show(
                            context,
                            user: staff,
                            departments: data.departments,
                            roles: data.roles,
                            branches: data.branches,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      OutlinedButton(
                        onPressed: () => _handleResetPassword(context, staff),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Reset PW',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      OutlinedButton(
                        onPressed: () async {
                          final removed = await RemoveStaffDialog.show(
                            context,
                            staff: staff,
                            staffList: data.staffList,
                          );
                          if (removed == true && context.mounted) {
                            context.read<StaffBloc>().add(DeleteStaffEvent(staff.id));
                            context.read<StaffBloc>().add(FetchStaffEvent());
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Staff member "${staff.name}" removed successfully'),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide(color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Remove',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Divider(height: 12),

                  // Stats Footer Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCol('${staff.created}', 'CREATED'),
                      _buildStatCol('${staff.assigned}', 'ASSIGNED'),
                      _buildStatCol('${staff.done}', 'DONE'),
                      _buildStatCol('₹${staff.fines}', 'FINES'),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCol(String val, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Future<void> _handleResetPassword(BuildContext parentContext, StaffModel staff) async {
    final isDark = Theme.of(parentContext).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: parentContext,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Text(
            'Reset password',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          content: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'Generate a new temporary password for '),
                TextSpan(
                  text: staff.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const TextSpan(text: '? Their current password stops working.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.button(context),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text('Reset Password'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    // Show loading dialog
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final dio = DioClient().dio;
      final response = await dio.post(
        '${ApiConstants.staff}/${staff.id}/reset-password',
      );

      if (mounted) {
        Navigator.of(parentContext, rootNavigator: true).pop();
      }

      final data = response.data;
      String? tempPassword;
      if (data is Map<String, dynamic>) {
        tempPassword = data['tempPassword'] as String? ?? data['temp_password'] as String?;
      }

      if (tempPassword != null && tempPassword.isNotEmpty) {
        if (mounted) {
          await TemporaryPasswordDialog.show(
            parentContext,
            name: staff.name,
            tempPassword: tempPassword,
          );
          if (mounted) {
            parentContext.read<StaffBloc>().add(FetchStaffEvent());
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            const SnackBar(
              content: Text('Password reset successfully, but no temporary password returned.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(parentContext, rootNavigator: true).pop();
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(
            content: Text('Failed to reset password: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) return const Color(0xFFD98A04);
    try {
      String cleanHex = hex.replaceAll('#', '').replaceAll('0x', '').trim();
      if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
      return Color(int.parse(cleanHex, radix: 16));
    } catch (_) {
      return const Color(0xFFD98A04);
    }
  }
}
