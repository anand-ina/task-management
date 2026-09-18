import 'package:equatable/equatable.dart';
import '../models/admin_role_model.dart';
import '../models/admin_permission_model.dart';

abstract class AdminRolesState extends Equatable {
  const AdminRolesState();
  @override
  List<Object?> get props => [];
}

class AdminRolesInitialState extends AdminRolesState {}
class AdminRolesLoadingState extends AdminRolesState {}

class AdminRolesLoadedState extends AdminRolesState {
  final List<AdminRoleModel> roles;
  final List<AdminPermissionModel> allPermissions;
  final int? expandedRoleId;
  /// Tracks pending permission changes: roleId -> set of checked permCodes
  final Map<int, Set<String>> pendingPermissions;

  const AdminRolesLoadedState({
    required this.roles,
    required this.allPermissions,
    this.expandedRoleId,
    this.pendingPermissions = const {},
  });

  AdminRolesLoadedState copyWith({
    List<AdminRoleModel>? roles,
    List<AdminPermissionModel>? allPermissions,
    int? expandedRoleId,
    bool clearExpanded = false,
    Map<int, Set<String>>? pendingPermissions,
  }) {
    return AdminRolesLoadedState(
      roles: roles ?? this.roles,
      allPermissions: allPermissions ?? this.allPermissions,
      expandedRoleId: clearExpanded ? null : (expandedRoleId ?? this.expandedRoleId),
      pendingPermissions: pendingPermissions ?? this.pendingPermissions,
    );
  }

  @override
  List<Object?> get props => [roles, allPermissions, expandedRoleId, pendingPermissions];
}

class AdminRolesErrorState extends AdminRolesState {
  final String message;
  const AdminRolesErrorState(this.message);
  @override
  List<Object?> get props => [message];
}
