import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/organization_repository.dart';
import 'my_reporting_event.dart';
import 'my_reporting_state.dart';

class MyReportingBloc extends Bloc<MyReportingEvent, MyReportingState> {
  final OrganizationRepository _repository = OrganizationRepository();

  MyReportingBloc() : super(MyReportingInitialState()) {
    on<FetchMyReportingEvent>(_onFetch);
  }

  Future<void> _onFetch(FetchMyReportingEvent event, Emitter<MyReportingState> emit) async {
    emit(MyReportingLoadingState());
    try {
      final data = await _repository.getMyReporting();
      emit(MyReportingLoadedState(data));
    } catch (e) {
      emit(MyReportingErrorState(e.toString()));
    }
  }
}
