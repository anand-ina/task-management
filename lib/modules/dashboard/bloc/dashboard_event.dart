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
  const SelectBranchEvent(this.branch);
  @override
  List<Object?> get props => [branch];
}

class AddTodoEvent extends DashboardEvent {
  final String text;
  const AddTodoEvent(this.text);
  @override
  List<Object?> get props => [text];
}

class ToggleTodoEvent extends DashboardEvent {
  final int index;
  const ToggleTodoEvent(this.index);
  @override
  List<Object?> get props => [index];
}
