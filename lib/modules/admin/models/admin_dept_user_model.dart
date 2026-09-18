class AdminDeptUserModel {
  final int id;
  final String name;
  final String initials;
  final String avatarColor;
  final String email;
  final String designation;
  final String branchCode;
  final String roleLabel;

  AdminDeptUserModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.email,
    required this.designation,
    required this.branchCode,
    required this.roleLabel,
  });

  factory AdminDeptUserModel.fromJson(Map<String, dynamic> json) {
    return AdminDeptUserModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      avatarColor: json['avatar_color'] as String? ?? '#e5484d',
      email: json['email'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      branchCode: json['branch_code'] as String? ?? '',
      roleLabel: json['role_label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'initials': initials,
      'avatar_color': avatarColor,
      'email': email,
      'designation': designation,
      'branch_code': branchCode,
      'role_label': roleLabel,
    };
  }
}
