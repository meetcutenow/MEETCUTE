import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState extends ChangeNotifier {
  static final AuthState instance = AuthState._();
  AuthState._();

  String? _accessToken;
  String? _refreshToken;
  String? _userId;
  String? _username;
  String? _displayName;
  bool    _isPremium = false;

  String? get accessToken  => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get userId       => _userId;
  String? get username     => _username;
  String? get displayName  => _displayName;
  bool    get isPremium    => _isPremium;
  bool    get isLoggedIn   => _accessToken != null && _accessToken!.isNotEmpty;

  static const _kAccess      = 'auth_access_token';
  static const _kRefresh     = 'auth_refresh_token';
  static const _kUserId      = 'auth_user_id';
  static const _kUsername    = 'auth_username';
  static const _kDisplayName = 'auth_display_name';
  static const _kIsPremium   = 'auth_is_premium';

  static Future<bool> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kAccess);
    if (token == null || token.isEmpty) return false;

    instance._accessToken  = token;
    instance._refreshToken = prefs.getString(_kRefresh);
    instance._userId       = prefs.getString(_kUserId);
    instance._username     = prefs.getString(_kUsername);
    instance._displayName  = prefs.getString(_kDisplayName);
    instance._isPremium    = prefs.getBool(_kIsPremium) ?? false;
    return true;
  }

  Future<void> saveFromResponse(Map<String, dynamic> data) async {
    _accessToken  = data['accessToken'];
    _refreshToken = data['refreshToken'];
    final user    = data['user'] as Map<String, dynamic>? ?? {};
    _userId       = user['id'];
    _username     = user['username'];
    _displayName  = user['displayName'];
    _isPremium    = user['isPremium'] ?? false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccess,      _accessToken  ?? '');
    await prefs.setString(_kRefresh,     _refreshToken ?? '');
    await prefs.setString(_kUserId,      _userId       ?? '');
    await prefs.setString(_kUsername,    _username     ?? '');
    await prefs.setString(_kDisplayName, _displayName  ?? '');
    await prefs.setBool  (_kIsPremium,   _isPremium);

    notifyListeners();
  }

  Future<void> clear() async {
    _accessToken = _refreshToken = _userId = _username = _displayName = null;
    _isPremium = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
    await prefs.remove(_kUserId);
    await prefs.remove(_kUsername);
    await prefs.remove(_kDisplayName);
    await prefs.remove(_kIsPremium);

    notifyListeners();
  }
}