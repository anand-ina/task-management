import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/reports_repository.dart';
import 'status_reports_event.dart';
import 'status_reports_state.dart';

class StatusReportsBloc extends Bloc<StatusReportsEvent, StatusReportsState> {
  final ReportsRepository repository;

  StatusReportsBloc({ReportsRepository? reportsRepository})
      : repository = reportsRepository ?? ReportsRepository(),
        super(StatusReportsInitialState()) {
    on<FetchStatusReportsEvent>(_onFetchStatusReports);
  }

  Future<void> _onFetchStatusReports(
    FetchStatusReportsEvent event,
    Emitter<StatusReportsState> emit,
  ) async {
    emit(StatusReportsLoadingState());
    try {
      final reports = await repository.getReports();
      emit(StatusReportsLoadedState(reports: reports));
    } catch (e) {
      emit(StatusReportsErrorState(message: e.toString()));
    }
  }
}
