import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/events_repository.dart';
import 'events_event.dart';
import 'events_state.dart';

class EventsBloc extends Bloc<EventsEvent, EventsState> {
  final EventsRepository repository;

  EventsBloc({EventsRepository? eventsRepository})
      : repository = eventsRepository ?? EventsRepository(),
        super(EventsInitialState()) {
    on<FetchEventsEvent>(_onFetchEvents);
  }

  Future<void> _onFetchEvents(
    FetchEventsEvent event,
    Emitter<EventsState> emit,
  ) async {
    emit(EventsLoadingState());
    try {
      final events = await repository.getEvents();
      emit(EventsLoadedState(events));
    } catch (e) {
      emit(EventsErrorState(e.toString()));
    }
  }
}
