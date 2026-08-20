class EscalationModel {
  final int id;
  final String? type;
  final String? reason;
  final String? proposedDate;
  final String status;
  final String? decisionNote;
  final String? createdAt;
  final String? decidedAt;
  final int? taskId;
  final String? taskNo;
  final String? title;
  final String? priority;
  final String? taskStatus;
  final String? dueDate;
  final int? assignedByUserId;
  final String? raisedBy;

  EscalationModel({
    required this.id,
    this.type,
    this.reason,
    this.proposedDate,
    required this.status,
    this.decisionNote,
    this.createdAt,
    this.decidedAt,
    this.taskId,
    this.taskNo,
    this.title,
    this.priority,
    this.taskStatus,
    this.dueDate,
    this.assignedByUserId,
    this.raisedBy,
  });

  factory EscalationModel.fromJson(Map<String, dynamic> json) {
    return EscalationModel(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String?,
      reason: json['reason'] as String?,
      proposedDate: json['proposed_date'] as String?,
      status: json['status'] as String? ?? 'pending',
      decisionNote: json['decision_note'] as String?,
      createdAt: json['created_at'] as String?,
      decidedAt: json['decided_at'] as String?,
      taskId: json['task_id'] as int?,
      taskNo: json['task_no'] as String?,
      title: json['title'] as String?,
      priority: json['priority'] as String?,
      taskStatus: json['task_status'] as String?,
      dueDate: json['due_date'] as String?,
      assignedByUserId: json['assigned_by_user_id'] as int?,
      raisedBy: json['raised_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'reason': reason,
      'proposed_date': proposedDate,
      'status': status,
      'decision_note': decisionNote,
      'created_at': createdAt,
      'decided_at': decidedAt,
      'task_id': taskId,
      'task_no': taskNo,
      'title': title,
      'priority': priority,
      'task_status': taskStatus,
      'due_date': dueDate,
      'assigned_by_user_id': assignedByUserId,
      'raised_by': raisedBy,
    };
  }
}
