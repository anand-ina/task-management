class BranchModel {
  final int id;
  final String code;
  final String name;
  final bool isAll;

  BranchModel({
    required this.id,
    required this.code,
    required this.name,
    required this.isAll,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isAll: json['is_all'] as bool? ?? false,
    );
  }
}
