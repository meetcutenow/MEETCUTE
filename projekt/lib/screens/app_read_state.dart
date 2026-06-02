import 'package:shared_preferences/shared_preferences.dart';

class AppReadState {
  static const _kReadNotifIds = 'read_notif_ids';
  static const _kReadConvIds  = 'read_conv_ids';

  static final Set<String> _readNotifIds = {};
  static final Set<String> _readConvIds  = {};

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<void> loadFromStorage() async {
    final prefs = await _getPrefs();
    _readNotifIds.addAll(prefs.getStringList(_kReadNotifIds) ?? []);
    _readConvIds.addAll(prefs.getStringList(_kReadConvIds) ?? []);
  }

  static bool isNotifRead(String id) => _readNotifIds.contains(id);

  static Future<void> markNotifRead(String id) async {
    if (_readNotifIds.add(id)) await _save(_kReadNotifIds, _readNotifIds);
  }

  static Future<void> markAllNotifsRead(List<String> ids) async {
    _readNotifIds.addAll(ids);
    await _save(_kReadNotifIds, _readNotifIds);
  }

  static bool isConvRead(String id) => _readConvIds.contains(id);

  static Future<void> markConvRead(String id) async {
    if (_readConvIds.add(id)) await _save(_kReadConvIds, _readConvIds);
  }

  static Future<void> _save(String key, Set<String> data) async {
    final prefs = await _getPrefs();
    await prefs.setStringList(key, data.toList());
  }

  static Future<void> clearAll() async {
    _readNotifIds.clear();
    _readConvIds.clear();
    final prefs = await _getPrefs();
    await prefs.remove(_kReadNotifIds);
    await prefs.remove(_kReadConvIds);
  }
}