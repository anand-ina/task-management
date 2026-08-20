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
  final String? activeSearch;

  AllTasksLoadedState({
    required this.response,
    this.activeScope = 'all',
    this.activeStatus,
    this.activePriority,
    this.activeSearch,
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
