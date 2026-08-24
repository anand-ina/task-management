import 'package:equatable/equatable.dart';

abstract class StatusReportsEvent extends Equatable {
  const StatusReportsEvent();

  @override
  List<Object?> get props => [];
}

class FetchStatusReportsEvent extends StatusReportsEvent {}
