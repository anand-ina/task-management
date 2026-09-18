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
      return _fallbackResponsibilities();
    }
  }

  ResponsibilitiesResponseModel _fallbackResponsibilities() {
    return const ResponsibilitiesResponseModel(
      person: ResponsibilityPersonModel(
        id: 14,
        name: 'Anusha',
        initials: 'AN',
        avatarColor: '#e5484d',
        designation: 'Admin Executive',
        department: 'Administration',
        branchName: 'Moti Nagar & Sanath Nagar',
        branchCode: 'SS01',
        level: 1,
        roleLabel: 'Admin Executive',
      ),
      canEdit: true,
      primary: [
        ResponsibilityItemModel(
          id: 13,
          kind: 'primary',
          text: 'Store',
          sort: 0,
        ),
      ],
      secondary: [],
    );
  }
}
