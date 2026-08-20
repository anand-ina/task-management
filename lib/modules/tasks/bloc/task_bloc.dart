import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/task_repository.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository repository;

  TaskBloc({required this.repository}) : super(TaskInitialState()) {
    on<FetchPeriodTasksEvent>(_onFetchPeriodTasks);
    on<FetchTaskDetailEvent>(_onFetchTaskDetail);
  }

  Future<void> _onFetchPeriodTasks(
      FetchPeriodTasksEvent event, Emitter<TaskState> emit) async {
    emit(TasksLoadingState());
    try {
      final results = await Future.wait([
        repository.getBranches(),
        repository.getTasks(
          period: event.period,
          scope: event.scope,
          sort: event.sort,
          dir: event.dir,
        ),
      ]);

      final branches = results[0] as List<dynamic>;
      final response = results[1] as dynamic;

      emit(TasksLoadedState(
        branches: branches.cast(),
        response: response,
      ));
    } catch (e) {
      emit(TaskErrorState(e.toString()));
    }
  }

  Future<void> _onFetchTaskDetail(
      FetchTaskDetailEvent event, Emitter<TaskState> emit) async {
    emit(TaskDetailLoadingState());
    try {
      final detail = await repository.getTaskDetail(event.taskId);
      emit(TaskDetailLoadedState(detail));
    } catch (e) {
      emit(TaskErrorState(e.toString()));
    }
  }
}
