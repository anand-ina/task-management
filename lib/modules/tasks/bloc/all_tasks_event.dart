abstract class AllTasksEvent {}

class FetchAllTasksEvent extends AllTasksEvent {
  final String scope;
  final String? status;
  final String? priority;
  final String? search;

  FetchAllTasksEvent({
    this.scope = 'all',
    this.status,
    this.priority,
    this.search,
  });
}

class FetchRecurringLookupsEvent extends AllTasksEvent {}

class FetchTaskDetailEvent extends AllTasksEvent {
  final int taskId;
  FetchTaskDetailEvent(this.taskId);
}
