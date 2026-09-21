import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/task_id_settings_model.dart';
import '../repository/task_id_settings_repository.dart';
import 'task_id_settings_event.dart';
import 'task_id_settings_state.dart';

class TaskIdSettingsBloc extends Bloc<TaskIdSettingsEvent, TaskIdSettingsState> {
  final TaskIdSettingsRepository _repository;

  TaskIdSettingsBloc({TaskIdSettingsRepository? repository})
      : _repository = repository ?? TaskIdSettingsRepository(),
        super(const TaskIdSettingsInitialState()) {
    on<FetchTaskIdSettingsEvent>(_onFetch);
    on<ResetBranchCounterEvent>(_onResetBranch);
    on<ResetAllCountersEvent>(_onResetAll);
    on<UpdateBranchTicketOwnerEvent>(_onUpdateBranchOwner);
    on<UpdateFallbackTicketOwnerEvent>(_onUpdateFallbackOwner);
  }

  Future<void> _onFetch(
    FetchTaskIdSettingsEvent event,
    Emitter<TaskIdSettingsState> emit,
  ) async {
    emit(const TaskIdSettingsLoadingState());
    try {
      final results = await Future.wait([
        _repository.getTaskCounter(),
        _repository.getTicketSettings(),
        _repository.getAssignees(),
        _repository.getNotifications(),
      ]);

      emit(
        TaskIdSettingsLoadedState(
          counterData: results[0] as TaskCounterResponse,
          ticketSettings: results[1] as TicketSettingsResponse,
          assignees: results[2] as List<AssigneeLookupItem>,
        ),
      );
    } catch (e) {
      emit(TaskIdSettingsErrorState(e.toString()));
    }
  }

  Future<void> _onResetBranch(
    ResetBranchCounterEvent event,
    Emitter<TaskIdSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskIdSettingsLoadedState) return;

    final updatedResponse = await _repository.resetBranchCounter(event.branchId);
    if (updatedResponse != null) {
      emit(
        currentState.copyWith(
          counterData: updatedResponse,
          successMessage: 'Counter for ${event.branchCode} reset to 0001',
        ),
      );
    } else {
      // Optimistic local update if network succeeded with non-standard body
      final updatedBranches = currentState.counterData.branches.map((b) {
        if (b.branchId == event.branchId) {
          return b.copyWith(
            lastNo: 0,
            next: '${b.code}-0001/09-26',
            resetAt: DateTime.now().toIso8601String(),
          );
        }
        return b;
      }).toList();

      emit(
        currentState.copyWith(
          counterData: TaskCounterResponse(
            branches: updatedBranches,
            periodStart: currentState.counterData.periodStart,
            max: currentState.counterData.max,
          ),
          successMessage: 'Counter for ${event.branchCode} reset to 0001',
        ),
      );
    }
  }

  Future<void> _onResetAll(
    ResetAllCountersEvent event,
    Emitter<TaskIdSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskIdSettingsLoadedState) return;

    final updatedResponse = await _repository.resetAllCounters();
    if (updatedResponse != null) {
      emit(
        currentState.copyWith(
          counterData: updatedResponse,
          successMessage: 'All branch counters have been reset to 0001',
        ),
      );
    } else {
      final updatedBranches = currentState.counterData.branches.map((b) {
        return b.copyWith(
          lastNo: 0,
          next: '${b.code}-0001/09-26',
          resetAt: DateTime.now().toIso8601String(),
        );
      }).toList();

      emit(
        currentState.copyWith(
          counterData: TaskCounterResponse(
            branches: updatedBranches,
            periodStart: currentState.counterData.periodStart,
            max: currentState.counterData.max,
          ),
          successMessage: 'All branch counters have been reset to 0001',
        ),
      );
    }
  }

  Future<void> _onUpdateBranchOwner(
    UpdateBranchTicketOwnerEvent event,
    Emitter<TaskIdSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskIdSettingsLoadedState) return;

    final updatedSettings = await _repository.updateBranchTicketOwner(
      branchId: event.branchId,
      ownerId: event.ownerId,
    );

    if (updatedSettings != null) {
      emit(currentState.copyWith(ticketSettings: updatedSettings));
    } else {
      final assignee = currentState.assignees
          .where((a) => a.id == event.ownerId)
          .firstOrNull;
      final ownerName = assignee?.name;

      final updatedBranches = currentState.ticketSettings.branches.map((b) {
        if (b.branchId == event.branchId) {
          return b.copyWith(
            defaultOwnerId: event.ownerId,
            defaultOwnerName: ownerName,
            effectiveOwner:
                ownerName ?? currentState.ticketSettings.effectiveFallback,
          );
        }
        return b;
      }).toList();

      emit(
        currentState.copyWith(
          ticketSettings:
              currentState.ticketSettings.copyWith(branches: updatedBranches),
        ),
      );
    }
  }

  Future<void> _onUpdateFallbackOwner(
    UpdateFallbackTicketOwnerEvent event,
    Emitter<TaskIdSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskIdSettingsLoadedState) return;

    final updatedSettings =
        await _repository.updateFallbackTicketOwner(event.ownerId);

    if (updatedSettings != null) {
      emit(currentState.copyWith(ticketSettings: updatedSettings));
    } else {
      final assignee = currentState.assignees
          .where((a) => a.id == event.ownerId)
          .firstOrNull;
      final ownerName = assignee?.name ?? 'Renuka';

      emit(
        currentState.copyWith(
          ticketSettings: currentState.ticketSettings.copyWith(
            defaultOwnerId: event.ownerId,
            defaultOwnerName: assignee?.name,
            effectiveFallback: ownerName,
          ),
        ),
      );
    }
  }
}
