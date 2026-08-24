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
    on<FetchTodayTodosEvent>(_onFetchTodayTodos);
    on<AddTodayTodoEvent>(_onAddTodayTodo);
    on<ToggleTodoEvent>(_onToggleTodo);
    on<DeleteTodoEvent>(_onDeleteTodo);
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

  Future<void> _onFetchTodayTodos(
    FetchTodayTodosEvent event,
    Emitter<TodosState> emit,
  ) async {
    emit(TodosLoadingState());
    try {
      final data = await repository.getTodayTodos();
      emit(TodayTodosLoadedState(data));
    } catch (e) {
      emit(TodosErrorState(e.toString()));
    }
  }

  Future<void> _onAddTodayTodo(
    AddTodayTodoEvent event,
    Emitter<TodosState> emit,
  ) async {
    try {
      await repository.addTodo(event.text);
      add(FetchTodayTodosEvent());
    } catch (e) {
      emit(TodosErrorState(e.toString()));
    }
  }

  Future<void> _onToggleTodo(
    ToggleTodoEvent event,
    Emitter<TodosState> emit,
  ) async {
    try {
      await repository.toggleTodoStatus(event.id, event.done);
      add(FetchTodayTodosEvent());
    } catch (e) {
      emit(TodosErrorState(e.toString()));
    }
  }

  Future<void> _onDeleteTodo(
    DeleteTodoEvent event,
    Emitter<TodosState> emit,
  ) async {
    try {
      await repository.deleteTodo(event.id);
      add(FetchTodayTodosEvent());
    } catch (e) {
      emit(TodosErrorState(e.toString()));
    }
  }
}
