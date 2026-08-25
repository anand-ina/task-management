import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/task_model.dart';
import '../repository/all_tasks_repository.dart';
import 'all_tasks_event.dart';
import 'all_tasks_state.dart';

class AllTasksBloc extends Bloc<AllTasksEvent, AllTasksState> {
  final AllTasksRepository repository;

  AllTasksBloc({AllTasksRepository? allTasksRepository})
      : repository = allTasksRepository ?? AllTasksRepository(),
        super(AllTasksInitialState()) {
    on<FetchAllTasksEvent>(_onFetchAllTasks);
    on<FetchRecurringLookupsEvent>(_onFetchRecurringLookups);
    on<FetchTaskDetailEvent>(_onFetchTaskDetail);
  }

  Future<void> _onFetchAllTasks(
    FetchAllTasksEvent event,
    Emitter<AllTasksState> emit,
  ) async {
    if (event.offset == 0) {
      emit(AllTasksLoadingState());
    }
    try {
      final response = await repository.getAllTasks(
        scope: event.scope,
        limit: event.limit,
        offset: event.offset,
        status: event.status,
        priority: event.priority,
        search: event.search,
      );

      if (event.offset > 0 && state is AllTasksLoadedState) {
        final currentState = state as AllTasksLoadedState;
        final combinedItems = List<TaskItemModel>.from(currentState.response.items)
          ..addAll(response.items);
        final combinedResponse = TasksResponseModel(
          items: combinedItems,
          total: response.total > 0 ? response.total : currentState.response.total,
          limit: response.limit,
          offset: response.offset,
        );
        emit(AllTasksLoadedState(
          response: combinedResponse,
          activeScope: event.scope,
          activeStatus: event.status,
          activePriority: event.priority,
          activeSearch: event.search,
        ));
      } else {
        emit(AllTasksLoadedState(
          response: response,
          activeScope: event.scope,
          activeStatus: event.status,
          activePriority: event.priority,
          activeSearch: event.search,
        ));
      }
    } catch (e) {
      emit(AllTasksErrorState(e.toString()));
    }
  }

  Future<void> _onFetchRecurringLookups(
    FetchRecurringLookupsEvent event,
    Emitter<AllTasksState> emit,
  ) async {
    try {
      final data = await repository.getRecurringLookups();
      emit(RecurringLookupsLoadedState(data));
    } catch (e) {
      emit(AllTasksErrorState(e.toString()));
    }
  }

  Future<void> _onFetchTaskDetail(
    FetchTaskDetailEvent event,
    Emitter<AllTasksState> emit,
  ) async {
    try {
      final data = await repository.getTaskDetail(event.taskId);
      emit(TaskDetailLoadedState(data));
    } catch (e) {
      emit(AllTasksErrorState(e.toString()));
    }
  }
}
