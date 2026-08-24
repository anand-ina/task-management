import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/reports_repository.dart';
import 'reports_event.dart';
import 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final ReportsRepository repository;

  ReportsBloc({ReportsRepository? reportsRepository})
      : repository = reportsRepository ?? ReportsRepository(),
        super(ReportsInitialState()) {
    on<FetchReportsDashboardEvent>(_onFetchReportsDashboard);
    on<FetchComplianceEvent>(_onFetchCompliance);
  }

  Future<void> _onFetchReportsDashboard(
    FetchReportsDashboardEvent event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoadingState());
    try {
      final data = await repository.getReportsDashboardData();
      emit(ReportsDashboardLoadedState(data));
    } catch (e) {
      emit(ReportsErrorState(e.toString()));
    }
  }

  Future<void> _onFetchCompliance(
    FetchComplianceEvent event,
    Emitter<ReportsState> emit,
  ) async {
    if (state is ReportsDashboardLoadedState) {
      final currentData = (state as ReportsDashboardLoadedState).data;
      try {
        final newCompliance = await repository.getCompliance(type: event.type, count: 14);
        final updatedData = ReportsDashboardData(
          reports: currentData.reports,
          stats: currentData.stats,
          compliance: newCompliance,
        );
        emit(ReportsDashboardLoadedState(updatedData));
      } catch (_) {}
    }
  }
}
