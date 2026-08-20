import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/task_approval_model.dart';
import '../models/escalation_model.dart';
import '../models/meeting_approval_model.dart';
import '../models/budget_approval_model.dart';

class ApprovalsRepository {
  final DioClient _dioClient = DioClient();

  Future<List<TaskApprovalModel>> getApprovals() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.approvals);
      if (response.data is List) {
        return (response.data as List).map((e) => TaskApprovalModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<TaskApprovalModel>> getApprovalsInitiated() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.approvalsInitiated);
      if (response.data is List) {
        return (response.data as List).map((e) => TaskApprovalModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<EscalationModel>> getEscalationsToReview() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.escalationsToReview);
      if (response.data is List) {
        return (response.data as List).map((e) => EscalationModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<EscalationModel>> getEscalations() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.escalations);
      if (response.data is List) {
        return (response.data as List).map((e) => EscalationModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<MeetingApprovalModel>> getMeetings() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.meetings);
      if (response.data is List) {
        return (response.data as List).map((e) => MeetingApprovalModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<MeetingApprovalModel>> getMeetingCompletionRequests() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.meetingCompletionRequests);
      if (response.data is List) {
        return (response.data as List).map((e) => MeetingApprovalModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<BudgetApprovalModel>> getBudgetReceived() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.budgetReceived);
      if (response.data is List) {
        return (response.data as List).map((e) => BudgetApprovalModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<BudgetApprovalModel>> getBudgetInitiated() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.budgetInitiated);
      if (response.data is List) {
        return (response.data as List).map((e) => BudgetApprovalModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }
}
