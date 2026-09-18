import 'package:equatable/equatable.dart';

abstract class MyReportingEvent extends Equatable {
  const MyReportingEvent();
  @override
  List<Object?> get props => [];
}

class FetchMyReportingEvent extends MyReportingEvent {}
