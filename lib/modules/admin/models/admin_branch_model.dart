class AdminBranchModel {
  final int id;
  final String code;
  final String name;
  final bool isAll;
  final int users;

  AdminBranchModel({
    required this.id,
    required this.code,
    required this.name,
    required this.isAll,
    required this.users,
  });

  factory AdminBranchModel.fromJson(Map<String, dynamic> json) {
    return AdminBranchModel(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isAll: json['is_all'] as bool? ?? false,
      users: json['users'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'is_all': isAll,
      'users': users,
    };
  }
}
