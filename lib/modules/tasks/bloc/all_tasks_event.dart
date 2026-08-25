abstract class AllTasksEvent {}

class FetchAllTasksEvent extends AllTasksEvent {
  final String scope;
  final String? status;
  final String? priority;
  final String? search;
  final int limit;
  final int offset;

  FetchAllTasksEvent({
    this.scope = 'all',
    this.status,
    this.priority,
    this.search,
    this.limit = 10,
    this.offset = 0,
  });
}

class FetchRecurringLookupsEvent extends AllTasksEvent {}

class FetchTaskDetailEvent extends AllTasksEvent {
  final int taskId;
  FetchTaskDetailEvent(this.taskId);
}
