import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class FetchDashboardDataEvent extends DashboardEvent {}

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
