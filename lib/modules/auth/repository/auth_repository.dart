import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/preferences_service.dart';
import '../models/login_response.dart';
import '../models/user_profile.dart';

class AuthRepository {
  final DioClient _dioClient = DioClient();
  final PreferencesService _prefs = PreferencesService();

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

  Future<LoginResponse> login(String email, String password) async {
    final response = await _dioClient.dio.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = _safeParse(response.data);
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final loginRes = LoginResponse.fromJson(map);
    if (loginRes.token.isNotEmpty) {
      await _prefs.saveToken(loginRes.token);
    }
    return loginRes;
  }

  Future<UserProfile> getMe() async {
    final response = await _dioClient.dio.get(ApiConstants.me);
    final data = _safeParse(response.data);
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final userProfile = UserProfile.fromJson(map);
    await _prefs.saveUserMe(map);
    await _prefs.saveUserRole(userProfile.role, roleLabel: userProfile.roleLabel);
    return userProfile;
  }

  Future<void> logout() async {
    await _prefs.clearSession();
  }
}
