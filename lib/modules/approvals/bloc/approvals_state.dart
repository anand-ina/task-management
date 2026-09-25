import 'package:equatable/equatable.dart';
import '../models/task_approval_model.dart';
import '../models/escalation_model.dart';
import '../models/meeting_approval_model.dart';
import '../models/budget_approval_model.dart';
import '../models/indent_model.dart';

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
  final List<IndentItemModel> indentsInbox;
  final List<IndentItemModel> indentsAll;
  final IndentItemModel? selectedIndentDetail;

  const ApprovalsLoadedState({
    this.taskApprovalsReceived = const [],
    this.taskApprovalsInitiated = const [],
    this.escalationsToReview = const [],
    this.escalations = const [],
    this.meetings = const [],
    this.meetingCompletionRequests = const [],
    this.budgetReceived = const [],
    this.budgetInitiated = const [],
    this.indentsInbox = const [],
    this.indentsAll = const [],
    this.selectedIndentDetail,
  });

  ApprovalsLoadedState copyWith({
    List<TaskApprovalModel>? taskApprovalsReceived,
    List<TaskApprovalModel>? taskApprovalsInitiated,
    List<EscalationModel>? escalationsToReview,
    List<EscalationModel>? escalations,
    List<MeetingApprovalModel>? meetings,
    List<MeetingApprovalModel>? meetingCompletionRequests,
    List<BudgetApprovalModel>? budgetReceived,
    List<BudgetApprovalModel>? budgetInitiated,
    List<IndentItemModel>? indentsInbox,
    List<IndentItemModel>? indentsAll,
    IndentItemModel? selectedIndentDetail,
  }) {
    return ApprovalsLoadedState(
      taskApprovalsReceived: taskApprovalsReceived ?? this.taskApprovalsReceived,
      taskApprovalsInitiated: taskApprovalsInitiated ?? this.taskApprovalsInitiated,
      escalationsToReview: escalationsToReview ?? this.escalationsToReview,
      escalations: escalations ?? this.escalations,
      meetings: meetings ?? this.meetings,
      meetingCompletionRequests: meetingCompletionRequests ?? this.meetingCompletionRequests,
      budgetReceived: budgetReceived ?? this.budgetReceived,
      budgetInitiated: budgetInitiated ?? this.budgetInitiated,
      indentsInbox: indentsInbox ?? this.indentsInbox,
      indentsAll: indentsAll ?? this.indentsAll,
      selectedIndentDetail: selectedIndentDetail ?? this.selectedIndentDetail,
    );
  }

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
        indentsInbox,
        indentsAll,
        selectedIndentDetail,
      ];
}

class ApprovalsErrorState extends ApprovalsState {
  final String message;

  const ApprovalsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
