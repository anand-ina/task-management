class RecentActivityItem {
  final int id;
  final String actor;
  final String initials;
  final String avatarColor;
  final String taskNo;
  final String title;
  final String description;
  final String status;
  final String priority;
  final int progress;
  final String? dueDate;
  final String? completedDate;
  final String branchCode;
  final String branchName;
  final String note;
  final String at;

  RecentActivityItem({
    required this.id,
    required this.actor,
    required this.initials,
    required this.avatarColor,
    required this.taskNo,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.progress,
    this.dueDate,
    this.completedDate,
    required this.branchCode,
    required this.branchName,
    required this.note,
    required this.at,
  });

  factory RecentActivityItem.fromJson(Map<String, dynamic> json) {
    return RecentActivityItem(
      id: json['id'] as int? ?? 0,
      actor: json['actor'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      avatarColor: json['avatar_color'] as String? ?? '#cf3d8a',
      taskNo: json['task_no'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? '',
      priority: json['priority'] as String? ?? '',
      progress: json['progress'] as int? ?? 0,
      dueDate: json['due_date'] as String?,
      completedDate: json['completed_date'] as String?,
      branchCode: json['branch_code'] as String? ?? '',
      branchName: json['branch_name'] as String? ?? '',
      note: json['note'] as String? ?? '',
      at: json['at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'actor': actor,
        'initials': initials,
        'avatar_color': avatarColor,
        'task_no': taskNo,
        'title': title,
        'description': description,
        'status': status,
        'priority': priority,
        'progress': progress,
        'due_date': dueDate,
        'completed_date': completedDate,
        'branch_code': branchCode,
        'branch_name': branchName,
        'note': note,
        'at': at,
      };
}
