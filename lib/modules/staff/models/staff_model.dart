class StaffModel {
  final int id;
  final String name;
  final String firstName;
  final String? lastName;
  final String email;
  final String phone;
  final String countryCode;
  final String? designation;
  final String employmentType;
  final String? responsibilities;
  final bool isTaskCreator;
  final bool confidentialAccess;
  final String avatarColor;
  final String initials;
  final String department;
  final int? departmentId;
  final String? branchCode;
  final String? branchName;
  final String roleLabel;
  final String roleName;
  final int created;
  final int assigned;
  final int done;
  final String fines;
  final bool isPasswordPending;

  StaffModel({
    required this.id,
    required this.name,
    required this.firstName,
    this.lastName,
    required this.email,
    required this.phone,
    required this.countryCode,
    this.designation,
    required this.employmentType,
    this.responsibilities,
    required this.isTaskCreator,
    required this.confidentialAccess,
    required this.avatarColor,
    required this.initials,
    required this.department,
    this.departmentId,
    this.branchCode,
    this.branchName,
    required this.roleLabel,
    required this.roleName,
    required this.created,
    required this.assigned,
    required this.done,
    required this.fines,
    this.isPasswordPending = true,
  });

  StaffModel copyWith({
    int? id,
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? countryCode,
    String? designation,
    String? employmentType,
    String? responsibilities,
    bool? isTaskCreator,
    bool? confidentialAccess,
    String? avatarColor,
    String? initials,
    String? department,
    int? departmentId,
    String? branchCode,
    String? branchName,
    String? roleLabel,
    String? roleName,
    int? created,
    int? assigned,
    int? done,
    String? fines,
    bool? isPasswordPending,
  }) {
    return StaffModel(
      id: id ?? this.id,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      countryCode: countryCode ?? this.countryCode,
      designation: designation ?? this.designation,
      employmentType: employmentType ?? this.employmentType,
      responsibilities: responsibilities ?? this.responsibilities,
      isTaskCreator: isTaskCreator ?? this.isTaskCreator,
      confidentialAccess: confidentialAccess ?? this.confidentialAccess,
      avatarColor: avatarColor ?? this.avatarColor,
      initials: initials ?? this.initials,
      department: department ?? this.department,
      departmentId: departmentId ?? this.departmentId,
      branchCode: branchCode ?? this.branchCode,
      branchName: branchName ?? this.branchName,
      roleLabel: roleLabel ?? this.roleLabel,
      roleName: roleName ?? this.roleName,
      created: created ?? this.created,
      assigned: assigned ?? this.assigned,
      done: done ?? this.done,
      fines: fines ?? this.fines,
      isPasswordPending: isPasswordPending ?? this.isPasswordPending,
    );
  }

  bool get hasMissingContact =>
      phone.trim().isEmpty ||
      phone == '0' ||
      phone.toLowerCase().contains('no mobile') ||
      phone.toLowerCase().contains('missing');

  String get handle {
    if (email.contains('@')) {
      final username = email.split('@').first;
      if (username.isNotEmpty) return '@$username';
    }
    return '@${name.toLowerCase().replaceAll(' ', '')}';
  }

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String?,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '+91',
      designation: json['designation'] as String?,
      employmentType: json['employment_type'] as String? ?? 'non_teaching',
      responsibilities: json['responsibilities'] as String?,
      isTaskCreator: json['is_task_creator'] as bool? ?? false,
      confidentialAccess: json['confidential_access'] as bool? ?? false,
      avatarColor: json['avatar_color'] as String? ?? '#d98a04',
      initials: json['initials'] as String? ?? '',
      department: json['department'] as String? ?? '',
      departmentId: json['department_id'] as int?,
      branchCode: json['branch_code'] as String?,
      branchName: json['branch_name'] as String?,
      roleLabel: json['role_label'] as String? ?? 'Member',
      roleName: json['role_name'] as String? ?? 'member',
      created: json['created'] as int? ?? 0,
      assigned: json['assigned'] as int? ?? 0,
      done: json['done'] as int? ?? 0,
      fines: json['fines']?.toString() ?? '0',
      isPasswordPending: json['is_password_pending'] as bool? ??
          json['password_pending'] as bool? ??
          true,
    );
  }
}
