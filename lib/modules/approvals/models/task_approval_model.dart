class TaskApprovalModel {
  final int id;
  final String status;
  final String? note;
  final String? createdAt;
  final int? taskId;
  final String? taskNo;
  final String? title;
  final String? priority;
  final String? requestedBy;

  TaskApprovalModel({
    required this.id,
    required this.status,
    this.note,
    this.createdAt,
    this.taskId,
    this.taskNo,
    this.title,
    this.priority,
    this.requestedBy,
  });

  factory TaskApprovalModel.fromJson(Map<String, dynamic> json) {
    return TaskApprovalModel(
      id: json['id'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      note: json['note'] as String?,
      createdAt: json['created_at'] as String?,
      taskId: json['task_id'] as int?,
      taskNo: json['task_no'] as String?,
      title: json['title'] as String?,
      priority: json['priority'] as String?,
      requestedBy: json['requested_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'note': note,
      'created_at': createdAt,
      'task_id': taskId,
      'task_no': taskNo,
      'title': title,
      'priority': priority,
      'requested_by': requestedBy,
    };
  }
}
