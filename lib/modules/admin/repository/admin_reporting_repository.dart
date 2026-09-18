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
      return _fallbackPeople();
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

  List<ReportingPersonModel> _fallbackPeople() {
    return [
      const ReportingPersonModel(id: 1, name: 'Administrator', initials: 'AD', avatarColor: '#132a50', primary: [], secondary: [], level: 1),
      const ReportingPersonModel(id: 2, name: 'Madhumathi', initials: 'MA', avatarColor: '#e5484d', primary: [1], secondary: [], level: 2),
      const ReportingPersonModel(id: 3, name: 'Murali', initials: 'MU', avatarColor: '#30a46c', primary: [2], secondary: [], level: 3),
    ];
  }
}
