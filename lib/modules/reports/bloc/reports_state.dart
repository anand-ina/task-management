import '../repository/reports_repository.dart';

abstract class ReportsState {}

class ReportsInitialState extends ReportsState {}

class ReportsLoadingState extends ReportsState {}

class ReportsDashboardLoadedState extends ReportsState {
  final ReportsDashboardData data;
  ReportsDashboardLoadedState(this.data);
}

class ReportsErrorState extends ReportsState {
  final String message;
  ReportsErrorState(this.message);
}
