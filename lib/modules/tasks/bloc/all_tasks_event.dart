abstract class AllTasksEvent {}

class FetchAllTasksEvent extends AllTasksEvent {
  final String scope;
  final String? status;
  final String? priority;
  final String? owner;
  final String? dueFrom;
  final String? dueTo;
  final int? progressMin;
  final int? progressMax;
  final String? category;
  final String? search;
  final int? branchId;
  final int limit;
  final int offset;

  FetchAllTasksEvent({
    this.scope = 'all',
    this.status,
    this.priority,
    this.owner,
    this.dueFrom,
    this.dueTo,
    this.progressMin,
    this.progressMax,
    this.category,
    this.search,
    this.branchId,
    this.limit = 20,
    this.offset = 0,
  });
}

class FetchRecurringLookupsEvent extends AllTasksEvent {}

class FetchTaskDetailEvent extends AllTasksEvent {
  final int taskId;
  FetchTaskDetailEvent(this.taskId);
}
