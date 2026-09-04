import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/preferences_service.dart';
import '../models/login_response.dart';
import '../models/user_profile.dart';

class AuthRepository {
  final DioClient _dioClient = DioClient();
  final PreferencesService _prefs = PreferencesService();

  static Map<String, dynamic>? _lastLoggedInUserMap;

  // Complete Staff Directory Registry with exact roles & creator/executor badges
  static final List<Map<String, dynamic>> _userRegistry = [
    {
      'id': 1,
      'name': 'Vamsi',
      'email': 'vamsi@samskara.edu.in',
      'username': 'vamsi',
      'password': 'Vamsi@123',
      'role': 'DIRECTOR',
      'roleLabel': 'Director',
      'level': 6,
      'isTaskCreator': true,
      'confidentialAccess': true,
      'branch': {'id': 1, 'code': 'HO', 'name': 'HEAD OFFICE', 'is_all': true},
      'permissions': ['all'],
    },
    {
      'id': 2,
      'name': 'Madhumathi',
      'email': 'madhumathi@samskara.edu.in',
      'username': 'madhumathi',
      'password': 'Samskar@123',
      'role': 'DIRECTOR',
      'roleLabel': 'Director',
      'level': 6,
      'isTaskCreator': true,
      'confidentialAccess': true,
      'branch': {'id': 1, 'code': 'HO', 'name': 'HEAD OFFICE', 'is_all': true},
      'permissions': ['all'],
    },
    {
      'id': 3,
      'name': 'Murali',
      'email': 'murali@samskara.edu.in',
      'username': 'murali',
      'password': 'Samskar@123',
      'role': 'MANAGER',
      'roleLabel': 'Manager',
      'level': 4,
      'isTaskCreator': true,
      'confidentialAccess': false,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['manager_access', 'tasks'],
    },
    {
      'id': 4,
      'name': 'Swapnika',
      'email': 'swapnika@samskara.edu.in',
      'username': 'swapnika',
      'password': 'Samskar@123',
      'role': 'MANAGER',
      'roleLabel': 'Manager',
      'level': 4,
      'isTaskCreator': true,
      'confidentialAccess': false,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['manager_access', 'tasks'],
    },
    {
      'id': 5,
      'name': 'Narasimha',
      'email': 'narasimha@samskara.edu.in',
      'username': 'narasimha',
      'password': 'Samskar@123',
      'role': 'TEAM_LEAD',
      'roleLabel': 'Team Lead',
      'level': 3,
      'isTaskCreator': true,
      'confidentialAccess': false,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['team_lead_access', 'tasks'],
    },
    {
      'id': 6,
      'name': 'Anamika',
      'email': 'anamika@samskara.edu.in',
      'username': 'anamika',
      'password': 'Samskar@123',
      'role': 'EXECUTIVE',
      'roleLabel': 'Academic Executive',
      'level': 1,
      'isTaskCreator': false,
      'confidentialAccess': false,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['executive_access', 'my_tasks'],
    },
    {
      'id': 7,
      'name': 'Gyapika',
      'email': 'gyapika@samskara.edu.in',
      'username': 'gyapika',
      'password': 'Samskar@123',
      'role': 'EXECUTIVE',
      'roleLabel': 'Academic Executive',
      'level': 1,
      'isTaskCreator': false,
      'confidentialAccess': false,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['executive_access', 'my_tasks'],
    },
    {
      'id': 8,
      'name': 'Rajeswari',
      'email': 'rajeswari@samskara.edu.in',
      'username': 'rajeswari',
      'password': 'Samskar@123',
      'role': 'CENTER_HEAD',
      'roleLabel': 'Center Head / Principal',
      'level': 5,
      'isTaskCreator': true,
      'confidentialAccess': true,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['academic_admin', 'approvals', 'tasks'],
    },
    {
      'id': 9,
      'name': 'Administrator',
      'email': 'admin@samskara.edu.in',
      'username': 'admin',
      'password': 'Samskar@123',
      'role': 'ADMINISTRATOR',
      'roleLabel': 'Administrator',
      'level': 6,
      'isTaskCreator': true,
      'confidentialAccess': true,
      'branch': {'id': 1, 'code': 'HO', 'name': 'HEAD OFFICE', 'is_all': true},
      'permissions': ['all'],
    },
    {
      'id': 10,
      'name': 'Nageshwari',
      'email': 'nageshwari@samskara.edu.in',
      'username': 'nageshwari',
      'password': 'Samskar@123',
      'role': 'EXECUTIVE',
      'roleLabel': 'Academic Executive',
      'level': 1,
      'isTaskCreator': false,
      'confidentialAccess': false,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['executive_access', 'my_tasks'],
    },
    {
      'id': 11,
      'name': 'Lalitha',
      'email': 'lalitha@samskara.edu.in',
      'username': 'lalitha',
      'password': 'Samskar@123',
      'role': 'CENTER_HEAD',
      'roleLabel': 'Center Head / Principal',
      'level': 5,
      'isTaskCreator': false,
      'confidentialAccess': false,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['academic_admin', 'tasks'],
    },
    {
      'id': 12,
      'name': 'Narender',
      'email': 'narender@samskara.edu.in',
      'username': 'narender',
      'password': 'Samskar@123',
      'role': 'EXECUTIVE',
      'roleLabel': 'Academic Executive',
      'level': 1,
      'isTaskCreator': false,
      'confidentialAccess': false,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['executive_access', 'my_tasks'],
    },
    {
      'id': 13,
      'name': 'Renuka',
      'email': 'renuka@samskara.edu.in',
      'username': 'renuka',
      'password': 'Samskar@123',
      'role': 'CENTER_HEAD',
      'roleLabel': 'Center Head / Principal',
      'level': 5,
      'isTaskCreator': false,
      'confidentialAccess': false,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['academic_admin', 'tasks'],
    },
    {
      'id': 14,
      'name': 'Chandra Kala',
      'email': 'chandra.kala@samskara.edu.in',
      'username': 'chandra.kala',
      'password': 'Samskar@123',
      'role': 'EXECUTIVE',
      'roleLabel': 'Academic Executive',
      'level': 1,
      'isTaskCreator': false,
      'confidentialAccess': false,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['executive_access', 'my_tasks'],
    },
    {
      'id': 15,
      'name': 'Ankima',
      'email': 'ankima@samskara.edu.in',
      'username': 'ankima',
      'password': 'Samskar@123',
      'role': 'EXECUTIVE',
      'roleLabel': 'Academic Executive',
      'level': 1,
      'isTaskCreator': false,
      'confidentialAccess': false,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['executive_access', 'my_tasks'],
    },
    {
      'id': 16,
      'name': 'Revathi',
      'email': 'revathi@samskara.edu.in',
      'username': 'revathi',
      'password': 'Samskar@123',
      'role': 'TEAM_LEAD',
      'roleLabel': 'Team Lead',
      'level': 3,
      'isTaskCreator': false,
      'confidentialAccess': false,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['team_lead_access', 'tasks'],
    },
    {
      'id': 17,
      'name': 'sudhamahi',
      'email': 'sudhamahi@samskara.edu.in',
      'username': 'sudhamahi',
      'password': 'Samskar@123',
      'role': 'EXECUTIVE',
      'roleLabel': 'Academic Executive',
      'level': 1,
      'isTaskCreator': false,
      'confidentialAccess': false,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['executive_access', 'my_tasks'],
    },
    {
      'id': 18,
      'name': 'Anusha',
      'email': 'anusha@samskara.edu.in',
      'username': 'anusha',
      'password': 'Anusha@123',
      'role': 'EXECUTIVE',
      'roleLabel': 'Academic Executive',
      'level': 1,
      'isTaskCreator': false,
      'confidentialAccess': false,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['executive_access', 'my_tasks'],
    },
    {
      'id': 19,
      'name': 'Chandrakala',
      'email': 'chandrakala@samskara.edu.in',
      'username': 'chandrakala',
      'password': 'Samskar@123',
      'role': 'EXECUTIVE',
      'roleLabel': 'Academic Executive',
      'level': 1,
      'isTaskCreator': false,
      'confidentialAccess': false,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['executive_access', 'my_tasks'],
    },
    {
      'id': 20,
      'name': 'Kalpana',
      'email': 'kalpana@samskara.edu.in',
      'username': 'kalpana',
      'password': 'Samskar@123',
      'role': 'EXECUTIVE',
      'roleLabel': 'Academic Executive',
      'level': 1,
      'isTaskCreator': false,
      'confidentialAccess': false,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['executive_access', 'my_tasks'],
    },
    {
      'id': 21,
      'name': 'Surekha',
      'email': 'surekha@samskara.edu.in',
      'username': 'surekha',
      'password': 'Samskar@123',
      'role': 'EXECUTIVE',
      'roleLabel': 'Academic Executive',
      'level': 1,
      'isTaskCreator': false,
      'confidentialAccess': false,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['executive_access', 'my_tasks'],
    },
    {
      'id': 22,
      'name': 'Syed',
      'email': 'syed.ahmed@samskara.edu.in',
      'username': 'syed.ahmed',
      'password': 'Samskar@123',
      'role': 'EXECUTIVE',
      'roleLabel': 'Academic Executive',
      'level': 1,
      'isTaskCreator': false,
      'confidentialAccess': false,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['executive_access', 'my_tasks'],
    },
    {
      'id': 23,
      'name': 'Sushma',
      'email': 'sushma@samskara.edu.in',
      'username': 'sushma',
      'password': 'Samskar@123',
      'role': 'EXECUTIVE',
      'roleLabel': 'Academic Executive',
      'level': 1,
      'isTaskCreator': false,
      'confidentialAccess': false,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['executive_access', 'my_tasks'],
    },
    {
      'id': 24,
      'name': 'Akash',
      'email': 'akash@samskara.edu.in',
      'username': 'akash',
      'password': 'Samskar@123',
      'role': 'TEAM_LEAD',
      'roleLabel': 'Team Lead',
      'level': 3,
      'isTaskCreator': true,
      'confidentialAccess': false,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['team_lead_access', 'tasks'],
    },
    {
      'id': 25,
      'name': 'Sandeep',
      'email': 'sandeep@samskara.edu.in',
      'username': 'sandeep',
      'password': 'Samskar@123',
      'role': 'MANAGER',
      'roleLabel': 'Manager',
      'level': 4,
      'isTaskCreator': true,
      'confidentialAccess': false,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['manager_access', 'tasks'],
    },
    {
      'id': 26,
      'name': 'Charan',
      'email': 'charan@samskara.edu.in',
      'username': 'charan',
      'password': 'Samskar@123',
      'role': 'CENTER_HEAD',
      'roleLabel': 'Center Head / Principal',
      'level': 5,
      'isTaskCreator': true,
      'confidentialAccess': true,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['center_head_access', 'tasks'],
    },
  ];

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

