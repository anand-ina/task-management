import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/today_todo_model.dart';
import '../models/todo_history_model.dart';

class TodosRepository {
  final DioClient _dioClient = DioClient();

  dynamic _safeParse(dynamic data) {
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return null;
      }
    }
    return data;
  }

  Future<TodayTodoResponseModel> getTodayTodos() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.todosToday);
      final res = _safeParse(response.data);
      return TodayTodoResponseModel.fromJson(res);
    } catch (_) {}
    return TodayTodoResponseModel(
      openCount: 0,
      doneCount: 0,
      carriedCount: 0,
      carriedItems: [],
      todayItems: [],
    );
  }

  Future<TodayTodoItemModel?> addTodo(String text) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.todos,
        data: {'text': text},
      );
      final res = _safeParse(response.data);
      if (res is Map<String, dynamic>) {
        return TodayTodoItemModel.fromJson(res);
      }
    } catch (_) {}
    return null;
  }

  Future<bool> toggleTodoStatus(int id, bool done) async {
    try {
      await _dioClient.dio.patch(
        '${ApiConstants.todos}/$id',
        data: {'done': done},
      );
      return true;
    } catch (_) {}
    return false;
  }

  Future<bool> deleteTodo(int id) async {
    try {
      final response = await _dioClient.dio.delete('${ApiConstants.todos}/$id');
      final res = _safeParse(response.data);
      if (res is Map<String, dynamic> && res['ok'] == true) {
        return true;
      }
      return true;
    } catch (_) {}
    return false;
  }

  Future<List<TodoHistoryModel>> getTodoHistory() async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.todosHistory,
        queryParameters: {'scope': 'history'},
      );

      final res = _safeParse(response.data);
      if (res is List) {
        return res.map((e) => TodoHistoryModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
      }
    } catch (_) {}
    return [];
  }
}
