import 'package:equatable/equatable.dart';
import '../models/clone_task_models.dart';

abstract class CloneTaskState extends Equatable {
  const CloneTaskState();

  @override
  List<Object?> get props => [];
}

class CloneTaskInitial extends CloneTaskState {
  const CloneTaskInitial();
}

class CloneTaskLoading extends CloneTaskState {
  const CloneTaskLoading();
}

class CloneTaskLookupsLoaded extends CloneTaskState {
  final CloneTaskLookupsModel lookups;

  const CloneTaskLookupsLoaded(this.lookups);

  @override
  List<Object?> get props => [lookups];
}

/// Emitted when only the next task ID changes (branch switch).
class CloneTaskNextIdUpdated extends CloneTaskState {
  final CloneTaskLookupsModel lookups;

  const CloneTaskNextIdUpdated(this.lookups);

  @override
  List<Object?> get props => [lookups];
}

class CloneTaskSubmitting extends CloneTaskState {
  const CloneTaskSubmitting();
}

class CloneTaskSuccess extends CloneTaskState {
  const CloneTaskSuccess();
}

class CloneTaskError extends CloneTaskState {
  final String message;

  const CloneTaskError(this.message);

  @override
  List<Object?> get props => [message];
}
