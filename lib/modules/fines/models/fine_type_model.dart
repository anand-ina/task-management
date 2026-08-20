class FineTypeModel {
  final int id;
  final String kind; // 'fine' or 'reward'
  final String label;
  final String amount;

  FineTypeModel({
    required this.id,
    required this.kind,
    required this.label,
    required this.amount,
  });

  factory FineTypeModel.fromJson(Map<String, dynamic> json) {
    return FineTypeModel(
      id: json['id'] as int? ?? 0,
      kind: json['kind'] as String? ?? 'fine',
      label: json['label'] as String? ?? '',
      amount: json['amount'] as String? ?? '0.00',
    );
  }
}
