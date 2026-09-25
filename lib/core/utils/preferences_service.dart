import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyToken = 'auth_token';
  static const String _keyUserMe = 'user_me_data';
  static const String _keyLanguage = 'selected_language';
  static const String _keyThemeMode = 'selected_theme_mode';

  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  // Token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static const String _keyAcademicYear = 'academic_year';
  static const String _keyAcademicYears = 'academic_years';

  // User Profile / Me Data
  Future<void> saveUserMe(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserMe, jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserMe() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyUserMe);
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // Academic Year / Years
  Future<void> saveAcademicYear(String year) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAcademicYear, year);
  }

  Future<String?> getAcademicYear() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAcademicYear);
  }

  Future<void> saveAcademicYears(List<int> years) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyAcademicYears, years.map((e) => e.toString()).toList());
  }

  Future<List<int>> getAcademicYears() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyAcademicYears);
    if (list != null && list.isNotEmpty) {
      final parsed = list.map((e) => int.tryParse(e)).whereType<int>().toList();
      if (parsed.isNotEmpty) return parsed;
    }
    return [];
  }

  // Language Code
  Future<void> saveLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, langCode);
  }

  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? 'en';
  }

  // Theme Mode (light, dark, system)
  Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) ?? 'light';
  }

  static const String _keyUserRole = 'user_role';
  static const String _keyUserRoleLabel = 'user_role_label';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserId = 'user_id';

  // User Role
  Future<void> saveUserRole(String role, {String? roleLabel}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserRole, role);
    if (roleLabel != null) {
      await prefs.setString(_keyUserRoleLabel, roleLabel);
    }
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole);
  }

  Future<String?> getUserRoleLabel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRoleLabel);
  }

  // User Name, Email, ID
  Future<void> saveUserDetails({String? name, String? email, int? id}) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null && name.isNotEmpty) {
      await prefs.setString(_keyUserName, name);
    }
    if (email != null && email.isNotEmpty) {
      await prefs.setString(_keyUserEmail, email);
    }
    if (id != null) {
      await prefs.setInt(_keyUserId, id);
    }
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  Future<bool> isAcademicExecutive() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(_keyUserRole)?.toLowerCase() ?? '';
    final roleLabel = prefs.getString(_keyUserRoleLabel)?.toLowerCase() ?? '';
    return role.contains('executive') || role.contains('ae') || roleLabel.contains('executive') || roleLabel.contains('ae');
  }

  // Clear session on Logout
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserMe);
    await prefs.remove(_keyUserRole);
    await prefs.remove(_keyUserRoleLabel);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserId);
  }
}
