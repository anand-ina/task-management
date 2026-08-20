class OneOnOnePendingModel {
  final int id;
  final String name;
  final String roleLabel;

  OneOnOnePendingModel({
    required this.id,
    required this.name,
    required this.roleLabel,
  });

  factory OneOnOnePendingModel.fromJson(Map<String, dynamic> json) {
    return OneOnOnePendingModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      roleLabel: json['roleLabel'] as String? ?? json['role_label'] as String? ?? 'Staff',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'roleLabel': roleLabel,
      };
}
