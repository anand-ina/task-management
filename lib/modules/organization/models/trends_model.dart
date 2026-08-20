class TrendBucketItem {
  final String label;
  final String weekStart;
  final int created;
  final int completed;

  TrendBucketItem({
    required this.label,
    required this.weekStart,
    required this.created,
    required this.completed,
  });

  factory TrendBucketItem.fromJson(Map<String, dynamic> json) {
    return TrendBucketItem(
      label: json['label'] as String? ?? '',
      weekStart: json['week_start'] as String? ?? '',
      created: (json['created'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'week_start': weekStart,
        'created': created,
        'completed': completed,
      };
}

class TrendsResponseModel {
  final List<TrendBucketItem> items;
  final String bucket;

  TrendsResponseModel({
    required this.items,
    required this.bucket,
  });

  factory TrendsResponseModel.fromJson(Map<String, dynamic> json) {
    final list = (json['weeks'] as List<dynamic>?) ??
        (json['months'] as List<dynamic>?) ??
        (json['items'] as List<dynamic>?);
    return TrendsResponseModel(
      items: list?.map((e) => TrendBucketItem.fromJson(e)).toList() ?? [],
      bucket: json['bucket'] as String? ?? 'week',
    );
  }
}
