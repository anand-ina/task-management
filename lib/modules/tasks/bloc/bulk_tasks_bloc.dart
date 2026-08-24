import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/bulk_task_model.dart';
import '../repository/bulk_task_repository.dart';
import 'bulk_tasks_event.dart';
import 'bulk_tasks_state.dart';

class BulkTasksBloc extends Bloc<BulkTasksEvent, BulkTasksState> {
  final BulkTaskRepository _repository = BulkTaskRepository();
  BulkTemplateModel? _cachedTemplate;

  BulkTasksBloc() : super(BulkTasksInitialState()) {
    on<FetchBulkTemplateEvent>(_onFetchTemplate);
    on<UploadBulkPreviewEvent>(_onUploadPreview);
    on<CommitBulkTasksEvent>(_onCommitTasks);
    on<ResetBulkUploadEvent>(_onReset);
  }

  Future<void> _onFetchTemplate(
    FetchBulkTemplateEvent event,
    Emitter<BulkTasksState> emit,
  ) async {
    emit(BulkTasksLoadingState());
    try {
      final template = await _repository.getTemplate();
      _cachedTemplate = template;
      emit(BulkTemplateLoadedState(template: template));
    } catch (e) {
      emit(BulkTasksErrorState(message: e.toString()));
    }
  }

  Future<void> _onUploadPreview(
    UploadBulkPreviewEvent event,
    Emitter<BulkTasksState> emit,
  ) async {
    final template = _cachedTemplate ?? BulkTemplateModel(columns: [], accepted: ['.xlsx', '.xls', '.csv']);
    emit(BulkTasksLoadingState());
    try {
      final preview = await _repository.uploadPreview(event.filePath);
      emit(BulkPreviewLoadedState(
        template: template,
        preview: preview,
        filePath: event.filePath,
      ));
    } catch (e) {
      emit(BulkTasksErrorState(message: e.toString()));
    }
  }

  Future<void> _onCommitTasks(
    CommitBulkTasksEvent event,
    Emitter<BulkTasksState> emit,
  ) async {
    emit(BulkTasksLoadingState());
    try {
      final result = await _repository.commitTasks(event.rows);
      emit(BulkCommitSuccessState(result: result));
    } catch (e) {
      emit(BulkTasksErrorState(message: e.toString()));
    }
  }

  void _onReset(
    ResetBulkUploadEvent event,
    Emitter<BulkTasksState> emit,
  ) {
    if (_cachedTemplate != null) {
      emit(BulkTemplateLoadedState(template: _cachedTemplate!));
    } else {
      emit(BulkTasksInitialState());
    }
  }
}
