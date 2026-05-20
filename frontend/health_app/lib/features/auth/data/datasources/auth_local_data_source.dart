import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session_model.dart';

class AuthLocalDataSource {
  AuthLocalDataSource();

  static const sessionStorageKey = 'auth.session';

  Future<AuthSessionModel?> getSession() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(sessionStorageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return AuthSessionModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSession(AuthSessionModel session) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      sessionStorageKey,
      jsonEncode(session.toJson()),
    );
  }

  Future<void> clearSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(sessionStorageKey);
  }
}
