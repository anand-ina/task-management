import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../performance/models/performance_me_model.dart';
import '../models/fine_item_model.dart';
import '../models/fine_type_model.dart';

class FinesOverviewData {
  final List<FineItemModel> fines;
  final List<FineTypeModel> fineTypes;
  final PerformanceMeModel me;

  FinesOverviewData({
    required this.fines,
    required this.fineTypes,
    required this.me,
  });
}

class FinesRepository {
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
    debugPrint('---------------- [FinesRepository: $serviceMethod] ----------------');
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

  Future<FinesOverviewData> getFinesOverviewData() async {
    final results = await Future.wait([
      _dioClient.dio.get(ApiConstants.fines),
      _dioClient.dio.get(ApiConstants.finesTypes),
      _dioClient.dio.get(ApiConstants.performanceMe),
    ]);

    _logServiceCall(
      serviceMethod: 'getFines',
      url: ApiConstants.fines,
      response: results[0].data,
    );
    _logServiceCall(
      serviceMethod: 'getFineTypes',
      url: ApiConstants.finesTypes,
      response: results[1].data,
    );
    _logServiceCall(
      serviceMethod: 'getPerformanceMe',
      url: ApiConstants.performanceMe,
      response: results[2].data,
    );

    final res0 = _safeParse(results[0].data);
    List<FineItemModel> fines = [];
    if (res0 is List) {
      fines = res0.map((e) => FineItemModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
    }

    final res1 = _safeParse(results[1].data);
    List<FineTypeModel> fineTypes = [];
    if (res1 is List) {
      fineTypes = res1.map((e) => FineTypeModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
    }

    final res2 = _safeParse(results[2].data);
    PerformanceMeModel me = PerformanceMeModel(assigned: 0, done: 0, overdue: 0, points: 0);
    if (res2 is Map<String, dynamic>) {
      me = PerformanceMeModel.fromJson(res2);
    }

    return FinesOverviewData(
      fines: fines,
      fineTypes: fineTypes,
      me: me,
    );
  }

  Future<List<FineTypeModel>> getFineTypes() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.finesTypes);
      _logServiceCall(
        serviceMethod: 'getFineTypes',
        url: ApiConstants.finesTypes,
        response: response.data,
      );
      final res = _safeParse(response.data);
      if (res is List) {
        return res.map((e) => FineTypeModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
      }
      return [];
    } catch (e) {
      _logServiceCall(
        serviceMethod: 'getFineTypes',
        url: ApiConstants.finesTypes,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<FineTypeModel> addFineType({
    required String kind,
    required String label,
    required dynamic amount,
  }) async {
    final payload = {
      'kind': kind,
      'label': label,
      'amount': amount,
    };
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.finesTypes,
        data: payload,
      );
      _logServiceCall(
        serviceMethod: 'addFineType',
        url: ApiConstants.finesTypes,
        requestBody: payload,
        response: response.data,
      );
      final res = _safeParse(response.data);
      if (res is Map<String, dynamic>) {
        return FineTypeModel.fromJson(res);
      }
      return FineTypeModel(id: 0, kind: kind, label: label, amount: amount.toString());
    } catch (e) {
      _logServiceCall(
        serviceMethod: 'addFineType',
        url: ApiConstants.finesTypes,
        requestBody: payload,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<bool> deleteFineType(int id) async {
    final url = '${ApiConstants.finesTypes}/$id';
    try {
      final response = await _dioClient.dio.delete(url);
      _logServiceCall(
        serviceMethod: 'deleteFineType',
        url: url,
        response: response.data,
      );
      final res = _safeParse(response.data);
      if (res is Map<String, dynamic>) {
        return res['ok'] == true;
      }
      return response.statusCode == 200;
    } catch (e) {
      _logServiceCall(
        serviceMethod: 'deleteFineType',
        url: url,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<List<FineTypeModel>> updateFineTypes(List<Map<String, dynamic>> types) async {
    final payload = {'types': types};
    try {
      final response = await _dioClient.dio.put(
        ApiConstants.finesTypes,
        data: payload,
      );
      _logServiceCall(
        serviceMethod: 'updateFineTypes',
        url: ApiConstants.finesTypes,
        requestBody: payload,
        response: response.data,
      );
      final res = _safeParse(response.data);
      if (res is List) {
        return res.map((e) => FineTypeModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
      }
      return await getFineTypes();
    } catch (e) {
      _logServiceCall(
        serviceMethod: 'updateFineTypes',
        url: ApiConstants.finesTypes,
        requestBody: payload,
        error: e.toString(),
      );
      rethrow;
    }
  }
}
