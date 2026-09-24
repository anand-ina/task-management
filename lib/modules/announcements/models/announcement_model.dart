class AnnouncementModel {
  final int id;
  final String title;
  final String body;
  final String priority;
  final bool active;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? createdAt;
  final String? createdByName;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    required this.priority,
    this.active = true,
    this.startsAt,
    this.endsAt,
    this.createdAt,
    this.createdByName,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic val) {
      if (val == null) return null;
      if (val is String && val.isNotEmpty) {
        return DateTime.tryParse(val)?.toLocal();
      }
      return null;
    }

    final rawStartsAt = json['starts_at'] ?? json['startsAt'];
    final rawEndsAt = json['ends_at'] ?? json['endsAt'];
    final rawCreatedAt = json['created_at'] ?? json['createdAt'];
    final rawCreatedByName = json['created_by_name'] ?? json['createdByName'];

    return AnnouncementModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      priority: (json['priority'] as String? ?? 'info').toLowerCase(),
      active: json['active'] == null
          ? true
          : (json['active'] is bool
              ? json['active'] as bool
              : (json['active'] == 1 || json['active'] == 'true' || json['active'] == '1')),
      startsAt: parseDateTime(rawStartsAt),
      endsAt: parseDateTime(rawEndsAt),
      createdAt: parseDateTime(rawCreatedAt),
      createdByName: rawCreatedByName?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'priority': priority,
      'active': active,
      if (startsAt != null) 'startsAt': startsAt!.toUtc().toIso8601String(),
      if (endsAt != null) 'endsAt': endsAt!.toUtc().toIso8601String(),
    };
  }

  AnnouncementModel copyWith({
    int? id,
    String? title,
    String? body,
    String? priority,
    bool? active,
    DateTime? startsAt,
    DateTime? endsAt,
    DateTime? createdAt,
    String? createdByName,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      priority: priority ?? this.priority,
      active: active ?? this.active,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      createdAt: createdAt ?? this.createdAt,
      createdByName: createdByName ?? this.createdByName,
    );
  }
}
