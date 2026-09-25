import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/batch_ticket_request.dart';
import '../models/batch_ticket_response.dart';
import '../models/create_ticket_request.dart';
import '../models/draft_model.dart';
import '../models/lookup_models.dart';
import '../models/ticket_insights_model.dart';
import '../models/ticket_meta_model.dart';
import '../models/ticket_model.dart';

class ComplaintsRepository {
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
    dynamic payload,
    dynamic response,
  }) {
    debugPrint('---------------- [ComplaintsService: $serviceMethod] ----------------');
    debugPrint('Service URL: $url');
    if (payload != null) {
      debugPrint('Service Payload: $payload');
    }
    if (response != null) {
      debugPrint('Service Response: $response');
    }
    debugPrint('---------------------------------------------------------------------');
  }

  Future<TicketListResponse> getTickets({
    String? status,
    String? type,
    String? types,
    String? source,
    String? category,
    String? mine,
    String? q,
    int? branchId,
  }) async {
    final Map<String, dynamic> queryParams = {};
    if (status != null && status.isNotEmpty && status != 'all' && status != 'everything') {
      queryParams['status'] = status;
    }
    if (types != null && types.isNotEmpty) {
      queryParams['types'] = types;
    } else if (type != null && type.isNotEmpty && type != 'All types') {
      queryParams['type'] = type;
    }
    if (source != null && source.isNotEmpty && source != 'Parents & students') {
      queryParams['source'] = source;
    }
    if (category != null && category.isNotEmpty && category != 'All categories') {
      queryParams['category'] = category;
    }
    if (mine != null && mine.isNotEmpty && mine != "Everyone's") {
      queryParams['mine'] = mine;
    }
    if (q != null && q.trim().isNotEmpty) {
      queryParams['q'] = q.trim();
    }
    if (branchId != null && branchId > 0) {
      queryParams['branchId'] = branchId;
    }

    final uri = Uri.parse(ApiConstants.tickets).replace(
      queryParameters: queryParams.isNotEmpty
          ? queryParams.map((k, v) => MapEntry(k, v.toString()))
          : null,
    );
    final url = uri.toString();

    _logServiceCall(
      serviceMethod: 'getTickets',
      url: url,
      payload: queryParams,
    );

    try {
      final res = await _dioClient.dio.get(url);
      final parsedData = _safeParse(res.data);

      _logServiceCall(
        serviceMethod: 'getTickets',
        url: url,
        response: parsedData,
      );

      if (parsedData is Map<String, dynamic>) {
        return TicketListResponse.fromJson(parsedData);
      }
      return const TicketListResponse(items: [], counts: TicketCountsModel());
    } catch (e, stack) {
      debugPrint('[ComplaintsRepository] getTickets error: $e\n$stack');
      rethrow;
    }
  }

  Future<BatchTicketResponse> createBatchTickets(BatchTicketRequest request) async {
    const url = ApiConstants.ticketBatch;
    final payload = request.toJson();

    _logServiceCall(
      serviceMethod: 'createBatchTickets',
      url: url,
      payload: payload,
    );

    try {
      final res = await _dioClient.dio.post(url, data: payload);
      final parsedData = _safeParse(res.data);

      _logServiceCall(
        serviceMethod: 'createBatchTickets',
        url: url,
        response: parsedData,
      );

      if (parsedData is Map<String, dynamic>) {
        return BatchTicketResponse.fromJson(parsedData);
      }
      return const BatchTicketResponse(created: []);
    } on DioException catch (e) {
      final errorData = e.response?.data;
      String errorMsg = e.message ?? 'Server error occurred';
      if (errorData is Map<String, dynamic> && errorData['message'] != null) {
        errorMsg = errorData['message'].toString();
      }
      debugPrint('[ComplaintsRepository] createBatchTickets DioException: $errorMsg');
      throw Exception(errorMsg);
    } catch (e, stack) {
      debugPrint('[ComplaintsRepository] createBatchTickets error: $e\n$stack');
      rethrow;
    }
  }

  Future<TicketMetaModel> getTicketMeta({int? branchId, String? source}) async {
    final Map<String, dynamic> queryParams = {};
    if (branchId != null && branchId > 0) {
      queryParams['branchId'] = branchId;
    }
    if (source != null && source.isNotEmpty) {
      queryParams['source'] = source;
    }

    final uri = Uri.parse(ApiConstants.ticketMeta).replace(
      queryParameters: queryParams.isNotEmpty
          ? queryParams.map((k, v) => MapEntry(k, v.toString()))
          : null,
    );
    final url = uri.toString();

    _logServiceCall(
      serviceMethod: 'getTicketMeta',
      url: url,
      payload: queryParams,
    );

    try {
      final res = await _dioClient.dio.get(url);
      final parsedData = _safeParse(res.data);

      _logServiceCall(
        serviceMethod: 'getTicketMeta',
        url: url,
        response: parsedData,
      );

      if (parsedData is Map<String, dynamic>) {
        return TicketMetaModel.fromJson(parsedData);
      }
      return const TicketMetaModel();
    } catch (e, stack) {
      debugPrint('[ComplaintsRepository] getTicketMeta error: $e\n$stack');
      rethrow;
    }
  }

  Future<List<DraftItemModel>> getDrafts({String kind = 'ticket'}) async {
    final Map<String, dynamic> queryParams = {'kind': kind};
    final uri = Uri.parse(ApiConstants.drafts).replace(queryParameters: queryParams);
    final url = uri.toString();

    _logServiceCall(
      serviceMethod: 'getDrafts',
      url: url,
      payload: queryParams,
    );

    try {
      final res = await _dioClient.dio.get(url);
      final parsedData = _safeParse(res.data);

      _logServiceCall(
        serviceMethod: 'getDrafts',
        url: url,
        response: parsedData,
      );

      if (parsedData is List) {
        return parsedData
            .whereType<Map<String, dynamic>>()
            .map((item) => DraftItemModel.fromJson(item))
            .toList();
      }
      return [];
    } catch (e, stack) {
      debugPrint('[ComplaintsRepository] getDrafts error: $e\n$stack');
      return [];
    }
  }

  Future<DraftItemModel?> getDraftDetail(int id) async {
    final url = ApiConstants.draftDetail(id);

    _logServiceCall(
      serviceMethod: 'getDraftDetail',
      url: url,
      payload: {'id': id},
    );

    try {
      final res = await _dioClient.dio.get(url);
      final parsedData = _safeParse(res.data);

      _logServiceCall(
        serviceMethod: 'getDraftDetail',
        url: url,
        response: parsedData,
      );

      if (parsedData is Map<String, dynamic>) {
        return DraftItemModel.fromJson(parsedData);
      }
      return null;
    } catch (e, stack) {
      debugPrint('[ComplaintsRepository] getDraftDetail error: $e\n$stack');
      return null;
    }
  }

  Future<int?> saveDraft(DraftSaveRequest request) async {
    const url = ApiConstants.drafts;
    final payload = request.toJson();

    _logServiceCall(
      serviceMethod: 'saveDraft',
      url: url,
      payload: payload,
    );

    try {
      final res = await _dioClient.dio.post(url, data: payload);
      final parsedData = _safeParse(res.data);

      _logServiceCall(
        serviceMethod: 'saveDraft',
        url: url,
        response: parsedData,
      );

      if (parsedData is Map<String, dynamic> && parsedData['id'] != null) {
        return parsedData['id'] is int
            ? parsedData['id'] as int
            : int.tryParse(parsedData['id'].toString());
      }
      return 1;
    } catch (e, stack) {
      debugPrint('[ComplaintsRepository] saveDraft error: $e\n$stack');
      rethrow;
    }
  }

  Future<bool> deleteDraft(int id) async {
    final url = ApiConstants.draftDetail(id);

    _logServiceCall(
      serviceMethod: 'deleteDraft',
      url: url,
      payload: {'id': id},
    );

    try {
      final res = await _dioClient.dio.delete(url);
      final parsedData = _safeParse(res.data);

      _logServiceCall(
        serviceMethod: 'deleteDraft',
        url: url,
        response: parsedData,
      );
      return true;
    } catch (e, stack) {
      debugPrint('[ComplaintsRepository] deleteDraft error: $e\n$stack');
      return false;
    }
  }

  Future<TicketInsightsResponse> getTicketInsights({int? year, int? branchId}) async {
    final Map<String, dynamic> queryParams = {};
    if (year != null) {
      queryParams['year'] = year;
    }
    if (branchId != null && branchId > 0) {
      queryParams['branchId'] = branchId;
    }

    const url = ApiConstants.ticketInsights;
    _logServiceCall(
      serviceMethod: 'getTicketInsights',
      url: url,
      payload: queryParams,
    );

    try {
      final res = await _dioClient.dio.get(url, queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final parsedData = _safeParse(res.data);

      _logServiceCall(
        serviceMethod: 'getTicketInsights',
        url: url,
        response: parsedData,
      );

      if (parsedData is Map<String, dynamic>) {
        return TicketInsightsResponse.fromJson(parsedData);
      }
      return const TicketInsightsResponse();
    } on DioException catch (e) {
      final errorData = e.response?.data;
      String errorMsg = e.message ?? 'Server error occurred';
      if (errorData is Map<String, dynamic> && errorData['message'] != null) {
        errorMsg = errorData['message'].toString();
      }
      debugPrint('[ComplaintsRepository] getTicketInsights DioException: $errorMsg');
      throw Exception(errorMsg);
    } catch (e, stack) {
      debugPrint('[ComplaintsRepository] getTicketInsights error: $e\n$stack');
      rethrow;
    }
  }

  Future<List<LookupDepartmentModel>> getDepartments() async {
    const url = ApiConstants.departments;
    _logServiceCall(serviceMethod: 'getDepartments', url: url);

    try {
      final res = await _dioClient.dio.get(url);
      final parsedData = _safeParse(res.data);

      _logServiceCall(
        serviceMethod: 'getDepartments',
        url: url,
        response: parsedData,
      );

      if (parsedData is List) {
        return parsedData
            .map((e) => LookupDepartmentModel.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList();
      }
      return [];
    } catch (e, stack) {
      debugPrint('[ComplaintsRepository] getDepartments error: $e\n$stack');
      return [];
    }
  }

  Future<List<LookupBranchModel>> getBranches() async {
    const url = ApiConstants.branches;
    _logServiceCall(serviceMethod: 'getBranches', url: url);

    try {
      final res = await _dioClient.dio.get(url);
      final parsedData = _safeParse(res.data);

      _logServiceCall(
        serviceMethod: 'getBranches',
        url: url,
        response: parsedData,
      );

      if (parsedData is List) {
        return parsedData
            .map((e) => LookupBranchModel.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList();
      }
      return [];
    } catch (e, stack) {
      debugPrint('[ComplaintsRepository] getBranches error: $e\n$stack');
      return [];
    }
  }

  Future<List<LookupAssigneeModel>> getAssignees() async {
    const url = ApiConstants.assignees;
    _logServiceCall(serviceMethod: 'getAssignees', url: url);

    try {
      final res = await _dioClient.dio.get(url);
      final parsedData = _safeParse(res.data);

      _logServiceCall(
        serviceMethod: 'getAssignees',
        url: url,
        response: parsedData,
      );

      if (parsedData is List) {
        return parsedData
            .map((e) => LookupAssigneeModel.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList();
      }
      return [];
    } catch (e, stack) {
      debugPrint('[ComplaintsRepository] getAssignees error: $e\n$stack');
      return [];
    }
  }

  Future<TicketAttachmentModel> uploadFile({
    required String filePath,
    required String filename,
  }) async {
    const url = ApiConstants.uploads;
    _logServiceCall(
      serviceMethod: 'uploadFile',
      url: url,
      payload: {'filePath': filePath, 'filename': filename},
    );

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: filename),
      });

      final res = await _dioClient.dio.post(url, data: formData);
      final parsedData = _safeParse(res.data);

      _logServiceCall(
        serviceMethod: 'uploadFile',
        url: url,
        response: parsedData,
      );

      if (parsedData is Map<String, dynamic>) {
        return TicketAttachmentModel.fromJson(parsedData);
      }
      throw Exception('Invalid upload response structure');
    } catch (e, stack) {
      debugPrint('[ComplaintsRepository] uploadFile error: $e\n$stack');
      rethrow;
    }
  }

  Future<TicketItemModel> createTicket(CreateTicketRequest request) async {
    const url = ApiConstants.tickets;
    final payload = request.toJson();

    _logServiceCall(
      serviceMethod: 'createTicket',
      url: url,
      payload: payload,
    );

    try {
      final res = await _dioClient.dio.post(url, data: payload);
      final parsedData = _safeParse(res.data);

      _logServiceCall(
        serviceMethod: 'createTicket',
        url: url,
        response: parsedData,
      );

      if (parsedData is Map<String, dynamic>) {
        return TicketItemModel.fromJson(parsedData);
      }
      throw Exception('Failed to create ticket: unexpected response');
    } catch (e, stack) {
      debugPrint('[ComplaintsRepository] createTicket error: $e\n$stack');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getNotifications() async {
    const url = ApiConstants.notifications;
    _logServiceCall(serviceMethod: 'getNotifications', url: url);

    try {
      final res = await _dioClient.dio.get(url);
      final parsedData = _safeParse(res.data);

      _logServiceCall(
        serviceMethod: 'getNotifications',
        url: url,
        response: parsedData,
      );

      if (parsedData is Map<String, dynamic>) {
        return parsedData;
      }
      return {};
    } catch (e, stack) {
      debugPrint('[ComplaintsRepository] getNotifications error: $e\n$stack');
      return {};
    }
  }

  Future<TicketItemModel> getTicketById(int id) async {
    final url = '${ApiConstants.tickets}/$id';
    _logServiceCall(
      serviceMethod: 'getTicketById',
      url: url,
      payload: null,
    );

    try {
      final res = await _dioClient.dio.get(url);
      final parsedData = _safeParse(res.data);

      _logServiceCall(
        serviceMethod: 'getTicketById',
        url: url,
        response: parsedData,
      );

      if (parsedData is Map<String, dynamic>) {
        return TicketItemModel.fromJson(parsedData);
      }
      throw Exception('Failed to load ticket details: unexpected response');
    } catch (e, stack) {
      debugPrint('[ComplaintsRepository] getTicketById error: $e\n$stack');
      rethrow;
    }
  }

  Future<TicketItemModel> assignTicket(
    int id, {
    required List<int> assigneeIds,
    required String note,
  }) async {
    final url = '${ApiConstants.tickets}/$id/assign';
    final payload = {
      'assigneeIds': assigneeIds,
      'note': note,
    };

    _logServiceCall(
      serviceMethod: 'assignTicket',
      url: url,
      payload: payload,
    );

    try {
      final res = await _dioClient.dio.post(url, data: payload);
      final parsedData = _safeParse(res.data);

      _logServiceCall(
        serviceMethod: 'assignTicket',
        url: url,
        response: parsedData,
      );

      if (parsedData is Map<String, dynamic>) {
        return TicketItemModel.fromJson(parsedData);
      }
      throw Exception('Failed to assign ticket: unexpected response');
    } catch (e, stack) {
      debugPrint('[ComplaintsRepository] assignTicket error: $e\n$stack');
      rethrow;
    }
  }

  Future<TicketItemModel> resolveTicket(
    int id, {
    required String resolution,
    bool notifyParent = false,
  }) async {
    final url = '${ApiConstants.tickets}/$id/resolve';
    final payload = {
      'resolution': resolution,
      'notifyParent': notifyParent,
    };

    _logServiceCall(
      serviceMethod: 'resolveTicket',
      url: url,
      payload: payload,
    );

    try {
      final res = await _dioClient.dio.post(url, data: payload);
      final parsedData = _safeParse(res.data);

      _logServiceCall(
        serviceMethod: 'resolveTicket',
        url: url,
        response: parsedData,
      );

      if (parsedData is Map<String, dynamic>) {
        return TicketItemModel.fromJson(parsedData);
      }
      throw Exception('Failed to resolve ticket: unexpected response');
    } catch (e, stack) {
      debugPrint('[ComplaintsRepository] resolveTicket error: $e\n$stack');
      rethrow;
    }
  }

  Future<TicketItemModel> rejectTicket(
    int id, {
    required String reason,
  }) async {
    final url = '${ApiConstants.tickets}/$id/reject';
    final payload = {
      'reason': reason,
    };

    _logServiceCall(
      serviceMethod: 'rejectTicket',
      url: url,
      payload: payload,
    );

    try {
      final res = await _dioClient.dio.post(url, data: payload);
      final parsedData = _safeParse(res.data);

      _logServiceCall(
        serviceMethod: 'rejectTicket',
        url: url,
        response: parsedData,
      );

      if (parsedData is Map<String, dynamic>) {
        return TicketItemModel.fromJson(parsedData);
      }
      throw Exception('Failed to reject ticket: unexpected response');
    } catch (e, stack) {
      debugPrint('[ComplaintsRepository] rejectTicket error: $e\n$stack');
      rethrow;
    }
  }

  Future<TicketItemModel> updateTicket(
    int id,
    Map<String, dynamic> data,
  ) async {
    final url = '${ApiConstants.tickets}/$id';

    _logServiceCall(
      serviceMethod: 'updateTicket',
      url: url,
      payload: data,
    );

    try {
      final res = await _dioClient.dio.put(url, data: data);
      final parsedData = _safeParse(res.data);

      _logServiceCall(
        serviceMethod: 'updateTicket',
        url: url,
        response: parsedData,
      );

      if (parsedData is Map<String, dynamic>) {
        return TicketItemModel.fromJson(parsedData);
      }
      throw Exception('Failed to update ticket: unexpected response');
    } catch (e, stack) {
      debugPrint('[ComplaintsRepository] updateTicket error: $e\n$stack');
      rethrow;
    }
  }

  Future<TicketItemModel> awardTicket({
    required int ticketId,
    required int userId,
    required int points,
    required String reason,
  }) async {
    final url = ApiConstants.ticketAward(ticketId);
    final payload = {
      'userId': userId,
      'points': points,
      'reason': reason,
    };

    _logServiceCall(
      serviceMethod: 'awardTicket',
      url: url,
      payload: payload,
    );

    try {
      final res = await _dioClient.dio.post(url, data: payload);
      final parsedData = _safeParse(res.data);

      _logServiceCall(
        serviceMethod: 'awardTicket',
        url: url,
        response: parsedData,
      );

      if (parsedData is Map<String, dynamic>) {
        return TicketItemModel.fromJson(parsedData);
      }
      throw Exception('Failed to award ticket: unexpected response');
    } catch (e, stack) {
      debugPrint('[ComplaintsRepository] awardTicket error: $e\n$stack');
      rethrow;
    }
  }
}

