import 'package:equatable/equatable.dart';
import '../models/status_report_model.dart';

abstract class StatusReportsState extends Equatable {
  const StatusReportsState();

  @override
  List<Object?> get props => [];
}

class StatusReportsInitialState extends StatusReportsState {}

class StatusReportsLoadingState extends StatusReportsState {}

class StatusReportsLoadedState extends StatusReportsState {
  final List<StatusReportItemModel> reports;

  const StatusReportsLoadedState({required this.reports});

  @override
  List<Object?> get props => [reports];
}

class StatusReportsErrorState extends StatusReportsState {
  final String message;

  const StatusReportsErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}
