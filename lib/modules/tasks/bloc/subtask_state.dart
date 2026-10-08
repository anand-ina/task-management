import 'package:equatable/equatable.dart';
import '../models/subtask_models.dart';
import '../models/task_model.dart';

abstract class SubtaskState extends Equatable {
  const SubtaskState();

  @override
  List<Object?> get props => [];
}

class SubtaskInitial extends SubtaskState {
  const SubtaskInitial();
}

class SubtaskLoading extends SubtaskState {
  const SubtaskLoading();
}

class SubtaskLookupsLoaded extends SubtaskState {
  final SubtaskLookupsModel lookups;

  const SubtaskLookupsLoaded(this.lookups);

  @override
  List<Object?> get props => [lookups];
}

class SubtaskSubmitting extends SubtaskState {
  const SubtaskSubmitting();
}

class SubtaskSuccess extends SubtaskState {
  final TaskItemModel? createdTask;

  const SubtaskSuccess([this.createdTask]);

  @override
  List<Object?> get props => [createdTask];
}

class SubtaskForbiddenError extends SubtaskState {
  final String message;
  final dynamic data;

  const SubtaskForbiddenError({
    required this.message,
    this.data,
  });

  @override
  List<Object?> get props => [message, data];
}

class SubtaskError extends SubtaskState {
  final String message;

  const SubtaskError(this.message);

  @override
  List<Object?> get props => [message];
}
