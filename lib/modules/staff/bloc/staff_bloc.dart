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
    on<UpdateStaffEvent>(_onUpdateStaff);
    on<DeleteStaffEvent>(_onDeleteStaff);
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

  void _onUpdateStaff(
    UpdateStaffEvent event,
    Emitter<StaffState> emit,
  ) {
    if (state is StaffLoadedState) {
      final currentData = (state as StaffLoadedState).data;
      final updatedList = currentData.staffList
          .map((s) => s.id == event.staff.id ? event.staff : s)
          .toList();
      final newData = StaffOverviewData(
        staffList: updatedList,
        departments: currentData.departments,
        roles: currentData.roles,
        branches: currentData.branches,
      );
      emit(StaffLoadedState(newData));
    }
  }

  void _onDeleteStaff(
    DeleteStaffEvent event,
    Emitter<StaffState> emit,
  ) {
    if (state is StaffLoadedState) {
      final currentData = (state as StaffLoadedState).data;
      final updatedList = currentData.staffList
          .where((s) => s.id != event.staffId)
          .toList();
      final newData = StaffOverviewData(
        staffList: updatedList,
        departments: currentData.departments,
        roles: currentData.roles,
        branches: currentData.branches,
      );
      emit(StaffLoadedState(newData));
    }
  }
}
