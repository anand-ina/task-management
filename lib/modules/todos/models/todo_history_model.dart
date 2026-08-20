class TodoHistoryModel {
  final int id;
  final int userId;
  final String day;
  final String text;
  final bool done;
  final String createdAt;
  final String? doneOn;
  final bool stillOpen;
  final int ageDays;

  TodoHistoryModel({
    required this.id,
    required this.userId,
    required this.day,
    required this.text,
    required this.done,
    required this.createdAt,
    this.doneOn,
    required this.stillOpen,
    required this.ageDays,
  });

  factory TodoHistoryModel.fromJson(Map<String, dynamic> json) {
    return TodoHistoryModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      day: json['day'] as String? ?? '',
      text: json['text'] as String? ?? '',
      done: json['done'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
      doneOn: json['done_on'] as String?,
      stillOpen: json['still_open'] as bool? ?? false,
      ageDays: json['age_days'] as int? ?? 0,
    );
  }
}
