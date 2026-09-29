import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/google_calendar_status_model.dart';
import '../models/meeting_model.dart';
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
    on<DisconnectGoogleCalendarEvent>(_onDisconnectGoogleCalendar);
    on<CompleteGoogleCalendarCallbackEvent>(_onCompleteGoogleCalendarCallback);
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message'];
        if (msg != null) {
          if (msg is List) return msg.join(', ');
          if (msg.toString().trim().isNotEmpty) return msg.toString();
        }
        final err = data['error'];
        if (err != null && err.toString().trim().isNotEmpty) return err.toString();
      } else if (data is String && data.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map) {
            final msg = decoded['message'];
            if (msg != null) {
              if (msg is List) return msg.join(', ');
              if (msg.toString().trim().isNotEmpty) return msg.toString();
            }
          }
        } catch (_) {
          return data;
        }
      }
    }
    final str = e.toString();
    if (str.startsWith('Exception: ')) return str.substring(11);
    return str;
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
      emit(MeetingsErrorState(_parseError(e)));
    }
  }

  Future<void> _onFetchMyScheduledMeetings(
    FetchMyScheduledMeetingsEvent event,
    Emitter<MeetingsState> emit,
  ) async {
    emit(MeetingsLoadingState());
    try {
      final results = await Future.wait([
        repository.getMyScheduledMeetings(),
        repository.getGoogleCalendarStatus(),
      ]);
      final meetings = results[0] as List<MeetingItemModel>;
      final calendarStatus = results[1] as GoogleCalendarStatusModel?;
      emit(MyScheduledMeetingsLoadedState(meetings, calendarStatus: calendarStatus));
    } catch (e) {
      emit(MeetingsErrorState(_parseError(e)));
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
      emit(MeetingsErrorState(_parseError(e)));
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
      emit(MeetingsErrorState(_parseError(e)));
    }
  }

  Future<void> _onDisconnectGoogleCalendar(
    DisconnectGoogleCalendarEvent event,
    Emitter<MeetingsState> emit,
  ) async {
    emit(MeetingsLoadingState());
    try {
      final success = await repository.disconnectGoogleCalendar();
      if (success) {
        final results = await Future.wait([
          repository.getMyScheduledMeetings(),
          repository.getGoogleCalendarStatus(),
        ]);
        final meetings = results[0] as List<MeetingItemModel>;
        final calendarStatus = results[1] as GoogleCalendarStatusModel?;
        emit(MyScheduledMeetingsLoadedState(
          meetings,
          calendarStatus: calendarStatus,
          isDisconnected: true,
        ));
      } else {
        emit(MeetingsErrorState('Failed to disconnect Google Calendar'));
      }
    } catch (e) {
      emit(MeetingsErrorState(_parseError(e)));
    }
  }

  Future<void> _onCompleteGoogleCalendarCallback(
    CompleteGoogleCalendarCallbackEvent event,
    Emitter<MeetingsState> emit,
  ) async {
    try {
      await repository.callGoogleCalendarCallback(
        code: event.code,
        state: event.state,
      );
      final results = await Future.wait([
        repository.getMyScheduledMeetings(),
        repository.getGoogleCalendarStatus(),
      ]);
      final meetings = results[0] as List<MeetingItemModel>;
      final calendarStatus = results[1] as GoogleCalendarStatusModel?;
      emit(MyScheduledMeetingsLoadedState(
        meetings,
        calendarStatus: calendarStatus,
      ));
    } catch (e) {
      emit(MeetingsErrorState(_parseError(e)));
    }
  }
}
