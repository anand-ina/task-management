import '../models/event_model.dart';

abstract class EventsState {}

class EventsInitialState extends EventsState {}

class EventsLoadingState extends EventsState {}

class EventsLoadedState extends EventsState {
  final List<EventModel> events;
  EventsLoadedState(this.events);
}

class EventsErrorState extends EventsState {
  final String message;
  EventsErrorState(this.message);
}
