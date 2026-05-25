import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session_model.dart';

class AuthLocalDataSource {
  AuthLocalDataSource();

  static const sessionStorageKey = 'auth.session';
  AuthSessionModel? _cachedSession;
  bool _hasLoadedCache = false;

  Future<AuthSessionModel?> getSession() async {
    if (_hasLoadedCache) {
      return _cachedSession;
    }

    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(sessionStorageKey);
    if (raw == null || raw.isEmpty) {
      _cachedSession = null;
      _hasLoadedCache = true;
      return null;
    }

    _cachedSession = AuthSessionModel.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    _hasLoadedCache = true;
    return _cachedSession;
  }

  Future<void> saveSession(AuthSessionModel session) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      sessionStorageKey,
      jsonEncode(session.toJson()),
    );
    _cachedSession = session;
    _hasLoadedCache = true;
  }

  Future<void> clearSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(sessionStorageKey);
    _cachedSession = null;
    _hasLoadedCache = true;
  }
}
