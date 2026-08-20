import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/performance_repository.dart';
import 'performance_event.dart';
import 'performance_state.dart';

class PerformanceBloc extends Bloc<PerformanceEvent, PerformanceState> {
  final PerformanceRepository repository;

  PerformanceBloc({PerformanceRepository? performanceRepository})
      : repository = performanceRepository ?? PerformanceRepository(),
        super(PerformanceInitialState()) {
    on<FetchLeaderboardEvent>(_onFetchLeaderboard);
    on<FetchTeamPerformanceEvent>(_onFetchTeamPerformance);
  }

  Future<void> _onFetchLeaderboard(
    FetchLeaderboardEvent event,
    Emitter<PerformanceState> emit,
  ) async {
    emit(PerformanceLoadingState());
    try {
      final data = await repository.getLeaderboardData();
      emit(LeaderboardLoadedState(data));
    } catch (e) {
      emit(PerformanceErrorState(e.toString()));
    }
  }

  Future<void> _onFetchTeamPerformance(
    FetchTeamPerformanceEvent event,
    Emitter<PerformanceState> emit,
  ) async {
    emit(PerformanceLoadingState());
    try {
      final data = await repository.getTeamPerformanceData();
      emit(TeamPerformanceLoadedState(data));
    } catch (e) {
      emit(PerformanceErrorState(e.toString()));
    }
  }
}
