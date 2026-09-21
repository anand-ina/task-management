class FineItemModel {
  final int id;
  final String type; // 'reward' or 'fine'
  final String label;
  final String amount;
  final int userId;
  final String member;
  final String? issuedBy;
  final int? taskId;
  final String? taskNo;
  final String? reason;
  final String createdAt;

  FineItemModel({
    required this.id,
    required this.type,
    this.label = '',
    required this.amount,
    this.userId = 0,
    required this.member,
    this.issuedBy,
    this.taskId,
    this.taskNo,
    this.reason,
    required this.createdAt,
  });

  String get kind => type;
  String get userName => member;

  factory FineItemModel.fromJson(Map<String, dynamic> json) {
    final typeVal = (json['type'] ?? json['kind'] ?? 'fine').toString();
    final memberVal = (json['member'] ?? json['user_name'] ?? '').toString();
    final issuedByVal = json['issued_by']?.toString();
    final taskIdVal = json['task_id'] is int ? json['task_id'] as int : int.tryParse(json['task_id']?.toString() ?? '');
    final taskNoVal = json['task_no']?.toString();

    return FineItemModel(
      id: json['id'] as int? ?? 0,
      type: typeVal,
      label: json['label'] as String? ?? '',
      amount: json['amount']?.toString() ?? '0.00',
      userId: json['user_id'] as int? ?? 0,
      member: memberVal,
      issuedBy: issuedByVal,
      taskId: taskIdVal,
      taskNo: taskNoVal,
      reason: json['reason'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
