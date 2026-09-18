import 'dart:convert';
import 'package:dio/dio.dart';
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
      final meetings = await repository.getMyScheduledMeetings();
      emit(MyScheduledMeetingsLoadedState(meetings));
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
}
