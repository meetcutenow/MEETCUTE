import 'package:shared_preferences/shared_preferences.dart';

class CompanyAuthState {
  static final CompanyAuthState instance = CompanyAuthState._();
  CompanyAuthState._();

  String? _accessToken;
  String? _refreshToken;
  String? _companyId;
  String? _username;
  String? _orgName;
  String? _email;
  String? _logoUrl;

  String? get accessToken  => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get companyId    => _companyId;
  String? get username     => _username;
  String? get orgName      => _orgName;
  String? get email        => _email;
  String? get logoUrl      => _logoUrl;
  bool    get isLoggedIn   => _accessToken != null && _accessToken!.isNotEmpty;

  static const _kAccess    = 'company_access_token';
  static const _kRefresh   = 'company_refresh_token';
  static const _kId        = 'company_id';
  static const _kUsername  = 'company_username';
  static const _kOrgName   = 'company_org_name';
  static const _kEmail     = 'company_email';
  static const _kLogoUrl   = 'company_logo_url';

  static Future<bool> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kAccess);
    if (token == null || token.isEmpty) return false;
    instance._accessToken  = token;
    instance._refreshToken = prefs.getString(_kRefresh);
    instance._companyId    = prefs.getString(_kId);
    instance._username     = prefs.getString(_kUsername);
    instance._orgName      = prefs.getString(_kOrgName);
    instance._email        = prefs.getString(_kEmail);
    instance._logoUrl      = prefs.getString(_kLogoUrl);
    return true;
  }

  Future<void> saveFromResponse(Map<String, dynamic> data) async {
    _accessToken  = data['accessToken'];
    _refreshToken = data['refreshToken'];
    final c       = data['company'] as Map<String, dynamic>? ?? {};
    _companyId    = c['id'];
    _username     = c['username'];
    _orgName      = c['orgName'];
    _email        = c['email'];
    _logoUrl      = c['logoUrl'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccess,   _accessToken  ?? '');
    await prefs.setString(_kRefresh,  _refreshToken ?? '');
    await prefs.setString(_kId,       _companyId    ?? '');
    await prefs.setString(_kUsername, _username     ?? '');
    await prefs.setString(_kOrgName,  _orgName      ?? '');
    await prefs.setString(_kEmail,    _email        ?? '');
    if (_logoUrl != null) await prefs.setString(_kLogoUrl, _logoUrl!);
  }

  /// Ažurira samo profil podatke (bez tokena) — trajno u SharedPreferences
  Future<void> updateProfile({
    String? orgName,
    String? email,
    String? logoUrl,
  }) async {
    if (orgName != null) _orgName = orgName;
    if (email != null)   _email   = email;
    if (logoUrl != null) _logoUrl = logoUrl;

    final prefs = await SharedPreferences.getInstance();
    if (orgName != null) await prefs.setString(_kOrgName, orgName);
    if (email != null)   await prefs.setString(_kEmail,   email);
    if (logoUrl != null) await prefs.setString(_kLogoUrl, logoUrl);
  }

  Future<void> clear() async {
    _accessToken = _refreshToken = _companyId = _username = _orgName = _email = _logoUrl = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
    await prefs.remove(_kId);
    await prefs.remove(_kUsername);
    await prefs.remove(_kOrgName);
    await prefs.remove(_kEmail);
    await prefs.remove(_kLogoUrl);
  }
}