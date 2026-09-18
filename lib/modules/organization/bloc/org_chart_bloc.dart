import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/organization_repository.dart';
import 'org_chart_event.dart';
import 'org_chart_state.dart';

class OrgChartBloc extends Bloc<OrgChartEvent, OrgChartState> {
  final OrganizationRepository _repository = OrganizationRepository();

  OrgChartBloc() : super(OrgChartInitialState()) {
    on<FetchOrgChartEvent>(_onFetch);
  }

  Future<void> _onFetch(FetchOrgChartEvent event, Emitter<OrgChartState> emit) async {
    emit(OrgChartLoadingState());
    try {
      final data = await _repository.getOrgChart();
      emit(OrgChartLoadedState(data));
    } catch (e) {
      emit(OrgChartErrorState(e.toString()));
    }
  }
}
