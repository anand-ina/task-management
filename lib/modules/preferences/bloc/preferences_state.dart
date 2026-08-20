import '../repository/preferences_repository.dart';

abstract class PreferencesState {}

class PreferencesInitialState extends PreferencesState {}

class PreferencesLoadingState extends PreferencesState {}

class PreferencesLoadedState extends PreferencesState {
  final PreferencesOverviewData data;
  PreferencesLoadedState({required this.data});
}

class PreferencesErrorState extends PreferencesState {
  final String message;
  PreferencesErrorState({required this.message});
}
