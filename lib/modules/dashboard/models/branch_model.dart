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
    final idVal = json['id'] is int
        ? json['id'] as int
        : (int.tryParse(json['id']?.toString() ?? '0') ?? 0);
    final codeVal = json['code']?.toString() ?? json['branch_code']?.toString() ?? '';
    final nameVal = json['name']?.toString() ?? json['branch_name']?.toString() ?? '';
    return BranchModel(
      id: idVal,
      code: codeVal,
      name: nameVal,
      isAll: idVal == 0 || codeVal.toUpperCase() == 'ALL' || nameVal.toLowerCase() == 'all branches',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BranchModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code;

  @override
  int get hashCode => id.hashCode ^ code.hashCode;
}
