import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/admin_branch_model.dart';
import '../models/admin_department_model.dart';
import '../repository/admin_access_repository.dart';
import 'admin_access_event.dart';
import 'admin_access_state.dart';

class AdminAccessBloc extends Bloc<AdminAccessEvent, AdminAccessState> {
  final AdminAccessRepository _repository = AdminAccessRepository();

  AdminAccessBloc() : super(AdminAccessInitialState()) {
    on<FetchAdminAccessEvent>(_onFetchAdminAccess);
    on<ToggleBranchUsersEvent>(_onToggleBranchUsers);
    on<ToggleDeptUsersEvent>(_onToggleDeptUsers);
    on<AddBranchEvent>(_onAddBranch);
    on<AddDepartmentEvent>(_onAddDepartment);
    on<UpdateBranchEvent>(_onUpdateBranch);
    on<UpdateDepartmentEvent>(_onUpdateDepartment);
  }

  Future<void> _onFetchAdminAccess(
    FetchAdminAccessEvent event,
    Emitter<AdminAccessState> emit,
  ) async {
    emit(AdminAccessLoadingState());
    try {
      final results = await Future.wait([
        _repository.getBranches(),
        _repository.getDepartments(),
      ]);
      final branches = results[0] as List<AdminBranchModel>;
      final departments = results[1] as List<AdminDepartmentModel>;

      emit(AdminAccessLoadedState(
        branches: branches,
        departments: departments,
      ));
    } catch (e) {
      emit(AdminAccessErrorState(e.toString()));
    }
  }

  Future<void> _onToggleBranchUsers(
    ToggleBranchUsersEvent event,
    Emitter<AdminAccessState> emit,
  ) async {
    if (state is! AdminAccessLoadedState) return;
    final currentState = state as AdminAccessLoadedState;

    if (currentState.expandedBranchId == event.branchId) {
      emit(currentState.copyWith(clearExpandedBranch: true, branchUsers: []));
      return;
    }

    emit(currentState.copyWith(
      expandedBranchId: event.branchId,
      loadingBranchUsers: true,
      branchUsers: [],
    ));

    try {
      final users = await _repository.getBranchUsers(event.branchId);
      emit((state as AdminAccessLoadedState).copyWith(
        branchUsers: users,
        loadingBranchUsers: false,
      ));
    } catch (_) {
      emit((state as AdminAccessLoadedState).copyWith(
        loadingBranchUsers: false,
      ));
    }
  }

  Future<void> _onToggleDeptUsers(
    ToggleDeptUsersEvent event,
    Emitter<AdminAccessState> emit,
  ) async {
    if (state is! AdminAccessLoadedState) return;
    final currentState = state as AdminAccessLoadedState;

    if (currentState.expandedDeptId == event.deptId) {
      emit(currentState.copyWith(clearExpandedDept: true, deptUsers: []));
      return;
    }

    emit(currentState.copyWith(
      expandedDeptId: event.deptId,
      loadingDeptUsers: true,
      deptUsers: [],
    ));

    try {
      final users = await _repository.getDeptUsers(event.deptId);
      emit((state as AdminAccessLoadedState).copyWith(
        deptUsers: users,
        loadingDeptUsers: false,
      ));
    } catch (_) {
      emit((state as AdminAccessLoadedState).copyWith(
        loadingDeptUsers: false,
      ));
    }
  }

  Future<void> _onAddBranch(
    AddBranchEvent event,
    Emitter<AdminAccessState> emit,
  ) async {
    if (state is! AdminAccessLoadedState) return;
    final currentState = state as AdminAccessLoadedState;

    final newId = await _repository.createBranch(code: event.code, name: event.name);

    final newBranch = AdminBranchModel(
      id: newId ?? (currentState.branches.length + 1),
      code: event.code,
      name: event.name,
      isAll: false,
      users: 0,
    );

    final updated = List<AdminBranchModel>.from(currentState.branches)..add(newBranch);
    emit(currentState.copyWith(branches: updated));
  }

  Future<void> _onAddDepartment(
    AddDepartmentEvent event,
    Emitter<AdminAccessState> emit,
  ) async {
    if (state is! AdminAccessLoadedState) return;
    final currentState = state as AdminAccessLoadedState;

    final newId = await _repository.createDepartment(name: event.name);

    final newDept = AdminDepartmentModel(
      id: newId ?? (currentState.departments.length + 1),
      name: event.name,
      users: 0,
    );

    final updated = List<AdminDepartmentModel>.from(currentState.departments)..add(newDept);
    emit(currentState.copyWith(departments: updated));
  }

  Future<void> _onUpdateBranch(
    UpdateBranchEvent event,
    Emitter<AdminAccessState> emit,
  ) async {
    if (state is! AdminAccessLoadedState) return;
    final currentState = state as AdminAccessLoadedState;
    debugPrint('[AdminAccessBloc] UpdateBranch id=${event.id} code=${event.code} name=${event.name}');
    final updated = currentState.branches.map((b) {
      if (b.id == event.id) {
        return AdminBranchModel(id: b.id, code: event.code, name: event.name, isAll: b.isAll, users: b.users);
      }
      return b;
    }).toList();
    emit(currentState.copyWith(branches: updated));

    await _repository.updateBranch(id: event.id, code: event.code, name: event.name);
  }

  Future<void> _onUpdateDepartment(
    UpdateDepartmentEvent event,
    Emitter<AdminAccessState> emit,
  ) async {
    if (state is! AdminAccessLoadedState) return;
    final currentState = state as AdminAccessLoadedState;
    debugPrint('[AdminAccessBloc] UpdateDepartment id=${event.id} name=${event.name}');
    final updated = currentState.departments.map((d) {
      if (d.id == event.id) {
        return AdminDepartmentModel(id: d.id, name: event.name, users: d.users);
      }
      return d;
    }).toList();
    emit(currentState.copyWith(departments: updated));

    await _repository.updateDepartment(id: event.id, name: event.name);
  }
}

