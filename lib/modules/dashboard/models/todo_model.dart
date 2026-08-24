class TodoItem {
  final int? id;
  final String text;
  bool isCompleted;

  TodoItem({
    this.id,
    required this.text,
    this.isCompleted = false,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as int?,
      text: json['text'] as String? ?? json['title'] as String? ?? '',
      isCompleted: json['done'] as bool? ?? json['is_completed'] as bool? ?? json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'title': text,
        'is_completed': isCompleted,
      };
}
