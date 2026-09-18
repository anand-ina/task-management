import 'package:equatable/equatable.dart';
import '../models/responsibility_model.dart';

abstract class ResponsibilitiesState extends Equatable {
  const ResponsibilitiesState();
  @override
  List<Object?> get props => [];
}

class ResponsibilitiesInitialState extends ResponsibilitiesState {}
class ResponsibilitiesLoadingState extends ResponsibilitiesState {}

class ResponsibilitiesLoadedState extends ResponsibilitiesState {
  final ResponsibilitiesResponseModel data;
  const ResponsibilitiesLoadedState(this.data);
  @override
  List<Object?> get props => [data];
}

class ResponsibilitiesErrorState extends ResponsibilitiesState {
  final String message;
  const ResponsibilitiesErrorState(this.message);
  @override
  List<Object?> get props => [message];
}
