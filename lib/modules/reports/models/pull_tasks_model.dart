class PulledTaskItem {
  final int taskId;
  final String line;

  PulledTaskItem({required this.taskId, required this.line});

  factory PulledTaskItem.fromJson(Map<String, dynamic> json) {
    return PulledTaskItem(
      taskId: json['taskId'] is int
          ? json['taskId'] as int
          : (json['task_id'] is int ? json['task_id'] as int : int.tryParse(json['taskId']?.toString() ?? '') ?? 0),
      line: json['line']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'line': line,
      };
}

class PullTasksResponseModel {
  final List<dynamic> workCompleted;
  final List<dynamic> workInProgress;
  final List<PulledTaskItem> pendingTasks;

  PullTasksResponseModel({
    required this.workCompleted,
    required this.workInProgress,
    required this.pendingTasks,
  });

  factory PullTasksResponseModel.fromJson(Map<String, dynamic> json) {
    List<PulledTaskItem> pending = [];
    if (json['pending_tasks'] is List) {
      pending = (json['pending_tasks'] as List)
          .map((e) => PulledTaskItem.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    } else if (json['pendingTasks'] is List) {
      pending = (json['pendingTasks'] as List)
          .map((e) => PulledTaskItem.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }
    return PullTasksResponseModel(
      workCompleted: json['work_completed'] is List ? json['work_completed'] as List : [],
      workInProgress: json['work_in_progress'] is List ? json['work_in_progress'] as List : [],
      pendingTasks: pending,
    );
  }
}
