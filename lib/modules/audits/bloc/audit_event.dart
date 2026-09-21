import 'package:equatable/equatable.dart';

abstract class AuditEvent extends Equatable {
  const AuditEvent();

  @override
  List<Object?> get props => [];
}

class FetchAuditsEvent extends AuditEvent {
  final bool isAuditee;

  const FetchAuditsEvent({required this.isAuditee});

  @override
  List<Object?> get props => [isAuditee];
}

class ScheduleAuditEvent extends AuditEvent {
  final Map<String, dynamic> body;
  final bool isAuditee;

  const ScheduleAuditEvent({required this.body, required this.isAuditee});

  @override
  List<Object?> get props => [body, isAuditee];
}

class SelectAuditDetailEvent extends AuditEvent {
  final int id;

  const SelectAuditDetailEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class CloseAuditEvent extends AuditEvent {
  final int id;
  final bool isAuditee;

  const CloseAuditEvent({required this.id, required this.isAuditee});

  @override
  List<Object?> get props => [id, isAuditee];
}

class ClearAuditDetailEvent extends AuditEvent {}
