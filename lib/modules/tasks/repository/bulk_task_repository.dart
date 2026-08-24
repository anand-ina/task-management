import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/bulk_task_model.dart';

class BulkTaskRepository {
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

  Future<BulkTemplateModel> getTemplate() async {
    final response = await _dioClient.dio.get(ApiConstants.bulkTasksTemplate);
    final data = _safeParse(response.data);
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    return BulkTemplateModel.fromJson(map);
  }

  Future<BulkPreviewModel> uploadPreview(String filePath) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
    });

    final response = await _dioClient.dio.post(
      ApiConstants.bulkTasksPreview,
      data: formData,
    );

    final data = _safeParse(response.data);
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    return BulkPreviewModel.fromJson(map);
  }

  Future<BulkCommitResponseModel> commitTasks(List<BulkRowModel> rows) async {
    final payload = {
      'rows': rows.map((e) => e.toJson()).toList(),
    };

    final response = await _dioClient.dio.post(
      ApiConstants.bulkTasksCommit,
      data: payload,
    );

    final data = _safeParse(response.data);
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    return BulkCommitResponseModel.fromJson(map);
  }
}
