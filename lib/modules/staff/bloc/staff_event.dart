import '../models/staff_model.dart';

abstract class StaffEvent {}

class FetchStaffEvent extends StaffEvent {}

class UpdateStaffEvent extends StaffEvent {
  final StaffModel staff;
  UpdateStaffEvent(this.staff);
}

class DeleteStaffEvent extends StaffEvent {
  final int staffId;
  DeleteStaffEvent(this.staffId);
}
