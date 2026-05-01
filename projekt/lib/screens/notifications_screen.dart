import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'auth_state.dart';
import 'home_screen.dart'
    show
    kPrimaryDark,
    kPrimaryLight,
    kSurface,
    kNavItems,
    kNavIconSize,
    kNavPadH,
    kNavPadV,
    kNavDotSize,
    NavBadge;
import 'chat_screen.dart' show ChatState, ChatScreen;
import 'profile_screen.dart';
import 'settings_screen.dart' show SettingsScreen;
import 'theme_state.dart';
import 'dart:convert';
import 'dart:async';

enum NotifType { joined, cancelled, reminder, newEvent, general }

class AppNotification {
  final String id;
  final String backendId;
  final NotifType type;
  final String title;
  final String body;
  final String? eventName;
  final String? eventLocation;
  final Color? accentColor;
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.backendId,
    required this.type,
    required this.title,
    required this.body,
    this.eventName,
    this.eventLocation,
    this.accentColor,
    required this.timestamp,
    this.isRead = false,
  });
}

class NotificationState {
  static final NotificationState instance = NotificationState._();
  NotificationState._();

  final List<AppNotification> _notifications = [];
  final List<VoidCallback> _listeners = [];

  List<AppNotification> get all => List.unmodifiable(_notifications);

