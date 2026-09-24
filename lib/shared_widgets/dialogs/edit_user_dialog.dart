import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../modules/staff/bloc/staff_bloc.dart';
import '../../../modules/staff/bloc/staff_event.dart';
import '../../../modules/staff/models/department_model.dart';
import '../../../modules/staff/models/role_model.dart';
import '../../../modules/staff/models/staff_model.dart';

class EditUserDialog extends StatefulWidget {
  final StaffModel user;
  final List<DepartmentModel> departments;
  final List<RoleModel> roles;
  final List<Map<String, dynamic>> branches;

  const EditUserDialog({
    super.key,
    required this.user,
    required this.departments,
    required this.roles,
    required this.branches,
  });

  static Future<void> show(
    BuildContext context, {
    required StaffModel user,
    required List<DepartmentModel> departments,
    required List<RoleModel> roles,
    required List<Map<String, dynamic>> branches,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => EditUserDialog(
        user: user,
        departments: departments,
        roles: roles,
        branches: branches,
      ),
    );
  }

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _usernameController;
  late final TextEditingController _countryCodeController;
  late final TextEditingController _mobileController;
  late final TextEditingController _responsibilitiesController;

  late String _staffType;
  int? _selectedDepartmentId;
  int? _selectedRoleId;
  int? _selectedBranchId;
  late bool _isTaskCreator;
  late bool _confidentialAccess;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;

    String fName = u.firstName;
    String lName = u.lastName ?? '';
    if (fName.isEmpty && u.name.isNotEmpty) {
      final parts = u.name.split(' ');
      fName = parts.first;
      if (parts.length > 1) {
        lName = parts.sublist(1).join(' ');
      }
    }

    String uname = '';
    if (u.email.contains('@')) {
      uname = u.email.split('@').first;
    } else {
      uname = u.name.toLowerCase().replaceAll(' ', '');
    }

    _firstNameController = TextEditingController(text: fName);
    _lastNameController = TextEditingController(text: lName);
    _emailController = TextEditingController(text: u.email);
    _usernameController = TextEditingController(text: uname);
    _countryCodeController = TextEditingController(text: u.countryCode.isNotEmpty ? u.countryCode : '+91');
    _mobileController = TextEditingController(text: u.hasMissingContact ? '' : u.phone);
    _responsibilitiesController = TextEditingController(text: u.responsibilities ?? '');

    _staffType = u.employmentType.toLowerCase().contains('non') ? 'Non-Teaching' : 'Teaching';

    // Match department
    if (u.departmentId != null && widget.departments.any((d) => d.id == u.departmentId)) {
      _selectedDepartmentId = u.departmentId;
    } else {
      final deptMatch = widget.departments.where(
        (d) => d.name.toLowerCase() == u.department.toLowerCase(),
      );
      if (deptMatch.isNotEmpty) {
        _selectedDepartmentId = deptMatch.first.id;
      } else if (widget.departments.isNotEmpty) {
        _selectedDepartmentId = widget.departments.first.id;
      }
    }

    // Match role
    final roleMatch = widget.roles.where(
      (r) => r.label.toLowerCase() == u.roleLabel.toLowerCase() ||
             r.name.toLowerCase() == u.roleName.toLowerCase() ||
             r.name.toLowerCase() == u.roleLabel.toLowerCase(),
    );
    if (roleMatch.isNotEmpty) {
      _selectedRoleId = roleMatch.first.id;
    } else if (widget.roles.isNotEmpty) {
      _selectedRoleId = widget.roles.first.id;
    }

    // Match branch
    final branchMatch = widget.branches.where(
      (b) => (b['code'] != null && b['code'].toString().toLowerCase() == (u.branchCode ?? '').toLowerCase()) ||
             (b['name'] != null && b['name'].toString().toLowerCase() == (u.branchName ?? '').toLowerCase()),
    );
    if (branchMatch.isNotEmpty) {
      _selectedBranchId = branchMatch.first['id'] as int?;
    } else {
      _selectedBranchId = null;
    }

    _isTaskCreator = u.isTaskCreator;
    _confidentialAccess = u.confidentialAccess;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _countryCodeController.dispose();
    _mobileController.dispose();
    _responsibilitiesController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();

