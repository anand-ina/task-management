import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/approvals_repository.dart';
import 'approvals_event.dart';
import 'approvals_state.dart';

class ApprovalsBloc extends Bloc<ApprovalsEvent, ApprovalsState> {
  final ApprovalsRepository repository;
  bool _lastIndentCanViewAll = false;

  ApprovalsBloc({ApprovalsRepository? repository})
      : repository = repository ?? ApprovalsRepository(),
        super(ApprovalsInitialState()) {
    on<FetchTaskApprovalsDataEvent>(_onFetchTaskApprovalsData);
    on<FetchOrganisationApprovalsEvent>(_onFetchOrganisationApprovals);
    on<FetchEscalationsDataEvent>(_onFetchEscalationsData);
    on<FetchMeetingApprovalsDataEvent>(_onFetchMeetingApprovalsData);
    on<FetchBudgetApprovalsDataEvent>(_onFetchBudgetApprovalsData);
    on<FetchIndentDetailEvent>(_onFetchIndentDetail);
    on<DecideApprovalEvent>(_onDecideApproval);
    on<CreateIndentEvent>(_onCreateIndent);
    on<DecideEscalationEvent>(_onDecideEscalation);
    on<DecideMeetingCompletionEvent>(_onDecideMeetingCompletion);
    on<RsvpMeetingEvent>(_onRsvpMeeting);
  }

  Future<void> _onFetchTaskApprovalsData(
    FetchTaskApprovalsDataEvent event,
    Emitter<ApprovalsState> emit,
  ) async {
    emit(ApprovalsLoadingState());
    try {
      final taskApprovalsReceived = await repository.getApprovals();
      final taskApprovalsInitiated = await repository.getApprovalsInitiated();
      final escalationsToReview = await repository.getEscalationsToReview();
      final escalations = await repository.getEscalations();
      final meetings = await repository.getMeetings();
      final meetingCompletionRequests = await repository.getMeetingCompletionRequests();

      emit(ApprovalsLoadedState(
        taskApprovalsReceived: taskApprovalsReceived,
        taskApprovalsInitiated: taskApprovalsInitiated,
        escalationsToReview: escalationsToReview,
        escalations: escalations,
        meetings: meetings,
        meetingCompletionRequests: meetingCompletionRequests,
      ));
    } catch (e) {
      emit(ApprovalsErrorState(e.toString()));
    }
  }

  Future<void> _onFetchEscalationsData(
    FetchEscalationsDataEvent event,
    Emitter<ApprovalsState> emit,
  ) async {
    emit(ApprovalsLoadingState());
    try {
      final escalations = await repository.getEscalations();
      final taskApprovalsInitiated = await repository.getApprovalsInitiated();
      final escalationsToReview = await repository.getEscalationsToReview();
      final meetings = await repository.getMeetings();

      emit(ApprovalsLoadedState(
        escalations: escalations,
        taskApprovalsInitiated: taskApprovalsInitiated,
        escalationsToReview: escalationsToReview,
        meetings: meetings,
      ));
    } catch (e) {
      emit(ApprovalsErrorState(e.toString()));
    }
  }

  Future<void> _onFetchMeetingApprovalsData(
    FetchMeetingApprovalsDataEvent event,
    Emitter<ApprovalsState> emit,
  ) async {
    emit(ApprovalsLoadingState());
    try {
      final taskApprovalsReceived = await repository.getApprovals();
      final escalations = await repository.getEscalations();
      final meetings = await repository.getMeetings();
      final meetingCompletionRequests = await repository.getMeetingCompletionRequests();

      emit(ApprovalsLoadedState(
        taskApprovalsReceived: taskApprovalsReceived,
        escalations: escalations,
        meetings: meetings,
        meetingCompletionRequests: meetingCompletionRequests,
      ));
    } catch (e) {
      emit(ApprovalsErrorState(e.toString()));
    }
  }

  Future<void> _onFetchBudgetApprovalsData(
    FetchBudgetApprovalsDataEvent event,
    Emitter<ApprovalsState> emit,
  ) async {
    emit(ApprovalsLoadingState());
    try {
      final canViewAll = event.canViewAll ?? _lastIndentCanViewAll;
      _lastIndentCanViewAll = canViewAll;
      final results = await Future.wait([
        repository.getIndentsInbox(),
        canViewAll ? repository.getIndentsAll() : repository.getIndentsMine(),
        repository.getIndentsMine(),
      ]);

      emit(ApprovalsLoadedState(
        indentsInbox: results[0],
        indentsAll: results[1],
        indentsMine: results[2],
      ));
    } catch (e) {
      emit(ApprovalsErrorState(e.toString()));
    }
  }

  Future<void> _onFetchIndentDetail(
    FetchIndentDetailEvent event,
    Emitter<ApprovalsState> emit,
  ) async {
    try {
      final detail = await repository.getIndentDetail(event.id);
      if (state is ApprovalsLoadedState) {
        emit((state as ApprovalsLoadedState).copyWith(selectedIndentDetail: detail));
      }
    } catch (e) {
      debugPrint('[ApprovalsBloc] _onFetchIndentDetail error: $e');
    }
  }

  Future<void> _onDecideApproval(
    DecideApprovalEvent event,
    Emitter<ApprovalsState> emit,
  ) async {
    await repository.decideApproval(event.id, event.decision);
    add(FetchTaskApprovalsDataEvent());
  }

  Future<void> _onCreateIndent(
    CreateIndentEvent event,
    Emitter<ApprovalsState> emit,
  ) async {
    try {
      await repository.createIndent(event.payload);
      add(const FetchBudgetApprovalsDataEvent());
    } catch (e) {
      debugPrint('[ApprovalsBloc] _onCreateIndent error: $e');
      rethrow;
    }
  }

  Future<void> _onDecideEscalation(
    DecideEscalationEvent event,
    Emitter<ApprovalsState> emit,
  ) async {
    await repository.decideEscalation(event.id, event.decision);
    add(FetchEscalationsDataEvent());
  }

  Future<void> _onDecideMeetingCompletion(
    DecideMeetingCompletionEvent event,
    Emitter<ApprovalsState> emit,
  ) async {
    await repository.decideMeetingCompletion(event.id, event.decision);
    add(FetchMeetingApprovalsDataEvent());
  }

  Future<void> _onRsvpMeeting(
    RsvpMeetingEvent event,
    Emitter<ApprovalsState> emit,
  ) async {
    await repository.rsvpMeeting(event.id, event.response);
    add(FetchMeetingApprovalsDataEvent());
  }

  Future<void> _onFetchOrganisationApprovals(
    FetchOrganisationApprovalsEvent event,
    Emitter<ApprovalsState> emit,
  ) async {
    emit(ApprovalsLoadingState());
    try {
      final list = await repository.getOrganisationApprovals();
      if (state is ApprovalsLoadedState) {
        emit((state as ApprovalsLoadedState).copyWith(organisationApprovals: list));
      } else {
        emit(ApprovalsLoadedState(organisationApprovals: list));
      }
    } catch (e) {
      emit(ApprovalsErrorState(e.toString()));
    }
  }
}
