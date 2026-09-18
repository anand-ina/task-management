import 'package:equatable/equatable.dart';
import '../models/org_chart_model.dart';

abstract class OrgChartState extends Equatable {
  const OrgChartState();
  @override
  List<Object?> get props => [];
}

class OrgChartInitialState extends OrgChartState {}
class OrgChartLoadingState extends OrgChartState {}

class OrgChartLoadedState extends OrgChartState {
  final OrgChartResponseModel orgChart;
  const OrgChartLoadedState(this.orgChart);
  @override
  List<Object?> get props => [orgChart];
}

class OrgChartErrorState extends OrgChartState {
  final String message;
  const OrgChartErrorState(this.message);
  @override
  List<Object?> get props => [message];
}
