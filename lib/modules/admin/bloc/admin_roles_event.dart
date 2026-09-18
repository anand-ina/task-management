import 'package:equatable/equatable.dart';

abstract class AdminRolesEvent extends Equatable {
  const AdminRolesEvent();
  @override
  List<Object?> get props => [];
}

class FetchRolesEvent extends AdminRolesEvent {}

class ToggleRoleExpandEvent extends AdminRolesEvent {
  final int roleId;
  const ToggleRoleExpandEvent(this.roleId);
  @override
  List<Object?> get props => [roleId];
}

class TogglePermissionEvent extends AdminRolesEvent {
  final int roleId;
  final String permCode;
  const TogglePermissionEvent({required this.roleId, required this.permCode});
  @override
  List<Object?> get props => [roleId, permCode];
}

class SaveRolePermissionsEvent extends AdminRolesEvent {
  final int roleId;
  final List<String> permissions;
  const SaveRolePermissionsEvent({required this.roleId, required this.permissions});
  @override
  List<Object?> get props => [roleId, permissions];
}

class AddRoleEvent extends AdminRolesEvent {
  final String label;
  final String name;
  final int level;
  const AddRoleEvent({required this.label, required this.name, required this.level});
  @override
  List<Object?> get props => [label, name, level];
}