  int get unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  void addListener(VoidCallback cb) => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);
  void _notify() {
    for (final cb in _listeners) cb();
  }

  void clearLocal() {
    _notifications.clear();
    _notify();
  }

  static Future<void> loadDeletedIds() async {}

  void replaceAll(List<AppNotification> notifications) {
    _notifications
      ..clear()
      ..addAll(notifications);
    _notify();
  }

  void push(AppNotification n) {
    if (_notifications.any((e) => e.id == n.id)) return;
    _notifications.insert(0, n);
    _notify();
  }

  Future<void> markAllRead() async {
    for (final n in _notifications) {
      n.isRead = true;
    }
    _notify();
    if (AuthState.instance.isLoggedIn) {
      try {
        await http.post(
          Uri.parse('http://localhost:8080/api/notifications/read'),
          headers: {
            'Authorization': 'Bearer ${AuthState.instance.accessToken}'
          },
        ).timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
  }

  Future<void> removeById(String localId) async {
    final notif = _notifications.firstWhere(
          (n) => n.id == localId,
      orElse: () => AppNotification(
        id: '',
        backendId: '',
        type: NotifType.general,
        title: '',
        body: '',
        timestamp: DateTime.now(),
      ),
    );
    if (notif.id.isEmpty) return;

    _notifications.removeWhere((n) => n.id == localId);
    _notify();

    if (AuthState.instance.isLoggedIn && notif.backendId.isNotEmpty) {
      try {
        await http.delete(
          Uri.parse(
              'http://localhost:8080/api/notifications/${notif.backendId}'),
          headers: {
            'Authorization': 'Bearer ${AuthState.instance.accessToken}'
          },
        ).timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
  }

  void remove(String id) => removeById(id);

  Future<void> clear() async {
    _notifications.clear();
    _notify();

    if (AuthState.instance.isLoggedIn) {
      try {
        await http.delete(
          Uri.parse('http://localhost:8080/api/notifications'),
          headers: {
            'Authorization': 'Bearer ${AuthState.instance.accessToken}'
          },
        ).timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
  }

  Future<void> onAttendanceChanged(
      String eventName,
      String location,
      Color cardColor,
      bool joined,
      ) async {
    if (!AuthState.instance.isLoggedIn) return;

    final colorHex =
        '#${cardColor.value.toRadixString(16).substring(2).toUpperCase()}';
    final type = joined ? 'joined_event' : 'cancelled_event';
    final title = joined ? 'Prijava potvrđena! 🎉' : 'Prijava otkazana';
    final body = joined
        ? 'Uspješno si se prijavio/la na "$eventName". Vidimo se tamo!'
        : 'Otkazao/la si sudjelovanje na "$eventName".';

    try {
      final resp = await http
          .post(
        Uri.parse('http://localhost:8080/api/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthState.instance.accessToken}',
        },
        body: jsonEncode({
          'type': type,
          'title': title,
          'body': body,
          'accentColor': colorHex,
        }),
      )
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes))['data']
        as Map<String, dynamic>;
        final backendId = data['id'].toString();
        push(AppNotification(
          id: 'backend_$backendId',
          backendId: backendId,
          type: joined ? NotifType.joined : NotifType.cancelled,
          title: title,
          body: body,
          eventName: eventName,
          eventLocation: location,
          accentColor: cardColor,
          timestamp: DateTime.now(),
        ));
      }
    } catch (_) {
      push(AppNotification(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        backendId: '',
        type: joined ? NotifType.joined : NotifType.cancelled,
        title: title,
        body: body,
        eventName: eventName,
        eventLocation: location,
        accentColor: cardColor,
        timestamp: DateTime.now(),
      ));
    }
  }
}

class NotificationPollingService {
  static Timer? _timer;

  static void start() {
    _timer?.cancel();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _poll());
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> _poll() async {
    if (!AuthState.instance.isLoggedIn) return;
    try {
      final resp = await http
          .get(
        Uri.parse('http://localhost:8080/api/notifications'),
        headers: {
          'Authorization': 'Bearer ${AuthState.instance.accessToken}'
        },
      )
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode == 401) return;
      if (resp.statusCode != 200) return;

      final list =
          jsonDecode(utf8.decode(resp.bodyBytes))['data'] as List? ?? [];

      final notifications = list.map((n) {
        final backendId = n['id'].toString();
        final type = switch (n['type'] as String? ?? '') {
          'joined_event' => NotifType.joined,
          'cancelled_event' => NotifType.cancelled,
          'new_event' => NotifType.newEvent,
          _ => NotifType.general,
        };

        Color accent = const Color(0xFF700D25);
        final c = n['accentColor'] as String?;
        if (c != null && c.length == 7 && c.startsWith('#')) {
          try {
            accent = Color(int.parse('FF${c.substring(1)}', radix: 16));
          } catch (_) {}
        }

        return AppNotification(
          id: 'backend_$backendId',
          backendId: backendId,
          type: type,
          title: n['title'] as String? ?? '',
          body: n['body'] as String? ?? '',
          accentColor: accent,
          timestamp:
          DateTime.tryParse(n['createdAt'] as String? ?? '') ??
              DateTime.now(),
          isRead: n['isRead'] == true,
        );
      }).toList();

      // Backend je source of truth — zamijeni cijelu listu
      NotificationState.instance.replaceAll(notifications);
    } catch (_) {}
  }
}

Future<void> seedWelcomeNotification(String displayName, String token) async {
  try {
    await http.post(
      Uri.parse('http://localhost:8080/api/notifications'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'type': 'general',
        'title': 'Dobrodošao/la na MeetCute, $displayName! 💘',
        'body': 'Tvoj profil je spreman. Istražuj događanja i upoznaj ljude!',
        'accentColor': '#700D25',
      }),
    ).timeout(const Duration(seconds: 8));
  } catch (_) {}
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl,
      _headerCtrl,
      _listCtrl,
      _navBarCtrl;
  late List<AnimationController> _navTapCtrls;

  late Animation<double> _entryFade, _headerFade, _listFade, _navBarSlide;
  late Animation<Offset> _headerSlide, _listSlide;

  int _selectedNavIndex = 2;

  @override
  void initState() {
    super.initState();
    NotificationState.instance.addListener(_rebuild);
    ChatState.instance.addListener(_rebuild);
    ThemeState.instance.addListener(_rebuild);

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _headerFade =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.20), end: Offset.zero)
            .animate(CurvedAnimation(
            parent: _headerCtrl, curve: Curves.easeOutCubic));

    _listCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _listFade = CurvedAnimation(parent: _listCtrl, curve: Curves.easeOut);
    _listSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _listCtrl, curve: Curves.easeOutCubic));

    _navBarCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _navBarSlide = Tween<double>(begin: 90, end: 0).animate(
        CurvedAnimation(parent: _navBarCtrl, curve: Curves.easeOutBack));

    _navTapCtrls = List.generate(
        5,
            (_) => AnimationController(
            vsync: this, duration: const Duration(milliseconds: 450)));
    _navTapCtrls[2].value = 1.0;

    _start();
  }

  Future<void> _start() async {
    _entryCtrl.forward();
    _headerCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _listCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _navBarCtrl.forward();
    await NotificationPollingService._poll();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) await NotificationState.instance.markAllRead();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    NotificationState.instance.removeListener(_rebuild);
    ChatState.instance.removeListener(_rebuild);
    ThemeState.instance.removeListener(_rebuild);
    _entryCtrl.dispose();
    _headerCtrl.dispose();
    _listCtrl.dispose();
    _navBarCtrl.dispose();
    for (final c in _navTapCtrls) c.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    HapticFeedback.selectionClick();
    _navTapCtrls[_selectedNavIndex].reverse();
    setState(() => _selectedNavIndex = index);
    _navTapCtrls[index].forward(from: 0.0);

    if (index == 0) {
      for (final c in _navTapCtrls) c.value = 0.0;
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    final screen = switch (index) {
      1 => const ChatScreen(),
      3 => const ProfileScreen(),
      4 => const SettingsScreen(),
      _ => null,
    };
    if (screen == null) {
      Navigator.pop(context);
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => screen,
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween<Offset>(
                begin: const Offset(0.04, 0), end: Offset.zero)
                .animate(
                CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    ).then((_) {
      if (!mounted) return;
      _navTapCtrls[index].reverse();
      _navTapCtrls[2].forward(from: 0.0);
      setState(() => _selectedNavIndex = 2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final notifs = NotificationState.instance.all;
    final isDark = ThemeState.instance.isDark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      color: isDark ? kDarkBg : kSurface,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FadeTransition(
          opacity: _entryFade,
          child: Column(children: [
            _buildHeader(mq),
            Expanded(
              child: FadeTransition(
                opacity: _listFade,
                child: SlideTransition(
                  position: _listSlide,
                  child:
                  notifs.isEmpty ? _buildEmpty() : _buildList(notifs),
                ),
              ),
            ),
            _buildNavBar(mq),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader(MediaQueryData mq) {
    final unread = NotificationState.instance.unreadCount;
    final isDark = ThemeState.instance.isDark;
    final primary = isDark ? kDarkPrimary : kLightPrimary;
    final cardBg = isDark ? kDarkCard : Colors.white;
    return FadeTransition(
      opacity: _headerFade,
      child: SlideTransition(
        position: _headerSlide,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 380),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(
                bottom:
                BorderSide(color: primary.withOpacity(0.06), width: 1)),
            boxShadow: [
              BoxShadow(
                  color: primary.withOpacity(0.07),
                  blurRadius: 22,
                  offset: const Offset(0, 5))
            ],
          ),
          padding: EdgeInsets.only(
              top: mq.padding.top + 18,
              left: 20,
              right: 20,
              bottom: 18),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                              color: primary,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8),
                          child: const Text('Obavijesti'),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: 10),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutBack,
                            builder: (_, v, child) =>
                                Transform.scale(scale: v, child: child),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 340),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text('$unread',
                                  style: TextStyle(
                                      color: isDark ? kDarkBg : Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                            color: primary.withOpacity(0.38),
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                        child: Text(
                            '${NotificationState.instance.all.length} obavijesti'),
                      ),
                    ],
                  ),
                ),
                if (NotificationState.instance.all.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showClearConfirm();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 340),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border:
                        Border.all(color: primary.withOpacity(0.12)),
                      ),
                      child: Text('Obriši sve',
                          style: TextStyle(
                              color: primary.withOpacity(0.70),
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
              ]),
        ),
      ),
    );
  }

  void _showClearConfirm() {
    final isDark = ThemeState.instance.isDark;
    final primary = isDark ? kDarkPrimary : kLightPrimary;
    final cardBg = isDark ? const Color(0xFF3A2A32) : Colors.white;
    final textCol = isDark ? const Color(0xFFEEE0E5) : kPrimaryDark;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1.0),
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutBack,
          builder: (_, v, child) =>
              Transform.scale(scale: v, child: child),
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                    color: primary.withOpacity(0.25),
                    blurRadius: 36,
                    offset: const Offset(0, 14))
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      shape: BoxShape.circle),
                  child: Icon(Icons.delete_sweep_rounded,
                      color: primary, size: 28)),
              const SizedBox(height: 14),
              Text('Obriši sve obavijesti?',
                  style: TextStyle(
                      color: textCol,
                      fontWeight: FontWeight.w800,
                      fontSize: 17)),
              const SizedBox(height: 8),
              Text('Sve obavijesti će biti trajno obrisane.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: textCol.withOpacity(0.55), fontSize: 13.5)),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                                color: textCol.withOpacity(0.20))),
                      ),
                      child: Text('Odustani',
                          style: TextStyle(
                              color: textCol.withOpacity(0.65),
                              fontSize: 14)),
                    )),
                const SizedBox(width: 10),
                Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor:
                        isDark ? kDarkBg : Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding:
                        const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        NotificationState.instance.clear();
                        HapticFeedback.mediumImpact();
                      },
                      child: const Text('Obriši',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    )),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final isDark = ThemeState.instance.isDark;
    final primary = isDark ? kDarkPrimary : kLightPrimary;
    final accent = isDark ? const Color(0xFF5A3A48) : kPrimaryLight;
    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutBack,
                builder: (_, v, __) => Transform.scale(
                    scale: v,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 380),
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [accent, primary.withOpacity(0.20)]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: primary.withOpacity(0.18),
                              blurRadius: 28,
                              offset: const Offset(0, 10))
                        ],
                      ),
                      child: Icon(Icons.notifications_none_rounded,
                          color: primary, size: 46),
                    )),
              ),
              const SizedBox(height: 24),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                    color: primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3),
                child: const Text('Sve je čisto!'),
              ),
              const SizedBox(height: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                    color: primary.withOpacity(isDark ? 0.65 : 0.40),
                    fontSize: 14,
                    height: 1.5),
                child: const Text('Nema novih obavijesti.',
                    textAlign: TextAlign.center),
              ),
            ]));
  }

  Widget _buildList(List<AppNotification> notifs) {
    final sorted = [...notifs]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final now = DateTime.now();
    final today = sorted
        .where((n) => now.difference(n.timestamp).inHours < 24)
        .toList();
    final earlier = sorted
        .where((n) => now.difference(n.timestamp).inHours >= 24)
        .toList();

    return RefreshIndicator(
      onRefresh: () => NotificationPollingService._poll(),
      color: kPrimaryDark,
      backgroundColor: Colors.white,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        children: [
          if (today.isNotEmpty) ...[
            _sectionLabel('Danas'),
            const SizedBox(height: 10),
            ...today.asMap().entries.map((e) => _NotifTile(
              key: ValueKey(e.value.id),
              notif: e.value,
              animDelay:
              Duration(milliseconds: e.key * 60),
              onDismiss: () => NotificationState.instance
                  .removeById(e.value.id),
            )),
          ],
          if (earlier.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionLabel('Ranije'),
            const SizedBox(height: 10),
            ...earlier.asMap().entries.map((e) => _NotifTile(
              key: ValueKey(e.value.id),
              notif: e.value,
              animDelay: Duration(
                  milliseconds: (today.length + e.key) * 60),
              onDismiss: () => NotificationState.instance
                  .removeById(e.value.id),
            )),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    final isDark = ThemeState.instance.isDark;
    final primary = isDark ? kDarkPrimary : kPrimaryDark;
    return Row(children: [
      Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(text,
          style: TextStyle(
              color: primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6)),
    ]);
  }

  Widget _buildNavBar(MediaQueryData mq) {
    final isDark = ThemeState.instance.isDark;
    final navBg = isDark ? kDarkCard : Colors.white;
    final primary = isDark ? kDarkPrimary : kLightPrimary;
    return AnimatedBuilder(
      animation: _navBarSlide,
      builder: (_, child) => Transform.translate(
          offset: Offset(0, _navBarSlide.value), child: child),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 380),
        decoration: BoxDecoration(
          color: navBg,
          border: Border(
              top:
              BorderSide(color: primary.withOpacity(0.06), width: 1)),
          boxShadow: [
            BoxShadow(
                color: primary.withOpacity(0.10),
                blurRadius: 28,
                offset: const Offset(0, -5))
          ],
        ),
        padding:
        EdgeInsets.only(bottom: mq.padding.bottom + 4, top: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, _buildNavItem),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isDark = ThemeState.instance.isDark;
    final navPrimary = isDark ? kDarkPrimary : kLightPrimary;
    final isSelected = _selectedNavIndex == index;
    final item = kNavItems[index];
    final notifUnread = NotificationState.instance.unreadCount;
    final showNotifBadge = index == 2 && !isSelected && notifUnread > 0;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: AnimatedBuilder(
        animation: _navTapCtrls[index],
        builder: (_, __) {
          final t = _navTapCtrls[index].value;
          final scale = isSelected
              ? 1.0 +
              0.16 *
                  Curves.elasticOut.transform(t.clamp(0.0, 1.0))
              : 1.0;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Transform.scale(
              scale: scale,
              child: Stack(clipBehavior: Clip.none, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: kNavPadH, vertical: kNavPadV),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? navPrimary.withOpacity(0.09)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                      isSelected ? item.selected : item.unselected,
                      color: isSelected
                          ? navPrimary
                          : navPrimary.withOpacity(0.25),
                      size: kNavIconSize),
                ),
                if (showNotifBadge)
                  Positioned(
                      top: 2,
                      right: 4,
                      child: NavBadge(count: notifUnread)),
              ]),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? kNavDotSize : 0,
              height: isSelected ? kNavDotSize : 0,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                  color: navPrimary, shape: BoxShape.circle),
            ),
          ]);
        },
      ),
    );
  }
}

