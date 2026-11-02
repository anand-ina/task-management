import 'package:equatable/equatable.dart';
import '../models/task_approval_model.dart';
import '../models/escalation_model.dart';
import '../models/meeting_approval_model.dart';
import '../models/indent_model.dart';
import '../models/organisation_approval_model.dart';

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
  final List<IndentItemModel> indentsInbox;
  /// /indents/all for approvers (director / center head / finance / manager), else /indents/mine
  final List<IndentItemModel> indentsAll;
  final List<IndentItemModel> indentsMine;
  final IndentItemModel? selectedIndentDetail;
  final List<OrganisationApprovalModel> organisationApprovals;

  const ApprovalsLoadedState({
    this.taskApprovalsReceived = const [],
    this.taskApprovalsInitiated = const [],
    this.escalationsToReview = const [],
    this.escalations = const [],
    this.meetings = const [],
    this.meetingCompletionRequests = const [],
    this.indentsInbox = const [],
    this.indentsAll = const [],
    this.indentsMine = const [],
    this.selectedIndentDetail,
    this.organisationApprovals = const [],
  });

  ApprovalsLoadedState copyWith({
    List<TaskApprovalModel>? taskApprovalsReceived,
    List<TaskApprovalModel>? taskApprovalsInitiated,
    List<EscalationModel>? escalationsToReview,
    List<EscalationModel>? escalations,
    List<MeetingApprovalModel>? meetings,
    List<MeetingApprovalModel>? meetingCompletionRequests,
    List<IndentItemModel>? indentsInbox,
    List<IndentItemModel>? indentsAll,
    List<IndentItemModel>? indentsMine,
    IndentItemModel? selectedIndentDetail,
    List<OrganisationApprovalModel>? organisationApprovals,
  }) {
    return ApprovalsLoadedState(
      taskApprovalsReceived: taskApprovalsReceived ?? this.taskApprovalsReceived,
      taskApprovalsInitiated: taskApprovalsInitiated ?? this.taskApprovalsInitiated,
      escalationsToReview: escalationsToReview ?? this.escalationsToReview,
      escalations: escalations ?? this.escalations,
      meetings: meetings ?? this.meetings,
      meetingCompletionRequests: meetingCompletionRequests ?? this.meetingCompletionRequests,
      indentsInbox: indentsInbox ?? this.indentsInbox,
      indentsAll: indentsAll ?? this.indentsAll,
      indentsMine: indentsMine ?? this.indentsMine,
      selectedIndentDetail: selectedIndentDetail ?? this.selectedIndentDetail,
      organisationApprovals: organisationApprovals ?? this.organisationApprovals,
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
        indentsInbox,
        indentsAll,
        indentsMine,
        selectedIndentDetail,
        organisationApprovals,
      ];
}

class ApprovalsErrorState extends ApprovalsState {
  final String message;

  const ApprovalsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
