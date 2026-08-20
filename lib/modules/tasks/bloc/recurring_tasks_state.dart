import '../models/recurring_task_model.dart';

abstract class RecurringTasksState {}

class RecurringTasksInitialState extends RecurringTasksState {}

class RecurringTasksLoadingState extends RecurringTasksState {}

class RecurringTasksLoadedState extends RecurringTasksState {
  final List<RecurringTaskModel> tasks;
  final String? activeFrequency;

  RecurringTasksLoadedState({
    required this.tasks,
    this.activeFrequency,
  });
}

class RecurringTasksErrorState extends RecurringTasksState {
  final String message;
  RecurringTasksErrorState(this.message);
}
