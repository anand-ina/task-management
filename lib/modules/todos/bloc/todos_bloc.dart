import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/todos_repository.dart';
import 'todos_event.dart';
import 'todos_state.dart';

class TodosBloc extends Bloc<TodosEvent, TodosState> {
  final TodosRepository repository;

  TodosBloc({TodosRepository? todosRepository})
      : repository = todosRepository ?? TodosRepository(),
        super(TodosInitialState()) {
    on<FetchTodoHistoryEvent>(_onFetchTodoHistory);
  }

  Future<void> _onFetchTodoHistory(
    FetchTodoHistoryEvent event,
    Emitter<TodosState> emit,
  ) async {
    emit(TodosLoadingState());
    try {
      final history = await repository.getTodoHistory();
      emit(TodoHistoryLoadedState(history));
    } catch (e) {
      emit(TodosErrorState(e.toString()));
    }
  }
}
