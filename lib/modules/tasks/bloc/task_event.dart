import 'package:equatable/equatable.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class FetchPeriodTasksEvent extends TaskEvent {
  final String period;
  final String scope;
  final String sort;
  final String dir;

  const FetchPeriodTasksEvent({
    this.period = 'day',
    this.scope = 'all',
    this.sort = 'entry',
    this.dir = 'desc',
  });

  @override
  List<Object?> get props => [period, scope, sort, dir];
}

class FetchTaskDetailEvent extends TaskEvent {
  final int taskId;

  const FetchTaskDetailEvent(this.taskId);

  @override
  List<Object?> get props => [taskId];
}
