class PerformanceMeModel {
  final int assigned;
  final int done;
  final int overdue;
  final int points;

  PerformanceMeModel({
    required this.assigned,
    required this.done,
    required this.overdue,
    required this.points,
  });

  factory PerformanceMeModel.fromJson(Map<String, dynamic> json) {
    return PerformanceMeModel(
      assigned: json['assigned'] as int? ?? 0,
      done: json['done'] as int? ?? 0,
      overdue: json['overdue'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
    );
  }
}
