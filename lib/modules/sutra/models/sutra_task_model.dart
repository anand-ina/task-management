class SutraTaskModel {
  final int id;
  final String taskNo;
  final String title;
  final String description;
  final String priority;
  final String status;
  final int progress;
  final String? dueDate;
  final String branchName;
  final String assignedByName;
  final List<Map<String, dynamic>> assignees;

  SutraTaskModel({
    required this.id,
    required this.taskNo,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.progress,
    this.dueDate,
    required this.branchName,
    required this.assignedByName,
    required this.assignees,
  });

  factory SutraTaskModel.fromJson(Map<String, dynamic> json) {
    return SutraTaskModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      taskNo: json['task_no']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'in_progress',
      progress: json['progress'] is int ? json['progress'] : (int.tryParse(json['progress']?.toString() ?? '0') ?? 0),
      dueDate: json['due_date']?.toString(),
      branchName: json['branch_name']?.toString() ?? 'Head Office',
      assignedByName: json['assigned_by_name']?.toString() ?? '',
      assignees: json['assignees'] is List ? List<Map<String, dynamic>>.from((json['assignees'] as List).whereType<Map<String, dynamic>>()) : [],
    );
  }
}
