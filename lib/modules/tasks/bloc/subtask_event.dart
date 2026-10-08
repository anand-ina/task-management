import 'package:equatable/equatable.dart';

abstract class SubtaskEvent extends Equatable {
  const SubtaskEvent();

  @override
  List<Object?> get props => [];
}

class LoadSubtaskLookupsEvent extends SubtaskEvent {
  final int parentTaskId;
  final int? branchId;

  const LoadSubtaskLookupsEvent({
    required this.parentTaskId,
    this.branchId,
  });

  @override
  List<Object?> get props => [parentTaskId, branchId];
}

class CreateSubtaskEvent extends SubtaskEvent {
  final Map<String, dynamic> payload;

  const CreateSubtaskEvent(this.payload);

  @override
  List<Object?> get props => [payload];
}
