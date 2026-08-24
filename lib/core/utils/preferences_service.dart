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
  }
}
