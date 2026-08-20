import 'package:equatable/equatable.dart';
import '../models/task_approval_model.dart';
import '../models/escalation_model.dart';
import '../models/meeting_approval_model.dart';
import '../models/budget_approval_model.dart';

abstract class ApprovalsState extends Equatable {
  const ApprovalsState();

  @override
  List<Object?> get props => [];
}

class ApprovalsInitialState extends ApprovalsState {}

class ApprovalsLoadingState extends ApprovalsState {}

class ApprovalsLoadedState extends ApprovalsState {
  final List<TaskApprovalModel> taskApprovalsReceived;
  final List<TaskApprovalModel> taskApprovalsInitiated;
  final List<EscalationModel> escalationsToReview;
  final List<EscalationModel> escalations;
  final List<MeetingApprovalModel> meetings;
  final List<MeetingApprovalModel> meetingCompletionRequests;
  final List<BudgetApprovalModel> budgetReceived;
  final List<BudgetApprovalModel> budgetInitiated;

  const ApprovalsLoadedState({
    this.taskApprovalsReceived = const [],
    this.taskApprovalsInitiated = const [],
    this.escalationsToReview = const [],
    this.escalations = const [],
    this.meetings = const [],
    this.meetingCompletionRequests = const [],
    this.budgetReceived = const [],
    this.budgetInitiated = const [],
  });

  @override
  List<Object?> get props => [
        taskApprovalsReceived,
        taskApprovalsInitiated,
        escalationsToReview,
        escalations,
        meetings,
        meetingCompletionRequests,
        budgetReceived,
        budgetInitiated,
      ];
}

class ApprovalsErrorState extends ApprovalsState {
  final String message;

  const ApprovalsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
