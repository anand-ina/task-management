abstract class RecurringTasksEvent {}

class FetchRecurringTasksEvent extends RecurringTasksEvent {
  final String? frequency;
  FetchRecurringTasksEvent({this.frequency});
}
