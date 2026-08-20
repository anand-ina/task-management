import '../models/meeting_model.dart';
import '../models/one_on_one_pending_model.dart';
import '../repository/meetings_repository.dart';

abstract class MeetingsState {}

class MeetingsInitialState extends MeetingsState {}

class MeetingsLoadingState extends MeetingsState {}

class OneOnOnePendingLoadedState extends MeetingsState {
  final List<OneOnOnePendingModel> pendingList;
  OneOnOnePendingLoadedState(this.pendingList);
}

class MyScheduledMeetingsLoadedState extends MeetingsState {
  final List<MeetingItemModel> meetings;
  MyScheduledMeetingsLoadedState(this.meetings);
}

class ScheduleLookupsLoadedState extends MeetingsState {
  final ScheduleLookupsData data;
  ScheduleLookupsLoadedState(this.data);
}

class MeetingCalendarLoadedState extends MeetingsState {
  final List<MeetingItemModel> meetings;
  MeetingCalendarLoadedState(this.meetings);
}

class MeetingsErrorState extends MeetingsState {
  final String message;
  MeetingsErrorState(this.message);
}
