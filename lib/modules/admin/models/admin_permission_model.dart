class AdminPermissionModel {
  final int id;
  final String code;
  final String description;

  const AdminPermissionModel({
    required this.id,
    required this.code,
    required this.description,
  });

  factory AdminPermissionModel.fromJson(Map<String, dynamic> json) {
    return AdminPermissionModel(
      id: json['id'] as int,
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'description': description,
      };
}
