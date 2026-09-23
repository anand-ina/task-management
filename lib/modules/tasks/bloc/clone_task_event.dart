import 'package:equatable/equatable.dart';

abstract class CloneTaskEvent extends Equatable {
  const CloneTaskEvent();

  @override
  List<Object?> get props => [];
}

/// Load all lookups (assignees, branches, enums, next-id) for a given branchId.
class LoadCloneTaskLookupsEvent extends CloneTaskEvent {
  final int? branchId;

  const LoadCloneTaskLookupsEvent({this.branchId});

  @override
  List<Object?> get props => [branchId];
}

/// Called when user changes the branch — refreshes next task ID.
class CloneTaskBranchChangedEvent extends CloneTaskEvent {
  final int branchId;

  const CloneTaskBranchChangedEvent(this.branchId);

  @override
  List<Object?> get props => [branchId];
}

/// Submit the cloned task.
class SubmitCloneTaskEvent extends CloneTaskEvent {
  final Map<String, dynamic> payload;

  const SubmitCloneTaskEvent(this.payload);

  @override
  List<Object?> get props => [payload];
}
