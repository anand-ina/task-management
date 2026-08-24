abstract class TodosEvent {}

class FetchTodoHistoryEvent extends TodosEvent {}

class FetchTodayTodosEvent extends TodosEvent {}

class AddTodayTodoEvent extends TodosEvent {
  final String text;
  AddTodayTodoEvent({required this.text});
}

class ToggleTodoEvent extends TodosEvent {
  final int id;
  final bool done;
  ToggleTodoEvent({required this.id, required this.done});
}

class DeleteTodoEvent extends TodosEvent {
  final int id;
  DeleteTodoEvent({required this.id});
}
