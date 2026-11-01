import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _userKey = 'saved_user_session';
  static const String _autoSaveKey = 'auto_save_media_to_gallery';

  final SharedPreferences prefs;

  StorageService({required this.prefs});

  UserModel? getSavedUser() {
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(UserModel user) async {
    final raw = jsonEncode(user.toJson());
    await prefs.setString(_userKey, raw);
  }

  bool hasValidToken() {
    final token = prefs.getString('accessToken');
    return token != null && token.isNotEmpty;
  }

  String? getAccessToken() => prefs.getString('accessToken');

  Future<void> clearUser() async {
    await prefs.remove(_userKey);
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('userId');
    await prefs.remove('userName');
  }

  bool getAutoSaveMedia() {
    return prefs.getBool(_autoSaveKey) ?? false;
  }

  Future<void> setAutoSaveMedia(bool enabled) async {
    await prefs.setBool(_autoSaveKey, enabled);
  }
}
