import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  static const _key = 'cookpilot_device_user_id';
  AuthService._private();
  static final AuthService instance = AuthService._private();

  String? _cachedId;
  SharedPreferences? _prefs;

  Future<void> init() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    _cachedId = _prefs!.getString(_key);
    if (_cachedId == null) {
      final uuid = const Uuid().v4();
      await _prefs!.setString(_key, uuid);
      _cachedId = uuid;
    }
  }

  String getCurrentUserIdSync() {
    if (_cachedId == null) {
      throw StateError('AuthService not initialized. Call init() first.');
    }
    return _cachedId!;
  }

  Future<String> getCurrentUserId() async {
    if (_prefs == null) await init();
    return _cachedId!;
  }
}
