class RoleModel {
  final int id;
  final String name;
  final String label;
  final int level;

  RoleModel({
    required this.id,
    required this.name,
    required this.label,
    required this.level,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      label: json['label'] as String? ?? '',
      level: json['level'] as int? ?? 0,
    );
  }
}
