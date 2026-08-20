class DepartmentModel {
  final int id;
  final String name;
  final int staffCount;

  DepartmentModel({
    required this.id,
    required this.name,
    required this.staffCount,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      staffCount: json['staff'] as int? ?? 0,
    );
  }
}
