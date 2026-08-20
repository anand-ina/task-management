import '../models/team_performance_model.dart';
import '../repository/performance_repository.dart';

abstract class PerformanceState {}

class PerformanceInitialState extends PerformanceState {}

class PerformanceLoadingState extends PerformanceState {}

class LeaderboardLoadedState extends PerformanceState {
  final LeaderboardDashboardData data;
  LeaderboardLoadedState(this.data);
}

class TeamPerformanceLoadedState extends PerformanceState {
  final TeamPerformanceModel data;
  TeamPerformanceLoadedState(this.data);
}

class PerformanceErrorState extends PerformanceState {
  final String message;
  PerformanceErrorState(this.message);
}
