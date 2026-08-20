import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../modules/staff/models/department_model.dart';
import '../../../modules/staff/models/role_model.dart';

class AddStaffDialog extends StatefulWidget {
  final List<DepartmentModel> departments;
  final List<RoleModel> roles;
  final List<Map<String, dynamic>> branches;

  const AddStaffDialog({
    super.key,
    required this.departments,
    required this.roles,
    required this.branches,
  });

  static Future<void> show(
    BuildContext context, {
    required List<DepartmentModel> departments,
    required List<RoleModel> roles,
    required List<Map<String, dynamic>> branches,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddStaffDialog(
        departments: departments,
        roles: roles,
        branches: branches,
      ),
    );
  }

  @override
  State<AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<AddStaffDialog> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _responsibilitiesController = TextEditingController();

  String _staffType = 'Teaching';
  int? _selectedDepartmentId;
  int? _selectedRoleId;
  int? _selectedBranchId;
  bool _isTaskCreator = true;
  bool _confidentialAccess = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _responsibilitiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('👤 ', style: TextStyle(fontSize: 16)),
                      Text(
                        s.addStaffTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // First Name & Last Name Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${s.firstNameLabel} *', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.lastNameLabel, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Email Field
              Text('${s.emailLabel} *', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),

              // Mobile & Staff Type Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.mobileLabel, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${s.staffTypeHeader} *', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _staffType,
                              items: [
                                DropdownMenuItem(value: 'Teaching', child: Text(s.teachingOption, style: const TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 'Non-Teaching', child: Text(s.nonTeachingOption, style: const TextStyle(fontSize: 13))),
                              ],
                              onChanged: (val) => setState(() => _staffType = val ?? 'Teaching'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Department & RBAC Role Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.departmentLabel, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.rbacRoleHeader, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: _selectedRoleId,
                              hint: const Text('Academic Executive', style: TextStyle(fontSize: 13)),
                              items: widget.roles.map((r) {
                                return DropdownMenuItem<int>(
                                  value: r.id,
                                  child: Text(r.label.isNotEmpty ? r.label : r.name, style: const TextStyle(fontSize: 13)),
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
              const SizedBox(height: 12),

              // Branch Field
              Text(s.branchLabel, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _selectedBranchId,
                    hint: const Text('—', style: TextStyle(fontSize: 13)),
                    items: widget.branches.map((b) {
                      return DropdownMenuItem<int>(
                        value: b['id'] as int,
                        child: Text(b['name'] as String? ?? 'Branch', style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedBranchId = val),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Responsibilities Field
              Text(s.responsibilitiesLabel, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: _responsibilitiesController,
                maxLines: 2,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),

              // Task Creator & Confidential Access Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.taskCreatorLabel, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<bool>(
                              isExpanded: true,
                              value: _isTaskCreator,
                              items: const [
                                DropdownMenuItem(value: true, child: Text('Yes', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: false, child: Text('No', style: TextStyle(fontSize: 13))),
                              ],
                              onChanged: (val) => setState(() => _isTaskCreator = val ?? true),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.confidentialAccessLabel, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<bool>(
                              isExpanded: true,
                              value: _confidentialAccess,
                              items: const [
                                DropdownMenuItem(value: true, child: Text('Yes', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: false, child: Text('No', style: TextStyle(fontSize: 13))),
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
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(s.cancelButton),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(s.addStaffTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
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
