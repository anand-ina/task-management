import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/task_approval_model.dart';
import '../models/escalation_model.dart';
import '../models/meeting_approval_model.dart';
import '../models/indent_model.dart';
import '../models/organisation_approval_model.dart';

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

  Future<List<OrganisationApprovalModel>> getOrganisationApprovals() async {
    final url = ApiConstants.approvalsOrganisation;
    _logServiceCall(
      serviceMethod: 'getOrganisationApprovals',
      url: url,
    );
    try {
      final response = await _dioClient.dio.get(url);
      _logServiceCall(
        serviceMethod: 'getOrganisationApprovals',
        url: url,
        response: response.data,
      );
      final rawList = _extractList(response.data);
      return rawList
          .map((e) => OrganisationApprovalModel.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    } catch (e) {
      debugPrint('[ApprovalsRepository] getOrganisationApprovals error: $e');
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

  Future<List<IndentItemModel>> getIndentsMine() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.indentsMine);
      _logServiceCall(
        serviceMethod: 'getIndentsMine',
        url: ApiConstants.indentsMine,
        response: response.data,
      );
      final rawList = _extractList(response.data);
      return rawList.map((e) => IndentItemModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
    } catch (e) {
      debugPrint('[ApprovalsRepository] getIndentsMine error: $e');
    }
    return [];
  }

  String _errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        final msg = data['message'];
        return msg is List ? msg.join(', ') : msg.toString();
      }
      return e.message ?? 'Request failed';
    }
    return e.toString();
  }

  /// POST /indents/{id}/decide  {decision: approve|reject, comment?}
  Future<IndentDecisionResponseModel> decideIndent(int id, String decision, {String? comment}) async {
    final url = ApiConstants.indentDecide(id);
    final payload = {
      'decision': decision,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    };
    _logServiceCall(serviceMethod: 'decideIndent', url: url, payload: payload);
    try {
      final response = await _dioClient.dio.post(url, data: payload);
      _logServiceCall(serviceMethod: 'decideIndent', url: url, response: response.data);
      return IndentDecisionResponseModel.fromJson(
          response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : {});
    } catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// POST /indents/{id}/override  {decision: approve|reject, comment}  (Director only)
  Future<void> overrideIndent(int id, String decision, String comment) async {
    final url = ApiConstants.indentOverride(id);
    final payload = {'decision': decision, 'comment': comment.trim()};
    _logServiceCall(serviceMethod: 'overrideIndent', url: url, payload: payload);
    try {
      final response = await _dioClient.dio.post(url, data: payload);
      _logServiceCall(serviceMethod: 'overrideIndent', url: url, response: response.data);
    } catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// POST /indents/{id}/cancel  (raiser only, while pending)
  Future<void> cancelIndent(int id) async {
    final url = ApiConstants.indentCancel(id);
    _logServiceCall(serviceMethod: 'cancelIndent', url: url);
    try {
      final response = await _dioClient.dio.post(url);
      _logServiceCall(serviceMethod: 'cancelIndent', url: url, response: response.data);
    } catch (e) {
      throw Exception(_errorMessage(e));
    }
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
          await _dioClient.dio.post(fallbackUrl2, data: payload);
          return true;
        } catch (_) {}
      }
      return false;
    }
  }

  Future<bool> rsvpMeeting(int id, String responseValue) async {
    final url = ApiConstants.meetingRespond(id);
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
      debugPrint('[ApprovalsRepository] rsvpMeeting /respond failed: $e, trying fallback to /rsvp');
      try {
        final fallbackUrl = '${ApiConstants.baseUrl}/meetings/$id/rsvp';
        final response = await _dioClient.dio.post(fallbackUrl, data: payload);
        _logServiceCall(
          serviceMethod: 'rsvpMeetingFallback',
          url: fallbackUrl,
          response: response.data,
        );
        return true;
      } catch (_) {}
      return false;
    }
  }

  Future<bool> respondToMeeting(int id, String responseValue) => rsvpMeeting(id, responseValue);
}
