import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/clone_task_models.dart';

/// Repository for Clone Task feature.
/// Every API call logs Request URL, payload (for POST), and response.
class CloneTaskRepository {
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

  // ---------------------------------------------------------------------------
  // GET /api/lookups/assignees
  // ---------------------------------------------------------------------------
  Future<List<AssigneeModel>> getAssignees() async {
    const url = ApiConstants.assignees;
    try {
      debugPrint('[CloneTaskRepository] GET $url');
      final response = await _dioClient.dio.get(url);
      debugPrint('[CloneTaskRepository] assignees → ${response.statusCode}: ${response.data}');
      final data = _safeParse(response.data);
      if (data is List) {
        return data
            .map((e) => AssigneeModel.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList();
      }
    } catch (e) {
      debugPrint('[CloneTaskRepository] getAssignees error: $e');
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // GET /api/lookups/branches
  // ---------------------------------------------------------------------------
  Future<List<BranchModel>> getBranches() async {
    const url = ApiConstants.branches;
    try {
      debugPrint('[CloneTaskRepository] GET $url');
      final response = await _dioClient.dio.get(url);
      debugPrint('[CloneTaskRepository] branches → ${response.statusCode}: ${response.data}');
      final data = _safeParse(response.data);
      if (data is List) {
        return data
            .map((e) => BranchModel.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList();
      }
    } catch (e) {
      debugPrint('[CloneTaskRepository] getBranches error: $e');
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // GET /api/lookups/enums
  // ---------------------------------------------------------------------------
  Future<Map<String, List<dynamic>>> getEnums() async {
    const url = ApiConstants.enums;
    try {
      debugPrint('[CloneTaskRepository] GET $url');
      final response = await _dioClient.dio.get(url);
      debugPrint('[CloneTaskRepository] enums → ${response.statusCode}: ${response.data}');
      final data = _safeParse(response.data);
      if (data is Map<String, dynamic>) {
        return {
          'priorities': data['priorities'] is List ? data['priorities'] as List<dynamic> : [],
          'statuses': data['statuses'] is List ? data['statuses'] as List<dynamic> : [],
        };
      }
    } catch (e) {
      debugPrint('[CloneTaskRepository] getEnums error: $e');
    }
    return {'priorities': [], 'statuses': []};
  }

  // ---------------------------------------------------------------------------
  // GET /api/tasks/next-id[?branchId=X]
  // ---------------------------------------------------------------------------
  Future<NextTaskIdModel?> getNextTaskId({int? branchId}) async {
    final url = branchId != null
        ? '${ApiConstants.tasksNextId}?branchId=$branchId'
        : ApiConstants.tasksNextId;
    try {
      debugPrint('[CloneTaskRepository] GET $url');
      final response = await _dioClient.dio.get(
        ApiConstants.tasksNextId,
        queryParameters: branchId != null ? {'branchId': branchId} : null,
      );
      debugPrint('[CloneTaskRepository] next-id → ${response.statusCode}: ${response.data}');
      final data = _safeParse(response.data);
      if (data is Map<String, dynamic>) {
        return NextTaskIdModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('[CloneTaskRepository] getNextTaskId error: $e');
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Fetch all lookups in parallel
  // ---------------------------------------------------------------------------
  Future<CloneTaskLookupsModel> fetchAllLookups({int? branchId}) async {
    final results = await Future.wait([
      getAssignees(),
      getBranches(),
      getEnums(),
      getNextTaskId(branchId: branchId),
    ]);

    final assignees = results[0] as List<AssigneeModel>;
    final branches = results[1] as List<BranchModel>;
    final enumsMap = results[2] as Map<String, List<dynamic>>;
    final nextId = results[3] as NextTaskIdModel?;

    final priorities = (enumsMap['priorities'] ?? [])
        .map((e) => EnumPriorityModel.fromJson(e is Map<String, dynamic> ? e : {}))
        .toList();
    final statuses = (enumsMap['statuses'] ?? [])
        .map((e) => EnumStatusModel.fromJson(e is Map<String, dynamic> ? e : {}))
        .toList();

    return CloneTaskLookupsModel(
      assignees: assignees,
      branches: branches,
      priorities: priorities,
      statuses: statuses,
      nextTaskNo: nextId?.taskNo ?? '',
    );
  }

  // ---------------------------------------------------------------------------
  // POST /api/tasks  — create cloned task
  // ---------------------------------------------------------------------------
  Future<bool> createTask(Map<String, dynamic> payload) async {
    const url = ApiConstants.tasks;
    try {
      debugPrint('[CloneTaskRepository] POST $url');
      debugPrint('[CloneTaskRepository] Payload: ${jsonEncode(payload)}');
      final response = await _dioClient.dio.post(url, data: payload);
      debugPrint('[CloneTaskRepository] createTask → ${response.statusCode}: ${response.data}');
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (e) {
      debugPrint('[CloneTaskRepository] createTask error: $e');
    }
    return false;
  }
}
