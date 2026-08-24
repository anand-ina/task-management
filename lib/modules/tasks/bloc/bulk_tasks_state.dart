import 'package:equatable/equatable.dart';
import '../models/bulk_task_model.dart';

abstract class BulkTasksState extends Equatable {
  const BulkTasksState();

  @override
  List<Object?> get props => [];
}

class BulkTasksInitialState extends BulkTasksState {}

class BulkTasksLoadingState extends BulkTasksState {}

class BulkTemplateLoadedState extends BulkTasksState {
  final BulkTemplateModel template;

  const BulkTemplateLoadedState({required this.template});

  @override
  List<Object?> get props => [template];
}

class BulkPreviewLoadedState extends BulkTasksState {
  final BulkTemplateModel template;
  final BulkPreviewModel preview;
  final String filePath;

  const BulkPreviewLoadedState({
    required this.template,
    required this.preview,
    required this.filePath,
  });

  @override
  List<Object?> get props => [template, preview, filePath];
}

class BulkCommitSuccessState extends BulkTasksState {
  final BulkCommitResponseModel result;

  const BulkCommitSuccessState({required this.result});

  @override
  List<Object?> get props => [result];
}

class BulkTasksErrorState extends BulkTasksState {
  final String message;

  const BulkTasksErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}
