import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../dashboard/models/branch_model.dart';
import '../models/clone_task_models.dart' hide BranchModel;
import '../models/subtask_models.dart';
import '../models/task_model.dart';
import '../repository/task_repository.dart';
import 'subtask_event.dart';
import 'subtask_state.dart';

class SubtaskBloc extends Bloc<SubtaskEvent, SubtaskState> {
  final TaskRepository _repository = TaskRepository();
  SubtaskLookupsModel? _cachedLookups;

  SubtaskLookupsModel? get cachedLookups => _cachedLookups;

  SubtaskBloc() : super(const SubtaskInitial()) {
    on<LoadSubtaskLookupsEvent>(_onLoadLookups);
    on<CreateSubtaskEvent>(_onCreateSubtask);
  }

  Future<void> _onLoadLookups(
    LoadSubtaskLookupsEvent event,
    Emitter<SubtaskState> emit,
  ) async {
    emit(const SubtaskLoading());
    try {
      final results = await Future.wait([
        _repository.getNextSubtaskId(event.parentTaskId),
        _repository.getAssigneesLookup(),
        _repository.getDraftsLookup(kind: 'task'),
        _repository.getEnumsLookup(),
        _repository.getBranches(),
      ]);

      final nextTaskNo = results[0] as String;
      final assignees = results[1] as List<AssigneeModel>;
      final drafts = results[2] as List<dynamic>;
      final enums = results[3] as Map<String, dynamic>;
      final branches = results[4] as List<BranchModel>;

      final priorities = enums['priorities'] is List ? enums['priorities'] as List<dynamic> : [];
      final statuses = enums['statuses'] is List ? enums['statuses'] as List<dynamic> : [];

      final lookups = SubtaskLookupsModel(
        nextTaskNo: nextTaskNo,
        assignees: assignees,
        drafts: drafts,
        priorities: priorities,
        statuses: statuses,
        branches: branches,
      );

      _cachedLookups = lookups;
      emit(SubtaskLookupsLoaded(lookups));
    } catch (e) {
      emit(SubtaskError(e.toString()));
    }
  }

  Future<void> _onCreateSubtask(
    CreateSubtaskEvent event,
    Emitter<SubtaskState> emit,
  ) async {
    emit(const SubtaskSubmitting());
    try {
      final result = await _repository.createSubTask(event.payload);
      if (result.isSuccess) {
        TaskItemModel? createdTask;
        if (result.data is Map<String, dynamic>) {
          try {
            createdTask = TaskItemModel.fromJson(result.data as Map<String, dynamic>);
          } catch (e) {
            debugPrint('Failed to parse created task: $e');
          }
        } else if (result.data is Map) {
          try {
            createdTask = TaskItemModel.fromJson(Map<String, dynamic>.from(result.data as Map));
          } catch (e) {
            debugPrint('Failed to parse created task: $e');
          }
        }
        emit(SubtaskSuccess(createdTask));
      } else if (result.statusCode == 403) {
        emit(SubtaskForbiddenError(
          message: result.message ?? 'Only the task creator or its assignees can add sub-tasks',
          data: result.data,
        ));
      } else {
        emit(SubtaskError(result.message ?? 'Failed to create sub-task'));
      }
    } catch (e) {
      emit(SubtaskError(e.toString()));
    }
  }
}
