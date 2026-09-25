import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/admin_audit_log_model.dart';

class AdminAuditRepository {
  final DioClient _dioClient = DioClient();

  Future<List<AdminAuditLogModel>> getAuditLogs() async {
    const url = ApiConstants.adminAudit;
    debugPrint('---------------- [AdminAuditRepository: getAuditLogs] ----------------');
    debugPrint('URL: $url');
    try {
      final response = await _dioClient.dio.get(url);
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Response: ${response.data}');
      debugPrint('---------------------------------------------------------------------');

      if (response.data is List) {
        final list = response.data as List<dynamic>;
        return list
            .map((j) => AdminAuditLogModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[AdminAuditRepository] Error: $e');
      rethrow;
    }
  }
}
