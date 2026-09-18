class AdminBranchUserModel {
  final int id;
  final String name;
  final String initials;
  final String avatarColor;
  final String email;
  final String designation;
  final String department;
  final String roleLabel;

  AdminBranchUserModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.email,
    required this.designation,
    required this.department,
    required this.roleLabel,
  });

  factory AdminBranchUserModel.fromJson(Map<String, dynamic> json) {
    return AdminBranchUserModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      avatarColor: json['avatar_color'] as String? ?? '#132a50',
      email: json['email'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      department: json['department'] as String? ?? '',
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
      'department': department,
      'role_label': roleLabel,
    };
  }
}