class _NotifTile extends StatefulWidget {
  final AppNotification notif;
  final Duration animDelay;
  final VoidCallback onDismiss;
  const _NotifTile(
      {super.key,
        required this.notif,
        required this.animDelay,
        required this.onDismiss});
  @override
  State<_NotifTile> createState() => _NotifTileState();
}

class _NotifTileState extends State<_NotifTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _entryFade =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(CurvedAnimation(
            parent: _entryCtrl, curve: Curves.easeOutCubic));
    Future.delayed(widget.animDelay,
            () {if (mounted) _entryCtrl.forward();});
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notif;
    final accent = n.accentColor ?? kPrimaryDark;
    final isUnread = !n.isRead;
    final isDark = ThemeState.instance.isDark;
    final cardBg = isDark ? const Color(0xFF4A3A42) : Colors.white;
    final textCol =
    isDark ? const Color(0xFFEEE0E5) : kPrimaryDark;
    final bodyCol = textCol.withOpacity(
        isUnread ? (isDark ? 0.80 : 0.65) : (isDark ? 0.60 : 0.40));
    final timeCol = textCol.withOpacity(0.45);

    return FadeTransition(
      opacity: _entryFade,
      child: SlideTransition(
        position: _entrySlide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Dismissible(
            key: Key(n.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) {
              HapticFeedback.mediumImpact();
              widget.onDismiss();
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 22),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.red.withOpacity(0.15)),
              ),
              child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_rounded,
                        color: Colors.redAccent, size: 22),
                    SizedBox(height: 3),
                    Text('Obriši',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ]),
            ),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              child: AnimatedScale(
                scale: _pressed ? 0.98 : 1.0,
                duration: const Duration(milliseconds: 100),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isUnread
                          ? accent.withOpacity(isDark ? 0.45 : 0.20)
                          : textCol.withOpacity(
                          isDark ? 0.12 : 0.06),
                      width: isUnread ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUnread
                            ? accent.withOpacity(
                            isDark ? 0.18 : 0.10)
                            : (isDark
                            ? Colors.black.withOpacity(0.25)
                            : kPrimaryDark.withOpacity(0.05)),
                        blurRadius: isUnread ? 18 : 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 4,
                            decoration: BoxDecoration(
                              color: isUnread
                                  ? accent
                                  : Colors.transparent,
                              borderRadius:
                              const BorderRadius.horizontal(
                                  left: Radius.circular(20)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            child: _NotifIcon(
                                type: n.type,
                                accent: accent,
                                isDark: isDark),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    0, 14, 14, 14),
                                child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                                child: Text(n.title,
                                                    style: TextStyle(
                                                        color: textCol,
                                                        fontSize: 14.5,
                                                        fontWeight: isUnread
                                                            ? FontWeight.w800
                                                            : FontWeight.w700,
                                                        letterSpacing:
                                                        -0.2))),
                                            const SizedBox(width: 8),
                                            Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .end,
                                                children: [
                                                  if (isUnread)
                                                    Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration:
                                                        BoxDecoration(
                                                            color: accent,
                                                            shape: BoxShape
                                                                .circle)),
                                                  const SizedBox(
                                                      height: 3),
                                                  Text(
                                                      _formatTime(
                                                          n.timestamp),
                                                      style: TextStyle(
                                                          color: timeCol,
                                                          fontSize: 11.5,
                                                          fontWeight:
                                                          FontWeight
                                                              .w500)),
                                                ]),
                                          ]),
                                      const SizedBox(height: 4),
                                      Text(n.body,
                                          style: TextStyle(
                                              color: bodyCol,
                                              fontSize: 13,
                                              height: 1.45)),
                                      if (n.eventName != null) ...[
                                        const SizedBox(height: 8),
                                        _EventChip(
                                            name: n.eventName!,
                                            location: n.eventLocation,
                                            color: accent,
                                            isDark: isDark),
                                      ],
                                    ]),
                              )),
                        ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'upravo';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _NotifIcon extends StatelessWidget {
  final NotifType type;
  final Color accent;
  final bool isDark;
  const _NotifIcon(
      {required this.type, required this.accent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      NotifType.joined => Icons.check_circle_rounded,
      NotifType.cancelled => Icons.cancel_rounded,
      NotifType.reminder => Icons.access_time_rounded,
      NotifType.newEvent => Icons.celebration_rounded,
      NotifType.general => Icons.favorite_rounded,
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: accent.withOpacity(isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(isDark ? 0.35 : 0.20)),
      ),
      child: Icon(icon, color: accent, size: 22),
    );
  }
}

class _EventChip extends StatelessWidget {
  final String name;
  final String? location;
  final Color color;
  final bool isDark;
  const _EventChip(
      {required this.name,
        required this.location,
        required this.color,
        required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: color.withOpacity(isDark ? 0.35 : 0.18)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.event_rounded, color: color, size: 13),
        const SizedBox(width: 5),
        Flexible(
            child: Text(
              location != null ? '$name · $location' : name,
              style: TextStyle(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
      ]),
    );
  }
}