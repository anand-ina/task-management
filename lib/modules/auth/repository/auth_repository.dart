import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/preferences_service.dart';
import '../models/login_response.dart';
import '../models/user_profile.dart';

class AuthRepository {
  final DioClient _dioClient = DioClient();
  final PreferencesService _prefs = PreferencesService();

  Future<LoginResponse> login(String email, String password) async {
    final response = await _dioClient.dio.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    final loginRes = LoginResponse.fromJson(response.data);
    await _prefs.saveToken(loginRes.token);
    return loginRes;
  }

  Future<UserProfile> getMe() async {
    final response = await _dioClient.dio.get(ApiConstants.me);
    final userProfile = UserProfile.fromJson(response.data);
    await _prefs.saveUserMe(response.data);
    return userProfile;
  }

  Future<void> logout() async {
    await _prefs.clearSession();
  }
}
