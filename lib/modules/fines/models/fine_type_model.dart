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
    final rawAmount = json['amount'];
    String formattedAmount = '0';
    if (rawAmount != null) {
      if (rawAmount is num) {
        formattedAmount = (rawAmount % 1 == 0)
            ? rawAmount.toInt().toString()
            : rawAmount.toString();
      } else {
        final str = rawAmount.toString().trim();
        final parsed = double.tryParse(str);
        if (parsed != null && parsed % 1 == 0) {
          formattedAmount = parsed.toInt().toString();
        } else {
          formattedAmount = str;
        }
      }
    }

    return FineTypeModel(
      id: json['id'] as int? ?? 0,
      kind: json['kind'] as String? ?? 'fine',
      label: json['label'] as String? ?? '',
      amount: formattedAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind,
      'label': label,
      'amount': amount,
    };
  }

  FineTypeModel copyWith({
    int? id,
    String? kind,
    String? label,
    String? amount,
  }) {
    return FineTypeModel(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      amount: amount ?? this.amount,
    );
  }
}
