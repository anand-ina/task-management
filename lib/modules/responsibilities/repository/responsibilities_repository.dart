import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/responsibility_model.dart';

class ResponsibilitiesRepository {
  final DioClient _dioClient = DioClient();

  Future<ResponsibilitiesResponseModel> getResponsibilities() async {
    const url = ApiConstants.responsibilities;
    debugPrint('[ResponsibilitiesRepository] GET $url');
    try {
      final response = await _dioClient.dio.get(url);
      debugPrint('[ResponsibilitiesRepository] Status: ${response.statusCode}');
      debugPrint('[ResponsibilitiesRepository] Response: ${response.data}');
      return ResponsibilitiesResponseModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[ResponsibilitiesRepository] Error: $e');
      rethrow;
    }
  }
}
