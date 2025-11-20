import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Сервис для хранения данных аутентификации
class AuthStorageService {
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserRole = 'user_role';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyIsLoggedIn = 'is_logged_in';

  /// Сохранить данные пользователя
  Future<void> saveUserData({
    required String userId,
    required String email,
    required String role,
    bool rememberMe = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserId, userId);
      await prefs.setString(_keyUserEmail, email);
      await prefs.setString(_keyUserRole, role);
      await prefs.setBool(_keyRememberMe, rememberMe);
      await prefs.setBool(_keyIsLoggedIn, true);
      debugPrint('✅ User data saved: $email, remember: $rememberMe');
    } catch (e) {
      debugPrint('❌ Error saving user data: $e');
    }
  }

  /// Получить ID пользователя
  Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserId);
    } catch (e) {
      debugPrint('❌ Error getting user ID: $e');
      return null;
    }
  }

  /// Получить email пользователя
  Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserEmail);
    } catch (e) {
      debugPrint('❌ Error getting user email: $e');
      return null;
    }
  }

  /// Получить роль пользователя
  Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserRole);
    } catch (e) {
      debugPrint('❌ Error getting user role: $e');
      return null;
    }
  }

  /// Проверить, нужно ли запомнить пользователя
  Future<bool> shouldRememberUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyRememberMe) ?? false;
    } catch (e) {
      debugPrint('❌ Error checking remember me: $e');
      return false;
    }
  }

  /// Проверить, залогинен ли пользователь
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLogged = prefs.getBool(_keyIsLoggedIn) ?? false;
      final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
      return isLogged && rememberMe;
    } catch (e) {
      debugPrint('❌ Error checking login status: $e');
      return false;
    }
  }

  /// Очистить все данные пользователя (logout)
  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserRole);
      await prefs.remove(_keyRememberMe);
      await prefs.remove(_keyIsLoggedIn);
      debugPrint('✅ User data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing user data: $e');
    }
  }

  /// Получить все сохраненные данные пользователя
  Future<Map<String, dynamic>?> getSavedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_keyUserId);
      final email = prefs.getString(_keyUserEmail);
      final role = prefs.getString(_keyUserRole);
      final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;

      if (userId != null && email != null && role != null && rememberMe && isLoggedIn) {
        return {
          'userId': userId,
          'email': email,
          'role': role,
          'rememberMe': rememberMe,
        };
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting saved user data: $e');
      return null;
    }
  }

  /// Обновить статус remember me
  Future<void> updateRememberMe(bool rememberMe) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRememberMe, rememberMe);
      debugPrint('✅ Remember me updated: $rememberMe');
    } catch (e) {
      debugPrint('❌ Error updating remember me: $e');
    }
  }
}