abstract class ReportsEvent {}

class FetchReportsDashboardEvent extends ReportsEvent {}

class FetchComplianceEvent extends ReportsEvent {
  final String type;
  FetchComplianceEvent(this.type);
}