    if (firstName.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in required fields (First Name & Email)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Resolve Department Name
    String deptName = widget.user.department;
    if (_selectedDepartmentId != null) {
      final dMatch = widget.departments.where((d) => d.id == _selectedDepartmentId);
      if (dMatch.isNotEmpty) deptName = dMatch.first.name;
    }

    // Resolve Role Label & Name
    String roleLabel = widget.user.roleLabel;
    String roleName = widget.user.roleName;
    if (_selectedRoleId != null) {
      final rMatch = widget.roles.where((r) => r.id == _selectedRoleId);
      if (rMatch.isNotEmpty) {
        roleLabel = rMatch.first.label.isNotEmpty ? rMatch.first.label : rMatch.first.name;
        roleName = rMatch.first.name;
      }
    }

    // Resolve Branch Name & Code
    String? branchName = widget.user.branchName;
    String? branchCode = widget.user.branchCode;
    if (_selectedBranchId != null) {
      final bMatch = widget.branches.where((b) => b['id'] == _selectedBranchId);
      if (bMatch.isNotEmpty) {
        branchName = bMatch.first['name'] as String?;
        branchCode = bMatch.first['code'] as String?;
      }
    } else {
      branchName = null;
      branchCode = null;
    }

    final fullName = lastName.isNotEmpty ? '$firstName $lastName' : firstName;
    final initials = (firstName.isNotEmpty ? firstName[0].toUpperCase() : '') +
        (lastName.isNotEmpty ? lastName[0].toUpperCase() : (firstName.length > 1 ? firstName[1].toUpperCase() : ''));

    final updatedUser = widget.user.copyWith(
      firstName: firstName,
      lastName: lastName,
      name: fullName,
      initials: initials,
      email: email,
      phone: _mobileController.text.trim(),
      countryCode: _countryCodeController.text.trim(),
      employmentType: _staffType == 'Non-Teaching' ? 'non_teaching' : 'teaching',
      department: deptName,
      departmentId: _selectedDepartmentId,
      roleLabel: roleLabel,
      roleName: roleName,
      branchName: branchName,
      branchCode: branchCode,
      responsibilities: _responsibilitiesController.text.trim(),
      isTaskCreator: _isTaskCreator,
      confidentialAccess: _confidentialAccess,
    );

    final payload = {
      'firstName': firstName,
      'lastName': lastName.isEmpty ? null : lastName,
      'email': email,
      'username': _usernameController.text.trim(),
      'phone': _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
      'countryCode': _countryCodeController.text.trim().isEmpty ? '+91' : _countryCodeController.text.trim(),
      'employmentType': _staffType == 'Non-Teaching' ? 'non_teaching' : 'teaching',
      'departmentId': _selectedDepartmentId,
      'responsibilities': _responsibilitiesController.text.trim().isEmpty ? null : _responsibilitiesController.text.trim(),
      'isTaskCreator': _isTaskCreator,
      'confidentialAccess': _confidentialAccess,
      'role': roleName.isEmpty ? null : roleName,
    };

    // Call PATCH API
    try {
      final dio = DioClient().dio;
      await dio.patch(
        '${ApiConstants.staff}/${widget.user.id}',
        data: payload,
      );
    } catch (e) {
      debugPrint('Error updating staff: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update user: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }
    }

    if (!mounted) return;

    // Update state in BLoC
    context.read<StaffBloc>().add(UpdateStaffEvent(updatedUser));
    context.read<StaffBloc>().add(FetchStaffEvent());

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User "${updatedUser.name}" updated successfully'),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  Widget _buildLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : const Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white38 : Colors.grey.shade400,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit User',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Row 1: First Name * & Last Name
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('First Name *'),
                        _buildTextField(controller: _firstNameController),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Last Name'),
                        _buildTextField(controller: _lastNameController),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Row 2: Email * & Username (optional login)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Email *'),
                        _buildTextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Username (optional login)'),
                        _buildTextField(controller: _usernameController),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Row 3: Country code & Mobile
              Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Country code'),
                        _buildTextField(controller: _countryCodeController),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Mobile'),
                        _buildTextField(
                          controller: _mobileController,
                          hintText: '10-digit number',
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Row 4: Staff Type * (full width)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Staff Type *'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _staffType,
                        items: const [
                          DropdownMenuItem(
                            value: 'Non-Teaching',
                            child: Text('Non-Teaching', style: TextStyle(fontSize: 13)),
                          ),
                          DropdownMenuItem(
                            value: 'Teaching',
                            child: Text('Teaching', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                        onChanged: (val) => setState(() => _staffType = val ?? 'Non-Teaching'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Row 5: Department & RBAC Role
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Department'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: _selectedDepartmentId,
                              hint: const Text('—', style: TextStyle(fontSize: 13)),
                              items: widget.departments.map((d) {
                                return DropdownMenuItem<int>(
                                  value: d.id,
                                  child: Text(d.name, style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedDepartmentId = val),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('RBAC Role'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: _selectedRoleId,
                              hint: const Text('—', style: TextStyle(fontSize: 13)),
                              items: widget.roles.map((r) {
                                return DropdownMenuItem<int>(
                                  value: r.id,
                                  child: Text(
                                    r.label.isNotEmpty ? r.label : r.name,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedRoleId = val),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Row 6: Branch (full width)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Branch'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        isExpanded: true,
                        value: _selectedBranchId,
                        hint: const Text('—', style: TextStyle(fontSize: 13)),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('—', style: TextStyle(fontSize: 13)),
                          ),
                          ...widget.branches.map((b) {
                            final bId = b['id'] as int?;
                            final bName = b['name'] as String? ?? 'Branch';
                            return DropdownMenuItem<int?>(
                              value: bId,
                              child: Text(bName, style: const TextStyle(fontSize: 13)),
                            );
                          }),
                        ],
                        onChanged: (val) => setState(() => _selectedBranchId = val),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Row 7: Responsibilities (multiline textarea)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Responsibilities'),
                  _buildTextField(
                    controller: _responsibilitiesController,
                    maxLines: 4,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Row 8: Task Creator & Confidential Task Access
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Task Creator'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<bool>(
                              isExpanded: true,
                              value: _isTaskCreator,
                              items: const [
                                DropdownMenuItem(value: false, child: Text('No', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: true, child: Text('Yes', style: TextStyle(fontSize: 13))),
                              ],
                              onChanged: (val) => setState(() => _isTaskCreator = val ?? false),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Confidential Task Access'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<bool>(
                              isExpanded: true,
                              value: _confidentialAccess,
                              items: const [
                                DropdownMenuItem(value: false, child: Text('No', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: true, child: Text('Yes', style: TextStyle(fontSize: 13))),
                              ],
                              onChanged: (val) => setState(() => _confidentialAccess = val ?? false),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Footer: Cancel & Save Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.button(context),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
