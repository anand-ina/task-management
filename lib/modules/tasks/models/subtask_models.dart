import '../../dashboard/models/branch_model.dart';
import 'clone_task_models.dart' hide BranchModel;

class SubtaskCreateResult {
  final bool isSuccess;
  final int? statusCode;
  final String? message;
  final dynamic data;

  const SubtaskCreateResult({
    required this.isSuccess,
    this.statusCode,
    this.message,
    this.data,
  });
}

class SubtaskLookupsModel {
  final String nextTaskNo;
  final List<AssigneeModel> assignees;
  final List<dynamic> drafts;
  final List<dynamic> priorities;
  final List<dynamic> statuses;
  final List<BranchModel> branches;

  const SubtaskLookupsModel({
    required this.nextTaskNo,
    required this.assignees,
    required this.drafts,
    required this.priorities,
    required this.statuses,
    required this.branches,
  });
}
