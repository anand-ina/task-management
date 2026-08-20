import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/all_tasks_repository.dart';
import 'recurring_tasks_event.dart';
import 'recurring_tasks_state.dart';

class RecurringTasksBloc extends Bloc<RecurringTasksEvent, RecurringTasksState> {
  final AllTasksRepository repository;

  RecurringTasksBloc({AllTasksRepository? allTasksRepository})
      : repository = allTasksRepository ?? AllTasksRepository(),
        super(RecurringTasksInitialState()) {
    on<FetchRecurringTasksEvent>(_onFetchRecurringTasks);
  }

  Future<void> _onFetchRecurringTasks(
    FetchRecurringTasksEvent event,
    Emitter<RecurringTasksState> emit,
  ) async {
    emit(RecurringTasksLoadingState());
    try {
      final tasks = await repository.getRecurringTasks(frequency: event.frequency);
      emit(RecurringTasksLoadedState(tasks: tasks, activeFrequency: event.frequency));
    } catch (e) {
      emit(RecurringTasksErrorState(e.toString()));
    }
  }
}
