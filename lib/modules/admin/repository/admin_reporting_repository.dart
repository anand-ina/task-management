import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/reporting_person_model.dart';

class AdminReportingRepository {
  final DioClient _dioClient = DioClient();

  Future<List<ReportingPersonModel>> getReportingPeople() async {
    const url = '${ApiConstants.baseUrl}/admin/reporting';
    debugPrint('[AdminReportingRepository] GET $url');
    try {
      final response = await _dioClient.dio.get(url);
      debugPrint('[AdminReportingRepository] Status: ${response.statusCode}');
      debugPrint('[AdminReportingRepository] Response: ${response.data}');

      final data = response.data;
      List<dynamic> peopleJson = [];
      if (data is Map<String, dynamic> && data.containsKey('people')) {
        peopleJson = data['people'] as List<dynamic>;
      } else if (data is List) {
        peopleJson = data;
      }

      return peopleJson
          .map((j) => ReportingPersonModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[AdminReportingRepository] Error: $e');
      rethrow;
    }
  }

  Future<bool> updateReporting({
    required int personId,
    required List<int> primary,
    required List<int> secondary,
  }) async {
    final url = '${ApiConstants.adminReporting}/$personId';
    final payload = {
      'primary': primary,
      'secondary': secondary,
    };
    debugPrint('[AdminReportingRepository] PATCH $url with $payload');
    try {
      final response = await _dioClient.dio.patch(url, data: payload);
      debugPrint('[AdminReportingRepository] Status: ${response.statusCode}');
      debugPrint('[AdminReportingRepository] Response: ${response.data}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[AdminReportingRepository] Error updateReporting: $e');
      return false;
    }
  }
}
