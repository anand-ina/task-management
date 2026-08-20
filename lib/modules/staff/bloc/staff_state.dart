import '../repository/staff_repository.dart';

abstract class StaffState {}

class StaffInitialState extends StaffState {}

class StaffLoadingState extends StaffState {}

class StaffLoadedState extends StaffState {
  final StaffOverviewData data;
  StaffLoadedState(this.data);
}

class StaffErrorState extends StaffState {
  final String message;
  StaffErrorState(this.message);
}
