import 'package:equatable/equatable.dart';

abstract class AdminAccessEvent extends Equatable {
  const AdminAccessEvent();

  @override
  List<Object?> get props => [];
}

class FetchAdminAccessEvent extends AdminAccessEvent {}

class ToggleBranchUsersEvent extends AdminAccessEvent {
  final int branchId;
  const ToggleBranchUsersEvent(this.branchId);

  @override
  List<Object?> get props => [branchId];
}

class ToggleDeptUsersEvent extends AdminAccessEvent {
  final int deptId;
  const ToggleDeptUsersEvent(this.deptId);

  @override
  List<Object?> get props => [deptId];
}

class AddBranchEvent extends AdminAccessEvent {
  final String code;
  final String name;
  const AddBranchEvent({required this.code, required this.name});

  @override
  List<Object?> get props => [code, name];
}

class AddDepartmentEvent extends AdminAccessEvent {
  final String name;
  const AddDepartmentEvent({required this.name});

  @override
  List<Object?> get props => [name];
}

class UpdateBranchEvent extends AdminAccessEvent {
  final int id;
  final String code;
  final String name;
  const UpdateBranchEvent({required this.id, required this.code, required this.name});

  @override
  List<Object?> get props => [id, code, name];
}

class UpdateDepartmentEvent extends AdminAccessEvent {
  final int id;
  final String name;
  const UpdateDepartmentEvent({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}
