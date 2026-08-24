import 'package:equatable/equatable.dart';

abstract class ApprovalsEvent extends Equatable {
  const ApprovalsEvent();

  @override
  List<Object?> get props => [];
}

class FetchTaskApprovalsDataEvent extends ApprovalsEvent {}

class FetchEscalationsDataEvent extends ApprovalsEvent {}

class FetchMeetingApprovalsDataEvent extends ApprovalsEvent {}

class FetchBudgetApprovalsDataEvent extends ApprovalsEvent {}

class DecideApprovalEvent extends ApprovalsEvent {
  final int id;
  final String decision; // 'approve' or 'reject'

  const DecideApprovalEvent({required this.id, required this.decision});

  @override
  List<Object?> get props => [id, decision];
}
