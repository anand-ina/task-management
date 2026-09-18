import 'package:equatable/equatable.dart';

abstract class AdminAuditEvent extends Equatable {
  const AdminAuditEvent();
  @override
  List<Object?> get props => [];
}

class FetchAuditLogsEvent extends AdminAuditEvent {}

class FilterAuditLogsEvent extends AdminAuditEvent {
  final String actionFilter;
  const FilterAuditLogsEvent(this.actionFilter);
  @override
  List<Object?> get props => [actionFilter];
}
