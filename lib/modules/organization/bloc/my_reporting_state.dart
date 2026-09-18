import 'package:equatable/equatable.dart';
import '../models/my_reporting_model.dart';

abstract class MyReportingState extends Equatable {
  const MyReportingState();
  @override
  List<Object?> get props => [];
}

class MyReportingInitialState extends MyReportingState {}
class MyReportingLoadingState extends MyReportingState {}

class MyReportingLoadedState extends MyReportingState {
  final MyReportingResponseModel data;
  const MyReportingLoadedState(this.data);
  @override
  List<Object?> get props => [data];
}

class MyReportingErrorState extends MyReportingState {
  final String message;
  const MyReportingErrorState(this.message);
  @override
  List<Object?> get props => [message];
}
