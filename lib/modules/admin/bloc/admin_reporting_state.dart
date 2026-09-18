import 'package:equatable/equatable.dart';
import '../models/reporting_person_model.dart';

abstract class AdminReportingState extends Equatable {
  const AdminReportingState();
  @override
  List<Object?> get props => [];
}

class AdminReportingInitialState extends AdminReportingState {}
class AdminReportingLoadingState extends AdminReportingState {}

class AdminReportingLoadedState extends AdminReportingState {
  final List<ReportingPersonModel> people;
  const AdminReportingLoadedState({required this.people});
  @override
  List<Object?> get props => [people];
}

class AdminReportingErrorState extends AdminReportingState {
  final String message;
  const AdminReportingErrorState(this.message);
  @override
  List<Object?> get props => [message];
}
