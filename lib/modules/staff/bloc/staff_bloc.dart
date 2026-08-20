import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/staff_repository.dart';
import 'staff_event.dart';
import 'staff_state.dart';

class StaffBloc extends Bloc<StaffEvent, StaffState> {
  final StaffRepository repository;

  StaffBloc({StaffRepository? staffRepository})
      : repository = staffRepository ?? StaffRepository(),
        super(StaffInitialState()) {
    on<FetchStaffEvent>(_onFetchStaff);
  }

  Future<void> _onFetchStaff(
    FetchStaffEvent event,
    Emitter<StaffState> emit,
  ) async {
    emit(StaffLoadingState());
    try {
      final data = await repository.getStaffOverviewData();
      emit(StaffLoadedState(data));
    } catch (e) {
      emit(StaffErrorState(e.toString()));
    }
  }
}
