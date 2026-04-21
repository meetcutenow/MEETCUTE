import 'package:shared_preferences/shared_preferences.dart';

/// Trajno pamti koji su razgovori i obavijesti označeni kao pročitani.
/// Preživljava restart aplikacije I odjavu.
class AppReadState {
  static const _kReadNotifIds = 'read_notif_ids';
  static const _kReadConvIds  = 'read_conv_ids';

  static final Set<String> _readNotifIds = {};
  static final Set<String> _readConvIds  = {};

  static SharedPreferences? _prefs;

  // Javna metoda za dohvat SharedPreferences instance
  static Future<SharedPreferences> getPrefsInstance() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── Učitaj pri pokretanju ──────────────────────────────────────────────────
  static Future<void> loadFromStorage() async {
    final prefs = await getPrefsInstance();
    final notifList = prefs.getStringList(_kReadNotifIds) ?? [];
    _readNotifIds.addAll(notifList);
    final convList = prefs.getStringList(_kReadConvIds) ?? [];
    _readConvIds.addAll(convList);
  }

  // ── Obavijesti ─────────────────────────────────────────────────────────────
  static bool isNotifRead(String id) => _readNotifIds.contains(id);

  static Future<void> markNotifRead(String id) async {
    if (_readNotifIds.contains(id)) return;
    _readNotifIds.add(id);
    await _saveNotifs();
  }

  static Future<void> markAllNotifsRead(List<String> ids) async {
    _readNotifIds.addAll(ids);
    await _saveNotifs();
  }

  static Future<void> _saveNotifs() async {
    final prefs = await getPrefsInstance();
    await prefs.setStringList(_kReadNotifIds, _readNotifIds.toList());
  }

  // ── Chat razgovori ─────────────────────────────────────────────────────────
  static bool isConvRead(String id) => _readConvIds.contains(id);

  static Future<void> markConvRead(String id) async {
    if (_readConvIds.contains(id)) return;
    _readConvIds.add(id);
    await _saveConvs();
  }

  static Future<void> _saveConvs() async {
    final prefs = await getPrefsInstance();
    await prefs.setStringList(_kReadConvIds, _readConvIds.toList());
  }

  // ── Čišćenje ───────────────────────────────────────────────────────────────
  static Future<void> clearAll() async {
    _readNotifIds.clear();
    _readConvIds.clear();
    final prefs = await getPrefsInstance();
    await prefs.remove(_kReadNotifIds);
    await prefs.remove(_kReadConvIds);
  }
}