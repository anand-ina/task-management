import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/task_approval_model.dart';
import '../models/escalation_model.dart';
import '../models/meeting_approval_model.dart';
import '../models/budget_approval_model.dart';
import '../models/indent_model.dart';

class ApprovalsRepository {
  final DioClient _dioClient = DioClient();

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final map = data as Map<String, dynamic>;
      if (map['data'] is List) return map['data'] as List;
      if (map['meetings'] is List) return map['meetings'] as List;
      if (map['items'] is List) return map['items'] as List;
      if (map['requests'] is List) return map['requests'] as List;
      if (map['results'] is List) return map['results'] as List;
    }
    return [];
  }

  Future<List<TaskApprovalModel>> getApprovals() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.approvals);
      final rawList = _extractList(response.data);
      return rawList.map((e) => TaskApprovalModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
    } catch (e) {
      debugPrint('[ApprovalsRepository] getApprovals error: $e');
    }
    return [];
  }

  Future<List<TaskApprovalModel>> getApprovalsInitiated() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.approvalsInitiated);
      final rawList = _extractList(response.data);
      return rawList.map((e) => TaskApprovalModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
    } catch (e) {
      debugPrint('[ApprovalsRepository] getApprovalsInitiated error: $e');
    }
    return [];
  }

  Future<List<EscalationModel>> getEscalationsToReview() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.escalationsToReview);
      final rawList = _extractList(response.data);
      return rawList.map((e) => EscalationModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
    } catch (e) {
      debugPrint('[ApprovalsRepository] getEscalationsToReview error: $e');
    }
    return [];
  }

  void _logServiceCall({
    required String serviceMethod,
    required String url,
    dynamic payload,
    dynamic response,
  }) {
    debugPrint('---------------- [ApprovalsService: $serviceMethod] ----------------');
    debugPrint('Service URL: $url');
    if (payload != null) {
      debugPrint('Service Payload: $payload');
    }
    if (response != null) {
      debugPrint('Service Response: $response');
    }
    debugPrint('---------------------------------------------------------------------');
  }

  Future<List<EscalationModel>> getEscalations() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.escalations);
      _logServiceCall(
        serviceMethod: 'getEscalations',
        url: ApiConstants.escalations,
        response: response.data,
      );
      final rawList = _extractList(response.data);
      return rawList.map((e) => EscalationModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
    } catch (e) {
      debugPrint('[ApprovalsRepository] getEscalations error: $e');
    }
    return [];
  }

  Future<List<MeetingApprovalModel>> getMeetings() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.meetings);
      debugPrint('[ApprovalsRepository] getMeetings response: ${response.data}');
      final rawList = _extractList(response.data);
      return rawList.map((e) => MeetingApprovalModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
    } catch (e, stack) {
      debugPrint('[ApprovalsRepository] getMeetings error: $e\n$stack');
    }
    return [];
  }

  Future<List<MeetingApprovalModel>> getMeetingCompletionRequests() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.meetingCompletionRequests);
      debugPrint('[ApprovalsRepository] getMeetingCompletionRequests response: ${response.data}');
      final rawList = _extractList(response.data);
      return rawList.map((e) => MeetingApprovalModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
    } catch (e, stack) {
      debugPrint('[ApprovalsRepository] getMeetingCompletionRequests error: $e\n$stack');
    }
    return [];
  }

  Future<List<BudgetApprovalModel>> getBudgetReceived() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.budgetReceived);
      final rawList = _extractList(response.data);
      return rawList.map((e) => BudgetApprovalModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
    } catch (e) {
      debugPrint('[ApprovalsRepository] getBudgetReceived error: $e');
    }
    return [];
  }

  Future<List<BudgetApprovalModel>> getBudgetInitiated() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.budgetInitiated);
      final rawList = _extractList(response.data);
      return rawList.map((e) => BudgetApprovalModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
    } catch (e) {
      debugPrint('[ApprovalsRepository] getBudgetInitiated error: $e');
    }
    return [];
  }

  Future<List<IndentItemModel>> getIndentsInbox() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.indentsInbox);
      _logServiceCall(
        serviceMethod: 'getIndentsInbox',
        url: ApiConstants.indentsInbox,
        response: response.data,
      );
      final rawList = _extractList(response.data);
      return rawList.map((e) => IndentItemModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
    } catch (e) {
      debugPrint('[ApprovalsRepository] getIndentsInbox error: $e');
    }
    return [];
  }

  Future<List<IndentItemModel>> getIndentsAll() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.indentsAll);
      _logServiceCall(
        serviceMethod: 'getIndentsAll',
        url: ApiConstants.indentsAll,
        response: response.data,
      );
      final rawList = _extractList(response.data);
      return rawList.map((e) => IndentItemModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
    } catch (e) {
      debugPrint('[ApprovalsRepository] getIndentsAll error: $e');
    }
    return [];
  }

  Future<IndentItemModel?> getIndentDetail(int id) async {
    final url = ApiConstants.indentDetail(id);
    try {
      final response = await _dioClient.dio.get(url);
      _logServiceCall(
        serviceMethod: 'getIndentDetail',
        url: url,
        response: response.data,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return IndentItemModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('[ApprovalsRepository] getIndentDetail error: $e');
    }
    return null;
  }

  Future<CreateIndentResponseModel?> createIndent(Map<String, dynamic> payload) async {
    final url = ApiConstants.indents;
    _logServiceCall(
      serviceMethod: 'createIndent',
      url: url,
      payload: payload,
    );
    try {
      final response = await _dioClient.dio.post(url, data: payload);
      _logServiceCall(
        serviceMethod: 'createIndent',
        url: url,
        response: response.data,
      );
      if (response.data is Map<String, dynamic>) {
        return CreateIndentResponseModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[ApprovalsRepository] createIndent error: $e');
      rethrow;
    }
    return null;
  }

  Future<bool> decideApproval(int id, String decision) async {
    try {
      final response = await _dioClient.dio.post(
        '${ApiConstants.baseUrl}/approvals/$id/decide',
        data: {'decision': decision},
      );
      debugPrint('[ApprovalsRepository] decideApproval URL: ${ApiConstants.baseUrl}/approvals/$id/decide, payload: {"decision": "$decision"}, response: ${response.data}');
      return true;
    } catch (e) {
      debugPrint('[ApprovalsRepository] decideApproval error: $e');
      return false;
    }
  }

  Future<bool> decideBudget(int id, String decision) async {
    try {
      final response = await _dioClient.dio.post(
        '${ApiConstants.baseUrl}/budget/$id/decide',
        data: {'decision': decision},
      );
      debugPrint('[ApprovalsRepository] decideBudget URL: ${ApiConstants.baseUrl}/budget/$id/decide, payload: {"decision": "$decision"}, response: ${response.data}');
      return true;
    } catch (e) {
      debugPrint('[ApprovalsRepository] decideBudget /budget/$id/decide failed: $e, trying fallback');
      try {
        final response = await _dioClient.dio.post(
          '${ApiConstants.baseUrl}/approvals/$id/decide',
          data: {'decision': decision},
        );
        debugPrint('[ApprovalsRepository] decideBudget fallback /approvals/$id/decide response: ${response.data}');
        return true;
      } catch (_) {
        try {
          final response = await _dioClient.dio.patch(
            '${ApiConstants.baseUrl}/budget/$id',
            data: {'status': decision == 'approve' ? 'approved' : 'rejected'},
          );
          debugPrint('[ApprovalsRepository] decideBudget fallback /budget/$id PATCH response: ${response.data}');
          return true;
        } catch (_) {}
      }
      return false;
    }
  }

  Future<bool> decideEscalation(int id, String decision) async {
    final url = '${ApiConstants.baseUrl}/escalations/$id/decide';
    final payload = {'decision': decision};
    _logServiceCall(
      serviceMethod: 'decideEscalation',
      url: url,
      payload: payload,
    );
    try {
      final response = await _dioClient.dio.post(url, data: payload);
      _logServiceCall(
        serviceMethod: 'decideEscalation',
        url: url,
        response: response.data,
      );
      return true;
    } catch (e) {
      debugPrint('[ApprovalsRepository] decideEscalation error: $e');
      return false;
    }
  }

  Future<bool> decideMeetingCompletion(int id, String decision) async {
    final url = '${ApiConstants.baseUrl}/meetings/$id/complete/decide';
    final payload = {'decision': decision};
    _logServiceCall(
      serviceMethod: 'decideMeetingCompletion',
      url: url,
      payload: payload,
    );
    try {
      final response = await _dioClient.dio.post(url, data: payload);
      _logServiceCall(
        serviceMethod: 'decideMeetingCompletion',
        url: url,
        response: response.data,
      );
      return true;
    } catch (e) {
      debugPrint('[ApprovalsRepository] decideMeetingCompletion error: $e, trying fallback');
      try {
        final fallbackUrl = '${ApiConstants.baseUrl}/meetings/completion-requests/$id/decide';
        final response = await _dioClient.dio.post(fallbackUrl, data: payload);
        _logServiceCall(
          serviceMethod: 'decideMeetingCompletionFallback',
          url: fallbackUrl,
          response: response.data,
        );
        return true;
      } catch (_) {
        try {
          final fallbackUrl2 = '${ApiConstants.baseUrl}/meetings/$id/complete';
          final response = await _dioClient.dio.post(fallbackUrl2, data: payload);
          return true;
        } catch (_) {}
      }
      return false;
    }
  }

  Future<bool> rsvpMeeting(int id, String responseValue) async {
    final url = '${ApiConstants.baseUrl}/meetings/$id/rsvp';
    final payload = {'response': responseValue};
    _logServiceCall(
      serviceMethod: 'rsvpMeeting',
      url: url,
      payload: payload,
    );
    try {
      final response = await _dioClient.dio.post(url, data: payload);
      _logServiceCall(
        serviceMethod: 'rsvpMeeting',
        url: url,
        response: response.data,
      );
      return true;
    } catch (e) {
      debugPrint('[ApprovalsRepository] rsvpMeeting error: $e');
      return false;
    }
  }
}
