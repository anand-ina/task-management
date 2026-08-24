import 'package:equatable/equatable.dart';
import '../models/bulk_task_model.dart';

abstract class BulkTasksEvent extends Equatable {
  const BulkTasksEvent();

  @override
  List<Object?> get props => [];
}

class FetchBulkTemplateEvent extends BulkTasksEvent {}

class UploadBulkPreviewEvent extends BulkTasksEvent {
  final String filePath;

  const UploadBulkPreviewEvent({required this.filePath});

  @override
  List<Object?> get props => [filePath];
}

class CommitBulkTasksEvent extends BulkTasksEvent {
  final List<BulkRowModel> rows;

  const CommitBulkTasksEvent({required this.rows});

  @override
  List<Object?> get props => [rows];
}

class ResetBulkUploadEvent extends BulkTasksEvent {}
