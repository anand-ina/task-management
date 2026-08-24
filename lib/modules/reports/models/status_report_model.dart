class AutoLineItemModel {
  final String? section;
  final String line;
  final bool isAuto;
  final int? taskId;

  AutoLineItemModel({
    this.section,
    required this.line,
    this.isAuto = true,
    this.taskId,
  });

  factory AutoLineItemModel.fromJson(Map<String, dynamic> json) {
    return AutoLineItemModel(
      section: json['section']?.toString(),
      line: json['line']?.toString() ?? '',
      isAuto: json['is_auto'] as bool? ?? true,
      taskId: json['task_id'] is int
          ? json['task_id'] as int
          : (json['taskId'] is int ? json['taskId'] as int : int.tryParse(json['task_id']?.toString() ?? '')),
    );
  }

  Map<String, dynamic> toJson() => {
        if (section != null) 'section': section,
        'line': line,
        'is_auto': isAuto,
        if (taskId != null) 'task_id': taskId,
        if (taskId != null) 'taskId': taskId,
      };
}

class StatusReportItemModel {
  final int id;
  final int? userId;
  final String type; // 'dsr', 'wsr', 'msr'
  final String periodDate;
  final String? title;
  final String? workCompleted;
  final String? workInProgress;
  final String? pendingTasks;
  final String? challenges;
  final String status; // 'draft', 'submitted'
  final bool isLocked;
  final String? submittedAt;
  final String? createdAt;
  final List<AutoLineItemModel>? autoLines;

  StatusReportItemModel({
    required this.id,
    this.userId,
    required this.type,
    required this.periodDate,
    this.title,
    this.workCompleted,
    this.workInProgress,
    this.pendingTasks,
    this.challenges,
    required this.status,
    required this.isLocked,
    this.submittedAt,
    this.createdAt,
    this.autoLines,
  });

  factory StatusReportItemModel.fromJson(Map<String, dynamic> json) {
    List<AutoLineItemModel>? lines;
    if (json['autoLines'] is List) {
      lines = (json['autoLines'] as List)
          .map((e) => AutoLineItemModel.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }

    return StatusReportItemModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] as int : int.tryParse(json['user_id']?.toString() ?? ''),
      type: json['type']?.toString() ?? 'dsr',
      periodDate: json['period_date']?.toString() ?? json['periodDate']?.toString() ?? '',
      title: json['title']?.toString(),
      workCompleted: json['work_completed']?.toString() ?? json['workCompleted']?.toString(),
      workInProgress: json['work_in_progress']?.toString() ?? json['workInProgress']?.toString(),
      pendingTasks: json['pending_tasks']?.toString() ?? json['pendingTasks']?.toString(),
      challenges: json['challenges']?.toString(),
      status: json['status']?.toString() ?? 'draft',
      isLocked: json['is_locked'] as bool? ?? false,
      submittedAt: json['submitted_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      autoLines: lines,
    );
  }
}
