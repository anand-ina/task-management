import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/app_navigator.dart';
import '../../../core/utils/network_connectivity_service.dart';
import '../../../core/utils/preferences_service.dart';
import '../../../shared_widgets/dialogs/no_internet_dialog.dart';
import '../models/login_response.dart';
import '../models/user_profile.dart';

class AuthRepository {
  final DioClient _dioClient = DioClient();
  final PreferencesService _prefs = PreferencesService();

  static Map<String, dynamic>? _lastLoggedInUserMap;

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
    final cleanInput = email.trim();
    final cleanPass = password.trim();

    // Check internet connection before calling login API
    final isConnected = await NetworkConnectivityService().checkConnection();
    if (!isConnected) {
      final context = AppNavigator.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        NoInternetDialog.show(context);
      }
      throw Exception('No internet connection. Please connect to the internet.');
    }

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.login,
        data: {
          'identifier': cleanInput,
          'password': cleanPass,
        },
      );

      final data = _safeParse(response.data);
      final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
      final loginRes = LoginResponse.fromJson(map);
      if (loginRes.token.isNotEmpty) {
        await _prefs.saveToken(loginRes.token);
        if (loginRes.user != null) {
          await _prefs.saveUserMe(loginRes.user!);
          final u = loginRes.user!;
          await _prefs.saveUserDetails(
            name: u['name']?.toString() ?? u['username']?.toString(),
            email: u['email']?.toString(),
            id: u['id'] is int ? u['id'] as int : int.tryParse(u['id']?.toString() ?? ''),
          );
        }
        if (loginRes.role != null && loginRes.role!.isNotEmpty) {
          await _prefs.saveUserRole(
            loginRes.role!,
            roleLabel: loginRes.roleLabel ?? loginRes.role!,
          );
        }
        return loginRes;
      }
      throw Exception('Login failed: Invalid server response.');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errData = _safeParse(e.response!.data);
        if (errData is Map<String, dynamic> && errData.containsKey('message')) {
          throw Exception(errData['message'].toString());
        }
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        final context = AppNavigator.navigatorKey.currentContext;
        if (context != null && context.mounted) {
          NoInternetDialog.show(context);
        }
        throw Exception('No internet connection. Please connect to the internet.');
      }
      throw Exception(e.message ?? 'Login failed. Please try again.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<UserProfile> getMe() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.me);
      final data = _safeParse(response.data);
      final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
      final userProfile = UserProfile.fromJson(map);
      await _prefs.saveUserMe(map);
      await _prefs.saveUserRole(userProfile.role, roleLabel: userProfile.roleLabel);
      await _prefs.saveUserDetails(
        name: userProfile.name,
        email: userProfile.email,
        id: userProfile.id,
      );
      return userProfile;
    } catch (_) {
      final localMap = await _prefs.getUserMe() ?? _lastLoggedInUserMap;
      if (localMap != null) {
        final profile = UserProfile.fromJson(localMap);
        await _prefs.saveUserRole(profile.role, roleLabel: profile.roleLabel);
        await _prefs.saveUserDetails(
          name: profile.name,
          email: profile.email,
          id: profile.id,
        );
        return profile;
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    _lastLoggedInUserMap = null;
    await _prefs.clearSession();
  }

  Future<Map<String, dynamic>> forgotPassword(String identifier) async {
    final cleanIdentifier = identifier.trim();
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.forgotPassword,
        data: {
          'identifier': cleanIdentifier,
        },
      );
      final data = _safeParse(response.data);
      if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final errData = _safeParse(e.response!.data);
        if (errData is Map<String, dynamic> && errData.containsKey('message')) {
          throw Exception(errData['message'].toString());
        }
      }
    }
    return {
      'ok': true,
      'message': 'If the account exists, a reset code has been sent.',
    };
  }

  Future<Map<String, dynamic>> resetPassword({
    required String identifier,
    required String code,
    required String newPassword,
  }) async {
    final cleanIdentifier = identifier.trim();
    final cleanCode = code.trim();
    final cleanPass = newPassword.trim();
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.resetPassword,
        data: {
          'identifier': cleanIdentifier,
          'code': cleanCode,
          'password': cleanPass,
        },
      );
      final data = _safeParse(response.data);
      if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final errData = _safeParse(e.response!.data);
        if (errData is Map<String, dynamic> && errData.containsKey('message')) {
          throw Exception(errData['message'].toString());
        }
      }
    }
    return {
      'ok': true,
      'message': 'Password reset successfully.',
    };
  }
}
