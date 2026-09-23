import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/clone_task_models.dart';
import '../repository/clone_task_repository.dart';
import 'clone_task_event.dart';
import 'clone_task_state.dart';

class CloneTaskBloc extends Bloc<CloneTaskEvent, CloneTaskState> {
  final CloneTaskRepository _repository = CloneTaskRepository();

  /// Holds last loaded lookups so branch change can rebuild with same data.
  CloneTaskLookupsModel? _cachedLookups;

  CloneTaskBloc() : super(const CloneTaskInitial()) {
    on<LoadCloneTaskLookupsEvent>(_onLoad);
    on<CloneTaskBranchChangedEvent>(_onBranchChanged);
    on<SubmitCloneTaskEvent>(_onSubmit);
  }

  Future<void> _onLoad(
    LoadCloneTaskLookupsEvent event,
    Emitter<CloneTaskState> emit,
  ) async {
    emit(const CloneTaskLoading());
    try {
      final lookups = await _repository.fetchAllLookups(branchId: event.branchId);
      _cachedLookups = lookups;
      emit(CloneTaskLookupsLoaded(lookups));
    } catch (e) {
      emit(CloneTaskError(e.toString()));
    }
  }

  Future<void> _onBranchChanged(
    CloneTaskBranchChangedEvent event,
    Emitter<CloneTaskState> emit,
  ) async {
    if (_cachedLookups == null) return;

    try {
      final nextId = await _repository.getNextTaskId(branchId: event.branchId);
      final updated = CloneTaskLookupsModel(
        assignees: _cachedLookups!.assignees,
        branches: _cachedLookups!.branches,
        priorities: _cachedLookups!.priorities,
        statuses: _cachedLookups!.statuses,
        nextTaskNo: nextId?.taskNo ?? _cachedLookups!.nextTaskNo,
      );
      _cachedLookups = updated;
      emit(CloneTaskNextIdUpdated(updated));
    } catch (e) {
      // Keep existing state; next-id refresh failure is non-fatal
    }
  }

  Future<void> _onSubmit(
    SubmitCloneTaskEvent event,
    Emitter<CloneTaskState> emit,
  ) async {
    emit(const CloneTaskSubmitting());
    try {
      final success = await _repository.createTask(event.payload);
      if (success) {
        emit(const CloneTaskSuccess());
      } else {
        emit(const CloneTaskError('Failed to clone task. Please try again.'));
      }
    } catch (e) {
      emit(CloneTaskError(e.toString()));
    }
  }
}
