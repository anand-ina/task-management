import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/preferences_service.dart';
import '../models/branch_model.dart';
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
      final role = (await PreferencesService().getUserRole())?.toLowerCase() ?? '';
      final roleLabel = (await PreferencesService().getUserRoleLabel())?.toLowerCase() ?? '';
      final isManager = role.contains('manager') || roleLabel.contains('manager');

      final effectiveBranchId = isManager ? null : event.branchId;
      final effectiveMine = isManager ? 1 : event.mine;
      final results = await Future.wait([
        _repository.getDashboardData(branchId: effectiveBranchId, mine: effectiveMine),
        _repository.getTeamData(branchId: effectiveBranchId, mine: effectiveMine),
        _repository.getNotifications(),
        _repository.getBranches(),
        _repository.getTodos(),
      ]);

      final dashboardData = results[0] as dynamic;
      final teamData = results[1] as dynamic;
      final notifications = results[2] as dynamic;
      final branchesRes = results[3] as List<BranchModel>;
      final todos = results[4] as dynamic;
      List<TodoItem> todoList = List<TodoItem>.from(todos);

      List<BranchModel> branchList = List<BranchModel>.from(branchesRes);
      if (!branchList.any((b) => b.id == 0 || b.code.toUpperCase() == 'ALL' || b.name.toLowerCase().contains('all branches'))) {
        branchList.insert(0, BranchModel(id: 0, code: 'ALL', name: 'All Branches', isAll: true));
      }

      BranchModel? selected;
      if (effectiveBranchId != null && effectiveBranchId > 0) {
        final match = branchList.firstWhere(
          (b) => b.id == effectiveBranchId,
          orElse: () => BranchModel(id: effectiveBranchId, code: '', name: '', isAll: false),
        );
        selected = match;
      } else if (state is DashboardLoadedState) {
        final prevSelected = (state as DashboardLoadedState).selectedBranch;
        if (prevSelected != null && !prevSelected.isAll) {
          final match = branchList.firstWhere((b) => b.id == prevSelected.id, orElse: () => branchList.first);
          selected = match;
        }
      }
      selected ??= (branchList.isNotEmpty ? branchList.first : null);

      emit(DashboardLoadedState(
        dashboardData: dashboardData,
        teamData: teamData,
        notifications: notifications,
        branches: branchList,
        selectedBranch: selected,
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
    final currentState = state is DashboardLoadedState ? state as DashboardLoadedState : null;
    emit(DashboardLoadingState());
    try {
      final role = (await PreferencesService().getUserRole())?.toLowerCase() ?? '';
      final roleLabel = (await PreferencesService().getUserRoleLabel())?.toLowerCase() ?? '';
      final isManager = role.contains('manager') || roleLabel.contains('manager');

      final isAllSelected = event.branch.id == 0 || event.branch.code.toUpperCase() == 'ALL' || event.branch.isAll;
      final effectiveMine = isManager ? 1 : (isAllSelected ? event.mine : null);
      final targetBranchId = isManager ? null : (isAllSelected ? null : (event.branch.id > 0 ? event.branch.id : null));
      final results = await Future.wait([
        _repository.getDashboardData(branchId: targetBranchId, mine: effectiveMine),
        _repository.getTeamData(branchId: targetBranchId, mine: effectiveMine),
      ]);

      final now = DateTime.now().millisecondsSinceEpoch;
      if (currentState != null) {
        emit(currentState.copyWith(
          dashboardData: results[0] as dynamic,
          teamData: results[1] as dynamic,
          selectedBranch: event.branch,
          branchChangeTimestamp: now,
        ));
      } else {
        final branchesRes = await _repository.getBranches();
        List<BranchModel> branchList = List<BranchModel>.from(branchesRes);
        if (!branchList.any((b) => b.id == 0 || b.code.toUpperCase() == 'ALL' || b.name.toLowerCase().contains('all branches'))) {
          branchList.insert(0, BranchModel(id: 0, code: 'ALL', name: 'All Branches', isAll: true));
        }
        final notifs = await _repository.getNotifications();
        final todos = await _repository.getTodos();
        emit(DashboardLoadedState(
          dashboardData: results[0] as dynamic,
          teamData: results[1] as dynamic,
          notifications: notifs,
          branches: branchList,
          selectedBranch: event.branch,
          todos: todos,
          branchChangeTimestamp: now,
        ));
      }
    } catch (e) {
      emit(DashboardErrorState(message: e.toString()));
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
