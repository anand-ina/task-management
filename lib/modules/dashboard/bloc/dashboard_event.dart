import 'package:equatable/equatable.dart';
import '../models/branch_model.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class FetchDashboardDataEvent extends DashboardEvent {
  final int? branchId;
  final int? mine;
  const FetchDashboardDataEvent({this.branchId, this.mine});
  @override
  List<Object?> get props => [branchId, mine];
}

class SelectBranchEvent extends DashboardEvent {
  final BranchModel branch;
  final int? mine;
  const SelectBranchEvent(this.branch, {this.mine});
  @override
  List<Object?> get props => [branch, mine];
}

class AddTodoEvent extends DashboardEvent {
  final String text;
  const AddTodoEvent(this.text);
  @override
  List<Object?> get props => [text];
}

class ToggleTodoEvent extends DashboardEvent {
  final int index;
  final int? id;
  final bool? done;
  final int timestamp;

  ToggleTodoEvent(this.index, {this.id, this.done, int? timestamp})
      : timestamp = timestamp ?? DateTime.now().microsecondsSinceEpoch;

  @override
  List<Object?> get props => [index, id, done, timestamp];
}

class RefreshTodosEvent extends DashboardEvent {
  final int timestamp;

  RefreshTodosEvent({int? timestamp})
      : timestamp = timestamp ?? DateTime.now().microsecondsSinceEpoch;

  @override
  List<Object?> get props => [timestamp];
}
