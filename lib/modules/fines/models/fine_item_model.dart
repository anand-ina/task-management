class FineItemModel {
  final int id;
  final String kind;
  final String label;
  final String amount;
  final int userId;
  final String userName;
  final String? reason;
  final String createdAt;

  FineItemModel({
    required this.id,
    required this.kind,
    required this.label,
    required this.amount,
    required this.userId,
    required this.userName,
    this.reason,
    required this.createdAt,
  });

  factory FineItemModel.fromJson(Map<String, dynamic> json) {
    return FineItemModel(
      id: json['id'] as int? ?? 0,
      kind: json['kind'] as String? ?? 'fine',
      label: json['label'] as String? ?? '',
      amount: json['amount'] as String? ?? '0.00',
      userId: json['user_id'] as int? ?? 0,
      userName: json['user_name'] as String? ?? '',
      reason: json['reason'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
