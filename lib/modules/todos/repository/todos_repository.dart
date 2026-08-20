import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
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

  Future<List<TodoHistoryModel>> getTodoHistory() async {
    final response = await _dioClient.dio.get(
      ApiConstants.todosHistory,
      queryParameters: {'scope': 'history'},
    );

    final res = _safeParse(response.data);
    if (res is List) {
      return res.map((e) => TodoHistoryModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
    }
    return [];
  }
}
