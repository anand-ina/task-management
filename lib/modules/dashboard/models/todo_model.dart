import 'package:equatable/equatable.dart';

class TodoItem extends Equatable {
  final int? id;
  final String text;
  final bool isCompleted;

  const TodoItem({
    this.id,
    required this.text,
    this.isCompleted = false,
  });

  TodoItem copyWith({
    int? id,
    String? text,
    bool? isCompleted,
  }) {
    return TodoItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    final doneVal = json['done'] ?? json['is_completed'] ?? json['completed'];
    final isDone = doneVal == true || doneVal == 1 || doneVal == 'true' || doneVal == '1';
    final idVal = json['id'] is int
        ? json['id'] as int
        : int.tryParse(json['id']?.toString() ?? '');

    return TodoItem(
      id: idVal,
      text: json['text'] as String? ?? json['title'] as String? ?? '',
      isCompleted: isDone,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'title': text,
        'text': text,
        'is_completed': isCompleted,
        'done': isCompleted,
      };

  @override
  List<Object?> get props => [id, text, isCompleted];
}
