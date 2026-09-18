class AdminDepartmentModel {
  final int id;
  final String name;
  final int users;

  AdminDepartmentModel({
    required this.id,
    required this.name,
    required this.users,
  });

  factory AdminDepartmentModel.fromJson(Map<String, dynamic> json) {
    return AdminDepartmentModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      users: json['users'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'users': users,
    };
  }
}
