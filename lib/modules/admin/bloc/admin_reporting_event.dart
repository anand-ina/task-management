import 'package:equatable/equatable.dart';

abstract class AdminReportingEvent extends Equatable {
  const AdminReportingEvent();
  @override
  List<Object?> get props => [];
}

class FetchReportingEvent extends AdminReportingEvent {}

class AddManagerEvent extends AdminReportingEvent {
  final int personId;
  final int managerId;
  final bool isPrimary;

  const AddManagerEvent({
    required this.personId,
    required this.managerId,
    required this.isPrimary,
  });

  @override
  List<Object?> get props => [personId, managerId, isPrimary];
}

class RemoveManagerEvent extends AdminReportingEvent {
  final int personId;
  final int managerId;
  final bool isPrimary;

  const RemoveManagerEvent({
    required this.personId,
    required this.managerId,
    required this.isPrimary,
  });

  @override
  List<Object?> get props => [personId, managerId, isPrimary];
}

class SaveReportingEvent extends AdminReportingEvent {
  final int personId;
  const SaveReportingEvent(this.personId);

  @override
  List<Object?> get props => [personId];
}

