class LedgerRowModel {
  final int id;
  final int points;
  final String reason;
  final int? taskId;
  final String createdAt;
  final String? taskNo;
  final String? title;
  final int balance;

  LedgerRowModel({
    required this.id,
    required this.points,
    required this.reason,
    this.taskId,
    required this.createdAt,
    this.taskNo,
    this.title,
    required this.balance,
  });

  factory LedgerRowModel.fromJson(Map<String, dynamic> json) {
    return LedgerRowModel(
      id: json['id'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
      reason: json['reason'] as String? ?? '',
      taskId: json['task_id'] as int?,
      createdAt: json['created_at'] as String? ?? '',
      taskNo: json['task_no'] as String?,
      title: json['title'] as String?,
      balance: json['balance'] as int? ?? 0,
    );
  }
}

class LedgerModel {
  final int total;
  final List<LedgerRowModel> rows;

  LedgerModel({
    required this.total,
    required this.rows,
  });

  factory LedgerModel.fromJson(Map<String, dynamic> json) {
    return LedgerModel(
      total: json['total'] as int? ?? 0,
      rows: json['rows'] != null && json['rows'] is List
          ? (json['rows'] as List).map((e) => LedgerRowModel.fromJson(e)).toList()
          : [],
    );
  }
}
