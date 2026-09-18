import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/admin_role_model.dart';
import '../repository/admin_roles_repository.dart';
import 'admin_roles_event.dart';
import 'admin_roles_state.dart';

class AdminRolesBloc extends Bloc<AdminRolesEvent, AdminRolesState> {
  final AdminRolesRepository _repository = AdminRolesRepository();

  AdminRolesBloc() : super(AdminRolesInitialState()) {
    on<FetchRolesEvent>(_onFetch);
    on<ToggleRoleExpandEvent>(_onToggleExpand);
    on<TogglePermissionEvent>(_onTogglePermission);
    on<SaveRolePermissionsEvent>(_onSavePermissions);
    on<AddRoleEvent>(_onAddRole);
  }

  Future<void> _onFetch(FetchRolesEvent event, Emitter<AdminRolesState> emit) async {
    emit(AdminRolesLoadingState());
    try {
      final roles = await _repository.getRoles();
      final allPermissions = await _repository.getPermissions();
      emit(AdminRolesLoadedState(
        roles: roles,
        allPermissions: allPermissions,
      ));
    } catch (e) {
      emit(AdminRolesErrorState(e.toString()));
    }
  }

  void _onToggleExpand(ToggleRoleExpandEvent event, Emitter<AdminRolesState> emit) {
    if (state is! AdminRolesLoadedState) return;
    final s = state as AdminRolesLoadedState;
    if (s.expandedRoleId == event.roleId) {
      emit(s.copyWith(clearExpanded: true));
    } else {
      // initialise pending perms from current role
      final role = s.roles.firstWhere((r) => r.id == event.roleId, orElse: () => AdminRoleModel(id: event.roleId, name: '', label: '', level: 5, permissions: [], users: 0));
      final pending = Map<int, Set<String>>.from(s.pendingPermissions);
      pending[event.roleId] = Set<String>.from(role.permissions);
      emit(s.copyWith(expandedRoleId: event.roleId, pendingPermissions: pending));
    }
  }

  void _onTogglePermission(TogglePermissionEvent event, Emitter<AdminRolesState> emit) {
    if (state is! AdminRolesLoadedState) return;
    final s = state as AdminRolesLoadedState;
    final pending = Map<int, Set<String>>.from(s.pendingPermissions);
    final set = Set<String>.from(pending[event.roleId] ?? {});
    if (set.contains(event.permCode)) {
      set.remove(event.permCode);
    } else {
      set.add(event.permCode);
    }
    pending[event.roleId] = set;
    emit(s.copyWith(pendingPermissions: pending));
  }

  void _onSavePermissions(SaveRolePermissionsEvent event, Emitter<AdminRolesState> emit) {
    if (state is! AdminRolesLoadedState) return;
    final s = state as AdminRolesLoadedState;
    debugPrint('[AdminRolesBloc] SavePermissions roleId=${event.roleId} perms=${event.permissions}');
    final roles = s.roles.map((r) {
      if (r.id == event.roleId) {
        return AdminRoleModel(id: r.id, name: r.name, label: r.label, level: r.level, permissions: event.permissions, users: r.users);
      }
      return r;
    }).toList();
    emit(s.copyWith(roles: roles, clearExpanded: true));
  }

  Future<void> _onAddRole(AddRoleEvent event, Emitter<AdminRolesState> emit) async {
    if (state is! AdminRolesLoadedState) return;
    final s = state as AdminRolesLoadedState;
    debugPrint('[AdminRolesBloc] AddRole label=${event.label} name=${event.name} level=${event.level}');

    final newId = await _repository.createRole(
      name: event.name,
      label: event.label,
      level: event.level,
    );

    final newRole = AdminRoleModel(
      id: newId ?? (s.roles.length + 100),
      name: event.name,
      label: event.label,
      level: event.level,
      permissions: [],
      users: 0,
    );
    emit(s.copyWith(roles: [...s.roles, newRole]));
  }
}
