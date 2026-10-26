import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/task_draft_model.dart';
import '../repository/task_repository.dart';

abstract class CreateTaskEvent {}

class CreateTaskSubmitEvent extends CreateTaskEvent {
  final Map<String, dynamic> payload;
  CreateTaskSubmitEvent(this.payload);
}

class SaveTaskDraftEvent extends CreateTaskEvent {
  final Map<String, dynamic> draftData;
  SaveTaskDraftEvent(this.draftData);
}

class FetchTaskDraftsEvent extends CreateTaskEvent {}

class DeleteTaskDraftEvent extends CreateTaskEvent {
  final int draftId;
  DeleteTaskDraftEvent(this.draftId);
}

abstract class CreateTaskState {}

class CreateTaskInitialState extends CreateTaskState {}

class CreateTaskSubmittingState extends CreateTaskState {}

class CreateTaskSuccessState extends CreateTaskState {
  final Map<String, dynamic> data;
  CreateTaskSuccessState(this.data);
}

class CreateTaskErrorState extends CreateTaskState {
  final String message;
  CreateTaskErrorState(this.message);
}

class DraftSavingState extends CreateTaskState {}

class DraftSavedSuccessState extends CreateTaskState {
  final int? draftId;
  DraftSavedSuccessState(this.draftId);
}

class DraftsLoadedState extends CreateTaskState {
  final List<TaskDraftModel> drafts;
  DraftsLoadedState(this.drafts);
}

class CreateTaskBloc extends Bloc<CreateTaskEvent, CreateTaskState> {
  final TaskRepository repository;

  CreateTaskBloc({required this.repository}) : super(CreateTaskInitialState()) {
    on<CreateTaskSubmitEvent>(_onSubmitTask);
    on<SaveTaskDraftEvent>(_onSaveDraft);
    on<FetchTaskDraftsEvent>(_onFetchDrafts);
    on<DeleteTaskDraftEvent>(_onDeleteDraft);
  }

  Future<void> _onSubmitTask(
    CreateTaskSubmitEvent event,
    Emitter<CreateTaskState> emit,
  ) async {
    emit(CreateTaskSubmittingState());
    try {
      final res = await repository.createTask(event.payload);
      emit(CreateTaskSuccessState(res));
    } catch (e) {
      emit(CreateTaskErrorState(e.toString()));
    }
  }

  Future<void> _onSaveDraft(
    SaveTaskDraftEvent event,
    Emitter<CreateTaskState> emit,
  ) async {
    emit(DraftSavingState());
    try {
      final draftId = await repository.saveTaskDraft(event.draftData);
      emit(DraftSavedSuccessState(draftId));
    } catch (e) {
      emit(CreateTaskErrorState(e.toString()));
    }
  }

  Future<void> _onFetchDrafts(
    FetchTaskDraftsEvent event,
    Emitter<CreateTaskState> emit,
  ) async {
    try {
      final drafts = await repository.getTaskDrafts();
      emit(DraftsLoadedState(drafts));
    } catch (e) {
      // Don't crash creation if drafts fail to load
      emit(DraftsLoadedState(const []));
    }
  }

  Future<void> _onDeleteDraft(
    DeleteTaskDraftEvent event,
    Emitter<CreateTaskState> emit,
  ) async {
    try {
      await repository.deleteTaskDraft(event.draftId);
      final drafts = await repository.getTaskDrafts();
      emit(DraftsLoadedState(drafts));
    } catch (_) {}
  }
}
