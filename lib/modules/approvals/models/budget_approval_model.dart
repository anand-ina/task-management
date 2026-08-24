class BudgetApprovalModel {
  final int id;
  final int? taskId;
  final String? taskNo;
  final String? title;
  final String currency;
  final double? amount;
  final String status;
  final String? category;
  final String? justification;
  final String? requestedBy;
  final String? createdAt;
  final String? neededBy;
  final String? note;

  BudgetApprovalModel({
    required this.id,
    this.taskId,
    this.taskNo,
    this.title,
    this.currency = 'INR',
    this.amount,
    required this.status,
    this.category,
    this.justification,
    this.requestedBy,
    this.createdAt,
    this.neededBy,
    this.note,
  });

  factory BudgetApprovalModel.fromJson(Map<String, dynamic> json) {
    double? amt;
    if (json['amount'] is num) {
      amt = (json['amount'] as num).toDouble();
    } else if (json['amount'] is String) {
      amt = double.tryParse(json['amount'] as String);
    }

    return BudgetApprovalModel(
      id: json['id'] as int? ?? 0,
      taskId: json['task_id'] as int?,
      taskNo: json['task_no'] as String?,
      title: json['title'] as String? ?? json['task_title'] as String?,
      currency: json['currency'] as String? ?? 'INR',
      amount: amt,
      status: json['status'] as String? ?? 'pending',
      category: json['category'] as String?,
      justification: json['justification'] as String? ?? json['reason'] as String?,
      requestedBy: json['requested_by'] as String? ?? json['raised_by'] as String?,
      createdAt: json['created_at'] as String? ?? json['date'] as String?,
      neededBy: json['needed_by'] as String? ?? json['neededBy'] as String?,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'task_no': taskNo,
      'title': title,
      'currency': currency,
      'amount': amount,
      'status': status,
      'category': category,
      'justification': justification,
      'requested_by': requestedBy,
      'created_at': createdAt,
      'needed_by': neededBy,
      'note': note,
    };
  }
}
