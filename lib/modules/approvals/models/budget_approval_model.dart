class BudgetApprovalModel {
  final int id;
  final int? taskId;
  final String? taskNo;
  final String? title;
  final double? amount;
  final String status;
  final String? requestedBy;
  final String? createdAt;
  final String? note;

  BudgetApprovalModel({
    required this.id,
    this.taskId,
    this.taskNo,
    this.title,
    this.amount,
    required this.status,
    this.requestedBy,
    this.createdAt,
    this.note,
  });

  factory BudgetApprovalModel.fromJson(Map<String, dynamic> json) {
    return BudgetApprovalModel(
      id: json['id'] as int? ?? 0,
      taskId: json['task_id'] as int?,
      taskNo: json['task_no'] as String?,
      title: json['title'] as String?,
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : null,
      status: json['status'] as String? ?? 'pending',
      requestedBy: json['requested_by'] as String?,
      createdAt: json['created_at'] as String?,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'task_no': taskNo,
      'title': title,
      'amount': amount,
      'status': status,
      'requested_by': requestedBy,
      'created_at': createdAt,
      'note': note,
    };
  }
}
