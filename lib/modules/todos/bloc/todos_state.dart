import '../models/today_todo_model.dart';
import '../models/todo_history_model.dart';

abstract class TodosState {}

class TodosInitialState extends TodosState {}

class TodosLoadingState extends TodosState {}

class TodoHistoryLoadedState extends TodosState {
  final List<TodoHistoryModel> historyItems;
  TodoHistoryLoadedState(this.historyItems);
}

class TodayTodosLoadedState extends TodosState {
  final TodayTodoResponseModel data;
  TodayTodosLoadedState(this.data);
}

class TodosErrorState extends TodosState {
  final String message;
  TodosErrorState(this.message);
}
