import 'package:equatable/equatable.dart';

abstract class OrgChartEvent extends Equatable {
  const OrgChartEvent();
  @override
  List<Object?> get props => [];
}

class FetchOrgChartEvent extends OrgChartEvent {}
