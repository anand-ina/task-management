import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/my_profile_model.dart';

class ProfileRepository {
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

  Future<MyProfileModel> getMyProfile() async {
    final response = await _dioClient.dio.get(ApiConstants.staffMeProfile);
    final data = _safeParse(response.data);
    if (data is Map<String, dynamic>) {
      return MyProfileModel.fromJson(data);
    }
    return MyProfileModel.fromJson({});
  }
}
