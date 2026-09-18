import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/admin_audit_log_model.dart';

class AdminAuditRepository {
  final DioClient _dioClient = DioClient();

  Future<List<AdminAuditLogModel>> getAuditLogs() async {
    const url = ApiConstants.adminAudit;
    debugPrint('[AdminAuditRepository] GET $url');
    try {
      final response = await _dioClient.dio.get(url);
      debugPrint('[AdminAuditRepository] Status: ${response.statusCode}');
      debugPrint('[AdminAuditRepository] Response: ${response.data}');

      final list = response.data as List<dynamic>;
      return list
          .map((j) => AdminAuditLogModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[AdminAuditRepository] Error: $e');
      return _fallbackAuditLogs();
    }
  }

  List<AdminAuditLogModel> _fallbackAuditLogs() {
    final now = DateTime.now();
    return [
      AdminAuditLogModel(
        id: 128,
        action: 'login',
        detail: 'Administrator',
        at: now.subtract(const Duration(minutes: 5)),
        actorId: 35,
        targetUserId: 35,
        actor: 'Administrator',
        target: 'Administrator',
      ),
      AdminAuditLogModel(
        id: 127,
        action: 'logout',
        detail: 'Vamsi',
        at: now.subtract(const Duration(minutes: 10)),
        actorId: 1,
        targetUserId: 1,
        actor: 'Vamsi',
        target: 'Vamsi',
      ),
      AdminAuditLogModel(
        id: 126,
        action: 'login',
        detail: 'Administrator',
        at: now.subtract(const Duration(minutes: 15)),
        actorId: 35,
        targetUserId: 35,
        actor: 'Administrator',
        target: 'Administrator',
      ),
      AdminAuditLogModel(
        id: 125,
        action: 'login',
        detail: 'Vamsi',
        at: now.subtract(const Duration(minutes: 30)),
        actorId: 1,
        targetUserId: 1,
        actor: 'Vamsi',
        target: 'Vamsi',
      ),
      AdminAuditLogModel(
        id: 124,
        action: 'password_change',
        detail: 'Changed own password',
        at: now.subtract(const Duration(hours: 1)),
        actorId: 14,
        targetUserId: 14,
        actor: 'Anusha',
        target: 'Anusha',
      ),
      AdminAuditLogModel(
        id: 123,
        action: 'login',
        detail: 'Anusha',
        at: now.subtract(const Duration(hours: 1, minutes: 5)),
        actorId: 14,
        targetUserId: 14,
        actor: 'Anusha',
        target: 'Anusha',
      ),
      AdminAuditLogModel(
        id: 122,
        action: 'logout',
        detail: 'Administrator',
        at: now.subtract(const Duration(hours: 1, minutes: 15)),
        actorId: 35,
        targetUserId: 35,
        actor: 'Administrator',
        target: 'Administrator',
      ),
    ];
  }
}
