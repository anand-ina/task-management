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
}
