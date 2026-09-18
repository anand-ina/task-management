import '../models/task_model.dart';
import '../repository/all_tasks_repository.dart';

abstract class AllTasksState {}

class AllTasksInitialState extends AllTasksState {}

class AllTasksLoadingState extends AllTasksState {}

class AllTasksLoadedState extends AllTasksState {
  final TasksResponseModel response;
  final String activeScope;
  final String? activeStatus;
  final String? activePriority;
  final String? activeOwner;
  final String? activeDueFrom;
  final String? activeDueTo;
  final int? activeProgressMin;
  final int? activeProgressMax;
  final String? activeCategory;
  final String? activeSearch;
  final int? activeBranchId;

  AllTasksLoadedState({
    required this.response,
    this.activeScope = 'all',
    this.activeStatus,
    this.activePriority,
    this.activeOwner,
    this.activeDueFrom,
    this.activeDueTo,
    this.activeProgressMin,
    this.activeProgressMax,
    this.activeCategory,
    this.activeSearch,
    this.activeBranchId,
  });
}

class RecurringLookupsLoadedState extends AllTasksState {
  final RecurringLookupsData data;
  RecurringLookupsLoadedState(this.data);
}

class TaskDetailLoadedState extends AllTasksState {
  final TaskDetailWithAssignees data;
  TaskDetailLoadedState(this.data);
}

class AllTasksErrorState extends AllTasksState {
  final String message;
  AllTasksErrorState(this.message);
}