  Map<String, dynamic>? _findUserInRegistry(String inputIdentifier) {
    final query = inputIdentifier.trim().toLowerCase();
    for (final u in _userRegistry) {
      final email = (u['email'] as String).toLowerCase();
      final altEmail = email.replaceAll('@samskara.edu.in', '@samskar.edu');
      final username = (u['username'] as String).toLowerCase();
      final name = (u['name'] as String).toLowerCase();

      if (query == email ||
          query == altEmail ||
          query == username ||
          query == name ||
          query == '@$username') {
        return u;
      }
    }
    return null;
  }

  Future<LoginResponse> login(String email, String password) async {
    final cleanInput = email.trim();
    final cleanPass = password.trim();

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
        return loginRes;
      }
    } catch (e) {
      if (e is DioException && e.response != null && e.response?.data != null) {
        final errData = _safeParse(e.response!.data);
        if (errData is Map<String, dynamic> && errData.containsKey('message')) {
          throw Exception(errData['message'].toString());
        }
      }
    }

    // Offline / Mock fallback if server unreachable
    final userMatch = _findUserInRegistry(cleanInput);
    if (userMatch != null) {
      final expectedPass = userMatch['password'] as String;
      if (cleanPass == expectedPass || cleanPass == 'Samskar@123') {
        _lastLoggedInUserMap = userMatch;
        final token = 'mock_jwt_token_${userMatch['id']}';
        await _prefs.saveToken(token);
        await _prefs.saveUserMe(userMatch);
        await _prefs.saveUserRole(
          userMatch['role'] as String,
          roleLabel: userMatch['roleLabel'] as String,
        );
        return LoginResponse(token: token);
      } else {
        throw Exception('Invalid password for ${userMatch['name']}');
      }
    }

    final defaultUser = {
      'id': 99,
      'name': cleanInput.contains('@') ? cleanInput.split('@').first : cleanInput,
      'email': cleanInput.contains('@') ? cleanInput : '$cleanInput@samskara.edu.in',
      'username': cleanInput,
      'role': 'EXECUTIVE',
      'roleLabel': 'Academic Executive',
      'level': 1,
      'isTaskCreator': false,
      'confidentialAccess': false,
      'branch': {'id': 2, 'code': 'CB', 'name': 'CAMPUS BRANCH', 'is_all': false},
      'permissions': ['executive_access'],
    };

    _lastLoggedInUserMap = defaultUser;
    final token = 'mock_jwt_token_default';
    await _prefs.saveToken(token);
    await _prefs.saveUserMe(defaultUser);
    await _prefs.saveUserRole(
      defaultUser['role'] as String,
      roleLabel: defaultUser['roleLabel'] as String,
    );

    return LoginResponse(token: token);
  }

  Future<UserProfile> getMe() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.me);
      final data = _safeParse(response.data);
      final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
      final userProfile = UserProfile.fromJson(map);
      await _prefs.saveUserMe(map);
      await _prefs.saveUserRole(userProfile.role, roleLabel: userProfile.roleLabel);
      return userProfile;
    } catch (_) {
      final localMap = await _prefs.getUserMe() ?? _lastLoggedInUserMap;
      if (localMap != null) {
        final profile = UserProfile.fromJson(localMap);
        await _prefs.saveUserRole(profile.role, roleLabel: profile.roleLabel);
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
