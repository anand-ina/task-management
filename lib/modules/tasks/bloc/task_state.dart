import 'package:equatable/equatable.dart';
import '../../dashboard/models/branch_model.dart';
import '../models/task_model.dart';

abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskInitialState extends TaskState {}

class TasksLoadingState extends TaskState {}

class TasksLoadedState extends TaskState {
  final List<BranchModel> branches;
  final TasksResponseModel response;

  const TasksLoadedState({
    required this.branches,
    required this.response,
  });

  @override
  List<Object?> get props => [branches, response];
}

class TaskDetailLoadingState extends TaskState {}

class TaskDetailLoadedState extends TaskState {
  final TaskDetailModel detail;

  const TaskDetailLoadedState(this.detail);

  @override
  List<Object?> get props => [detail];
}

class TaskErrorState extends TaskState {
  final String message;

  const TaskErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
