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
        owner: event.owner,
        dueFrom: event.dueFrom,
        dueTo: event.dueTo,
        progressMin: event.progressMin,
        progressMax: event.progressMax,
        category: event.category,
        search: event.search,
        branchId: event.branchId,
      );

      if (event.offset > 0 && state is AllTasksLoadedState) {
        final currentState = state as AllTasksLoadedState;
        final combinedItems = List<TaskItemModel>.from(currentState.response.items)
          ..addAll(response.items);
        final combinedResponse = TasksResponseModel(
          items: combinedItems,
          total: response.total > 0 ? response.total : currentState.response.total,
          inProgress: response.inProgress > 0 ? response.inProgress : currentState.response.inProgress,
          needsAction: response.needsAction > 0 ? response.needsAction : currentState.response.needsAction,
          needsReview: response.needsReview > 0 ? response.needsReview : currentState.response.needsReview,
          overdue: response.overdue > 0 ? response.overdue : currentState.response.overdue,
          completed: response.completed > 0 ? response.completed : currentState.response.completed,
          dropped: response.dropped > 0 ? response.dropped : currentState.response.dropped,
          limit: response.limit,
          offset: response.offset,
        );
        emit(AllTasksLoadedState(
          response: combinedResponse,
          activeScope: event.scope,
          activeStatus: event.status,
          activePriority: event.priority,
          activeOwner: event.owner,
          activeDueFrom: event.dueFrom,
          activeDueTo: event.dueTo,
          activeProgressMin: event.progressMin,
          activeProgressMax: event.progressMax,
          activeCategory: event.category,
          activeSearch: event.search,
          activeBranchId: event.branchId,
        ));
      } else {
        emit(AllTasksLoadedState(
          response: response,
          activeScope: event.scope,
          activeStatus: event.status,
          activePriority: event.priority,
          activeOwner: event.owner,
          activeDueFrom: event.dueFrom,
          activeDueTo: event.dueTo,
          activeProgressMin: event.progressMin,
          activeProgressMax: event.progressMax,
          activeCategory: event.category,
          activeSearch: event.search,
          activeBranchId: event.branchId,
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
