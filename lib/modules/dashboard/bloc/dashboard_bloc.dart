import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/todo_model.dart';
import '../repository/dashboard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _repository = DashboardRepository();

  DashboardBloc() : super(DashboardInitialState()) {
    on<FetchDashboardDataEvent>(_onFetchDashboardData);
    on<SelectBranchEvent>(_onSelectBranch);
    on<AddTodoEvent>(_onAddTodo);
    on<ToggleTodoEvent>(_onToggleTodo);
  }

  Future<void> _onFetchDashboardData(
    FetchDashboardDataEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoadingState());
    try {
      final results = await Future.wait([
        _repository.getDashboardData(branchId: event.branchId, mine: event.mine ?? 1),
        _repository.getTeamData(branchId: event.branchId),
        _repository.getNotifications(),
        _repository.getBranches(),
        _repository.getTodos(),
      ]);

      final dashboardData = results[0] as dynamic;
      final teamData = results[1] as dynamic;
      final notifications = results[2] as dynamic;
      final branches = results[3] as dynamic;
      final todos = results[4] as dynamic;
      List<TodoItem> todoList = List<TodoItem>.from(todos);

      emit(DashboardLoadedState(
        dashboardData: dashboardData,
        teamData: teamData,
        notifications: notifications,
        branches: branches,
        todos: todoList,
      ));
    } catch (e) {
      emit(DashboardErrorState(message: e.toString()));
    }
  }

  Future<void> _onSelectBranch(
    SelectBranchEvent event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoadedState) {
      final currentState = state as DashboardLoadedState;
      emit(DashboardLoadingState());
      try {
        final targetBranchId = event.branch.isAll ? null : event.branch.id;
        final results = await Future.wait([
          _repository.getDashboardData(branchId: targetBranchId, mine: 1),
          _repository.getTeamData(branchId: targetBranchId),
        ]);

        emit(currentState.copyWith(
          dashboardData: results[0] as dynamic,
          teamData: results[1] as dynamic,
          selectedBranch: event.branch,
        ));
      } catch (e) {
        emit(DashboardErrorState(message: e.toString()));
      }
    }
  }

  Future<void> _onAddTodo(AddTodoEvent event, Emitter<DashboardState> emit) async {
    if (state is DashboardLoadedState) {
      final currentState = state as DashboardLoadedState;
      final created = await _repository.addTodo(event.text);
      final newItem = created ?? TodoItem(text: event.text);
      final updatedTodos = List<TodoItem>.from(currentState.todos)..add(newItem);
      emit(currentState.copyWith(todos: updatedTodos));
    }
  }

  Future<void> _onToggleTodo(ToggleTodoEvent event, Emitter<DashboardState> emit) async {
    if (state is DashboardLoadedState) {
      final currentState = state as DashboardLoadedState;
      final updatedTodos = List<TodoItem>.from(currentState.todos);
      if (event.index >= 0 && event.index < updatedTodos.length) {
        final item = updatedTodos[event.index];
        final newDoneState = !item.isCompleted;
        item.isCompleted = newDoneState;
        emit(currentState.copyWith(todos: updatedTodos));

        if (item.id != null) {
          await _repository.patchTodo(item.id!, newDoneState);
        }
      }
    }
  }
}
