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

class DecideBudgetEvent extends ApprovalsEvent {
  final int id;
  final String decision; // 'approve' or 'reject'

  const DecideBudgetEvent({required this.id, required this.decision});

  @override
  List<Object?> get props => [id, decision];
}

class FetchIndentDetailEvent extends ApprovalsEvent {
  final int id;

  const FetchIndentDetailEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateIndentEvent extends ApprovalsEvent {
  final Map<String, dynamic> payload;

  const CreateIndentEvent(this.payload);

  @override
  List<Object?> get props => [payload];
}

class DecideEscalationEvent extends ApprovalsEvent {
  final int id;
  final String decision; // 'approve' or 'deny'

  const DecideEscalationEvent({required this.id, required this.decision});

  @override
  List<Object?> get props => [id, decision];
}

class DecideMeetingCompletionEvent extends ApprovalsEvent {
  final int id;
  final String decision; // 'approve' or 'send_back'

  const DecideMeetingCompletionEvent({required this.id, required this.decision});

  @override
  List<Object?> get props => [id, decision];
}

class RsvpMeetingEvent extends ApprovalsEvent {
  final int id;
  final String response; // 'accepted', 'declined', 'tentative'

  const RsvpMeetingEvent({required this.id, required this.response});

  @override
  List<Object?> get props => [id, response];
}

