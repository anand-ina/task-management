import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/meetings_repository.dart';
import 'meetings_event.dart';
import 'meetings_state.dart';

class MeetingsBloc extends Bloc<MeetingsEvent, MeetingsState> {
  final MeetingsRepository repository;

  MeetingsBloc({MeetingsRepository? meetingsRepository})
      : repository = meetingsRepository ?? MeetingsRepository(),
        super(MeetingsInitialState()) {
    on<FetchOneOnOnePendingEvent>(_onFetchOneOnOnePending);
    on<FetchMyScheduledMeetingsEvent>(_onFetchMyScheduledMeetings);
    on<FetchScheduleLookupsEvent>(_onFetchScheduleLookups);
    on<FetchMeetingCalendarEvent>(_onFetchMeetingCalendar);
  }

  Future<void> _onFetchOneOnOnePending(
    FetchOneOnOnePendingEvent event,
    Emitter<MeetingsState> emit,
  ) async {
    emit(MeetingsLoadingState());
    try {
      final pending = await repository.getOneOnOnePending();
      emit(OneOnOnePendingLoadedState(pending));
    } catch (e) {
      emit(MeetingsErrorState(e.toString()));
    }
  }

  Future<void> _onFetchMyScheduledMeetings(
    FetchMyScheduledMeetingsEvent event,
    Emitter<MeetingsState> emit,
  ) async {
    emit(MeetingsLoadingState());
    try {
      final meetings = await repository.getMyScheduledMeetings();
      emit(MyScheduledMeetingsLoadedState(meetings));
    } catch (e) {
      emit(MeetingsErrorState(e.toString()));
    }
  }

  Future<void> _onFetchMeetingCalendar(
    FetchMeetingCalendarEvent event,
    Emitter<MeetingsState> emit,
  ) async {
    emit(MeetingsLoadingState());
    try {
      final meetings = await repository.getMeetingsViewAll();
      emit(MeetingCalendarLoadedState(meetings));
    } catch (e) {
      emit(MeetingsErrorState(e.toString()));
    }
  }

  Future<void> _onFetchScheduleLookups(
    FetchScheduleLookupsEvent event,
    Emitter<MeetingsState> emit,
  ) async {
    try {
      final data = await repository.getScheduleLookups(atTime: event.atTime);
      emit(ScheduleLookupsLoadedState(data));
    } catch (e) {
      emit(MeetingsErrorState(e.toString()));
    }
  }
}
