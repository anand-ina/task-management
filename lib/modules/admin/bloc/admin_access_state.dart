import 'package:equatable/equatable.dart';
import '../models/admin_branch_model.dart';
import '../models/admin_branch_user_model.dart';
import '../models/admin_department_model.dart';
import '../models/admin_dept_user_model.dart';

abstract class AdminAccessState extends Equatable {
  const AdminAccessState();

  @override
  List<Object?> get props => [];
}

class AdminAccessInitialState extends AdminAccessState {}

class AdminAccessLoadingState extends AdminAccessState {}

class AdminAccessLoadedState extends AdminAccessState {
  final List<AdminBranchModel> branches;
  final List<AdminDepartmentModel> departments;
  final int? expandedBranchId;
  final List<AdminBranchUserModel> branchUsers;
  final bool loadingBranchUsers;
  final int? expandedDeptId;
  final List<AdminDeptUserModel> deptUsers;
  final bool loadingDeptUsers;

  const AdminAccessLoadedState({
    required this.branches,
    required this.departments,
    this.expandedBranchId,
    this.branchUsers = const [],
    this.loadingBranchUsers = false,
    this.expandedDeptId,
    this.deptUsers = const [],
    this.loadingDeptUsers = false,
  });

  AdminAccessLoadedState copyWith({
    List<AdminBranchModel>? branches,
    List<AdminDepartmentModel>? departments,
    int? expandedBranchId,
    bool clearExpandedBranch = false,
    List<AdminBranchUserModel>? branchUsers,
    bool? loadingBranchUsers,
    int? expandedDeptId,
    bool clearExpandedDept = false,
    List<AdminDeptUserModel>? deptUsers,
    bool? loadingDeptUsers,
  }) {
    return AdminAccessLoadedState(
      branches: branches ?? this.branches,
      departments: departments ?? this.departments,
      expandedBranchId: clearExpandedBranch
          ? null
          : (expandedBranchId ?? this.expandedBranchId),
      branchUsers: branchUsers ?? this.branchUsers,
      loadingBranchUsers: loadingBranchUsers ?? this.loadingBranchUsers,
      expandedDeptId: clearExpandedDept
          ? null
          : (expandedDeptId ?? this.expandedDeptId),
      deptUsers: deptUsers ?? this.deptUsers,
      loadingDeptUsers: loadingDeptUsers ?? this.loadingDeptUsers,
    );
  }

  @override
  List<Object?> get props => [
        branches,
        departments,
        expandedBranchId,
        branchUsers,
        loadingBranchUsers,
        expandedDeptId,
        deptUsers,
        loadingDeptUsers,
      ];
}

class AdminAccessErrorState extends AdminAccessState {
  final String message;
  const AdminAccessErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
