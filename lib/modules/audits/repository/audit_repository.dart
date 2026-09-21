import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/audit_model.dart';

class AuditRepository {
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

  void _logServiceCall({
    required String serviceMethod,
    required String url,
    Map<String, dynamic>? queryParams,
    dynamic requestBody,
    dynamic response,
    String? error,
  }) {
    debugPrint('=========================================');
    debugPrint('---------------- [AuditRepository: $serviceMethod] ----------------');
    debugPrint('Service URL: $url');
    if (queryParams != null && queryParams.isNotEmpty) {
      debugPrint('Query Params: $queryParams');
    }
    if (requestBody != null) {
      debugPrint('Request Body: $requestBody');
    }
    if (response != null) {
      debugPrint('Service Response: $response');
    }
    if (error != null) {
      debugPrint('Service Error: $error');
    }
    debugPrint('=========================================');
  }

  Future<AuditMetaModel> getAuditMeta() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.auditsMeta);
      _logServiceCall(
        serviceMethod: 'getAuditMeta',
        url: ApiConstants.auditsMeta,
        response: response.data,
      );
      final data = _safeParse(response.data);
      if (data is Map<String, dynamic>) {
        return AuditMetaModel.fromJson(data);
      }
      return AuditMetaModel(people: [], branches: []);
    } catch (e, stack) {
      _logServiceCall(
        serviceMethod: 'getAuditMeta',
        url: ApiConstants.auditsMeta,
        error: '$e\n$stack',
      );
      return AuditMetaModel(people: [], branches: []);
    }
  }

  Future<List<AuditItemModel>> getAsAuditeeAudits() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.auditsAsAuditee);
      _logServiceCall(
        serviceMethod: 'getAsAuditeeAudits',
        url: ApiConstants.auditsAsAuditee,
        response: response.data,
      );
      final data = _safeParse(response.data);
      if (data is List) {
        return data
            .map((e) => AuditItemModel.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList();
      }
      return [];
    } catch (e, stack) {
      _logServiceCall(
        serviceMethod: 'getAsAuditeeAudits',
        url: ApiConstants.auditsAsAuditee,
        error: '$e\n$stack',
      );
      return [];
    }
  }

  Future<List<AuditItemModel>> getAsAuditorAudits() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.auditsAsAuditor);
      _logServiceCall(
        serviceMethod: 'getAsAuditorAudits',
        url: ApiConstants.auditsAsAuditor,
        response: response.data,
      );
      final data = _safeParse(response.data);
      if (data is List) {
        return data
            .map((e) => AuditItemModel.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList();
      }
      return [];
    } catch (_) {
      // Fallback to /api/audits/as-auditee if as-auditor isn't available
      return getAsAuditeeAudits();
    }
  }

  Future<AuditItemModel?> getAuditById(int id) async {
    final url = ApiConstants.auditDetail(id);
    try {
      final response = await _dioClient.dio.get(url);
      _logServiceCall(
        serviceMethod: 'getAuditById',
        url: url,
        response: response.data,
      );
      final data = _safeParse(response.data);
      if (data is Map<String, dynamic>) {
        return AuditItemModel.fromJson(data);
      }
      return null;
    } catch (e, stack) {
      _logServiceCall(
        serviceMethod: 'getAuditById',
        url: url,
        error: '$e\n$stack',
      );
      return null;
    }
  }

  Future<bool> scheduleAudit(Map<String, dynamic> body) async {
    final url = ApiConstants.audits;
    try {
      final response = await _dioClient.dio.post(url, data: body);
      _logServiceCall(
        serviceMethod: 'scheduleAudit',
        url: url,
        requestBody: body,
        response: response.data,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, stack) {
      _logServiceCall(
        serviceMethod: 'scheduleAudit',
        url: url,
        requestBody: body,
        error: '$e\n$stack',
      );
      return false;
    }
  }

  Future<bool> closeAudit(int id) async {
    final url = ApiConstants.closeAudit(id);
    try {
      final response = await _dioClient.dio.post(url);
      _logServiceCall(
        serviceMethod: 'closeAudit',
        url: url,
        response: response.data,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, stack) {
      _logServiceCall(
        serviceMethod: 'closeAudit',
        url: url,
        error: '$e\n$stack',
      );
      return false;
    }
  }
}
