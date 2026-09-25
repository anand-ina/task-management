class AdminRoleModel {
  final int id;
  final String name;
  final String label;
  final int level;
  final List<String> permissions;
  final int users;

  const AdminRoleModel({
    required this.id,
    required this.name,
    required this.label,
    required this.level,
    required this.permissions,
    required this.users,
  });

  factory AdminRoleModel.fromJson(Map<String, dynamic> json) {
    return AdminRoleModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      label: json['label'] as String? ?? '',
      level: json['level'] as int? ?? 0,
      permissions: (json['permissions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      users: json['users'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'label': label,
        'level': level,
        'permissions': permissions,
        'users': users,
      };
}
