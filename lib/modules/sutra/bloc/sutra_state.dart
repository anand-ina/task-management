import '../repository/sutra_repository.dart';

abstract class SutraState {}

class SutraInitialState extends SutraState {}

class SutraLoadingState extends SutraState {}

class SutraLoadedState extends SutraState {
  final SutraDashboardData data;
  SutraLoadedState({required this.data});
}

class SutraErrorState extends SutraState {
  final String message;
  SutraErrorState({required this.message});
}
