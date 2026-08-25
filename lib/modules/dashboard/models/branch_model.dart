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
    final idVal = json['id'] as int? ?? 0;
    final codeVal = json['code'] as String? ?? '';
    return BranchModel(
      id: idVal,
      code: codeVal,
      name: json['name'] as String? ?? '',
      isAll: idVal == 0 || codeVal.toUpperCase() == 'ALL',
    );
  }
}
