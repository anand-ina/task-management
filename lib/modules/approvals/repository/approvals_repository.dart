import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/task_approval_model.dart';
import '../models/escalation_model.dart';
import '../models/meeting_approval_model.dart';
import '../models/budget_approval_model.dart';

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

  Future<List<EscalationModel>> getEscalations() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.escalations);
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
}
