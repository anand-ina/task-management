import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/models/user_profile.dart';
import '../models/notification_preferences_model.dart';

class PreferencesOverviewData {
  final NotificationPreferencesModel preferences;
  final UserProfile userProfile;

  PreferencesOverviewData({
    required this.preferences,
    required this.userProfile,
  });
}

class PreferencesRepository {
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

  Future<PreferencesOverviewData> getPreferencesData() async {
    final results = await Future.wait([
      _dioClient.dio.get(ApiConstants.notificationPreferences),
      _dioClient.dio.get(ApiConstants.me),
    ]);

    final prefRes = _safeParse(results[0].data);
    NotificationPreferencesModel preferences = NotificationPreferencesModel.fromJson({});
    if (prefRes is Map<String, dynamic>) {
      preferences = NotificationPreferencesModel.fromJson(prefRes);
    }

    final userRes = _safeParse(results[1].data);
    UserProfile profile = UserProfile.fromJson({});
    if (userRes is Map<String, dynamic>) {
      profile = UserProfile.fromJson(userRes);
    }

    return PreferencesOverviewData(
      preferences: preferences,
      userProfile: profile,
    );
  }
}
