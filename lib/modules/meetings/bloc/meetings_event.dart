abstract class MeetingsEvent {}

class FetchOneOnOnePendingEvent extends MeetingsEvent {}

class FetchMyScheduledMeetingsEvent extends MeetingsEvent {}

class FetchScheduleLookupsEvent extends MeetingsEvent {
  final String atTime;
  FetchScheduleLookupsEvent({this.atTime = '2026-08-19T14:00'});
}

class FetchMeetingCalendarEvent extends MeetingsEvent {}
