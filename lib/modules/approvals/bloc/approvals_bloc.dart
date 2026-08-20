import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/approvals_repository.dart';
import 'approvals_event.dart';
import 'approvals_state.dart';

class ApprovalsBloc extends Bloc<ApprovalsEvent, ApprovalsState> {
  final ApprovalsRepository repository;

  ApprovalsBloc({ApprovalsRepository? repository})
      : repository = repository ?? ApprovalsRepository(),
        super(ApprovalsInitialState()) {
    on<FetchTaskApprovalsDataEvent>(_onFetchTaskApprovalsData);
    on<FetchEscalationsDataEvent>(_onFetchEscalationsData);
    on<FetchMeetingApprovalsDataEvent>(_onFetchMeetingApprovalsData);
    on<FetchBudgetApprovalsDataEvent>(_onFetchBudgetApprovalsData);
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
      final budgetReceived = await repository.getBudgetReceived();
      final budgetInitiated = await repository.getBudgetInitiated();

      emit(ApprovalsLoadedState(
        taskApprovalsReceived: taskApprovalsReceived,
        taskApprovalsInitiated: taskApprovalsInitiated,
        escalationsToReview: escalationsToReview,
        escalations: escalations,
        meetings: meetings,
        meetingCompletionRequests: meetingCompletionRequests,
        budgetReceived: budgetReceived,
        budgetInitiated: budgetInitiated,
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

      emit(ApprovalsLoadedState(
        taskApprovalsReceived: taskApprovalsReceived,
        escalations: escalations,
        meetings: meetings,
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
      final budgetReceived = await repository.getBudgetReceived();
      final budgetInitiated = await repository.getBudgetInitiated();

      emit(ApprovalsLoadedState(
        budgetReceived: budgetReceived,
        budgetInitiated: budgetInitiated,
      ));
    } catch (e) {
      emit(ApprovalsErrorState(e.toString()));
    }
  }
}
