import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'chat_screen.dart' show ChatScreen, ChatState;
import 'profile_screen.dart';
import 'events_nearby.dart';
import 'organize_meetup.dart' show OrganizeMeetupScreen;
import 'notifications_screen.dart' show NotificationsScreen, NotificationState, seedStaticNotifications;
import 'settings_screen.dart' show SettingsScreen;
import 'theme_state.dart';


const Color kPrimaryDark   = Color(0xFF700D25);
const Color kPrimaryLight  = Color(0xFFF2E8E9);
const Color kGradientStart = Color(0xFF938083);
const Color kGradientEnd   = Color(0xFFEBEBEB);
const Color kGoldLock      = Color(0xFFE8C21A);
const Color kSurface       = Color(0xFFF5EDEF);
const Color kCardBg        = Colors.white;

const double kNavIconSize  = 24.0;
const double kNavPadH      = 12.0;
const double kNavPadV      = 6.0;
const double kNavDotSize   = 5.0;
const double kCardRadius   = 22.0;
const double kMenuPadH     = 18.0;
const double kMenuPadV     = 16.0;
const double kToggleW      = 44.0;
const double kToggleH      = 24.0;
const double kToggleKnob   = 18.0;
const double kContentPadH  = 16.0;
const double kHeaderFontSize = 20.0;
const double kHeaderIconSize = 22.0;
const double kHeaderPadH   = 20.0;
const double kHeaderPadV   = 12.0;

const List<_NavItem> kNavItems = [
  _NavItem(Icons.home_outlined,               Icons.home_rounded,          'Home'),
  _NavItem(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded,   'Chat'),
  _NavItem(Icons.notifications_none_rounded,  Icons.notifications_rounded, 'Alerts'),
  _NavItem(Icons.person_outline_rounded,      Icons.person_rounded,        'Profile'),
  _NavItem(Icons.settings_outlined,           Icons.settings_rounded,      'Settings'),
];

class _NavItem {
  final IconData unselected;
  final IconData selected;
  final String label;
  const _NavItem(this.unselected, this.selected, this.label);
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _locationEnabled = true;
  int _selectedNavIndex = 0;
  static const LatLng _defaultLoc = LatLng(45.8150, 15.9819);
  LatLng _userLocation = _defaultLoc;
  final MapController _mapController = MapController();

  late AnimationController _entryCtrl;
  late AnimationController _navBarCtrl;
  late AnimationController _blurCtrl;
  late AnimationController _avatarCtrl;
  late AnimationController _menuCtrl;
  late AnimationController _markerRingCtrl;
  late AnimationController _markerBobCtrl;
  late AnimationController _logoGlowCtrl;
  late List<AnimationController> _navTapCtrls;
  late List<AnimationController> _menuItemCtrls;

  late Animation<double> _entryFade;
  late Animation<double> _navBarSlide;
  late Animation<double> _blurAnim;
  late Animation<double> _avatarScale;
  late Animation<double> _menuFade;
  late Animation<Offset>  _menuSlide;
  late Animation<double> _markerRing;
  late Animation<double> _markerBob;
  late Animation<double> _logoGlow;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initAnims();
    _runEntry();
    _fetchLocation();
    seedStaticNotifications();
    NotificationState.instance.addListener(_onBadgeChanged);
    ChatState.instance.addListener(_onBadgeChanged);
    ThemeState.instance.addListener(_onBadgeChanged);
  }

  void _onBadgeChanged() {
    if (mounted) setState(() {});
  }

  void _initAnims() {
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    _navBarCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _navBarSlide = Tween<double>(begin: 90, end: 0)
        .animate(CurvedAnimation(parent: _navBarCtrl, curve: Curves.easeOutBack));

    _blurCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _blurAnim = CurvedAnimation(parent: _blurCtrl, curve: Curves.easeInOut);

    _avatarCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _avatarScale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _avatarCtrl, curve: Curves.elasticOut));

    _menuCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _menuFade = CurvedAnimation(parent: _menuCtrl, curve: Curves.easeOut);
    _menuSlide = Tween<Offset>(begin: const Offset(0, 0.20), end: Offset.zero)
        .animate(CurvedAnimation(parent: _menuCtrl, curve: Curves.easeOutCubic));

    _markerRingCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _markerRing = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _markerRingCtrl, curve: Curves.easeOut));

    _markerBobCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _markerBob = Tween<double>(begin: 0.0, end: -7.0)
        .animate(CurvedAnimation(parent: _markerBobCtrl, curve: Curves.easeInOut));

    _logoGlowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
    _logoGlow = CurvedAnimation(parent: _logoGlowCtrl, curve: Curves.easeInOut);

    _navTapCtrls = List.generate(5, (_) =>
        AnimationController(vsync: this, duration: const Duration(milliseconds: 450)));
    _navTapCtrls[0].value = 1.0;
    _menuItemCtrls = List.generate(3, (_) =>
        AnimationController(vsync: this, duration: const Duration(milliseconds: 120)));
  }

  void _runEntry() async {
    await Future.delayed(const Duration(milliseconds: 40));
    _entryCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _avatarCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 160));
    _menuCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _navBarCtrl.forward();
  }

  Future<void> _fetchLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
      _mapController.move(_userLocation, 15.5);
    } catch (_) {}
  }

  void _toggleLocation() {
    HapticFeedback.lightImpact();
    setState(() => _locationEnabled = !_locationEnabled);
    _locationEnabled ? _blurCtrl.reverse() : _blurCtrl.forward();
  }

  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    HapticFeedback.selectionClick();
    _navTapCtrls[_selectedNavIndex].reverse();
    setState(() => _selectedNavIndex = index);
    _navTapCtrls[index].forward(from: 0.0);

    Widget? screen;
    switch (index) {
      case 1: screen = const ChatScreen(); break;
      case 2: screen = const NotificationsScreen(); break;
      case 3: screen = const ProfileScreen(); break;
      case 4: screen = const SettingsScreen(); break;
      default: screen = null;
    }
    if (screen != null) {
      Navigator.push(context, PageRouteBuilder(
        pageBuilder: (_, a, __) => screen!,
        transitionsBuilder: (_, a, __, child) {
          if (index == 1) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: a, curve: Curves.easeIn),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1.0)
                    .animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
                child: child,
              ),
            );
          }
          return FadeTransition(opacity: a,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 380),
      )).then((_) {
        _navTapCtrls[index].reverse();
        _navTapCtrls[0].forward(from: 0.0);
        setState(() => _selectedNavIndex = 0);
      });
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => screen,
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 320),
    ));
  }

  void _showPremiumDialog() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.22), blurRadius: 48, offset: const Offset(0, 18))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 64, height: 64,
                  decoration: BoxDecoration(color: kGoldLock.withOpacity(0.13), shape: BoxShape.circle),
                  child: const Icon(Icons.star_rounded, color: kGoldLock, size: 32)),
              const SizedBox(height: 16),
              const Text('Premium 🔒',
                  style: TextStyle(color: kPrimaryDark, fontWeight: FontWeight.w800, fontSize: 20)),
              const SizedBox(height: 10),
              Text('Ova funkcija je dostupna samo Premium korisnicima. Otključaj sve i pronađi svog Cutieja! 💘',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kPrimaryDark.withOpacity(0.55), fontSize: 13.5, height: 1.5)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: kPrimaryDark.withOpacity(0.15))),
                  ),
                  child: Text('Kasnije', style: TextStyle(color: kPrimaryDark.withOpacity(0.5), fontSize: 14)),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryDark, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 13), elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Nadogradi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                )),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    NotificationState.instance.removeListener(_onBadgeChanged);
    ChatState.instance.removeListener(_onBadgeChanged);
    ThemeState.instance.removeListener(_onBadgeChanged);
    _entryCtrl.dispose(); _navBarCtrl.dispose(); _blurCtrl.dispose();
    _avatarCtrl.dispose(); _menuCtrl.dispose();
    _markerRingCtrl.dispose(); _markerBobCtrl.dispose(); _logoGlowCtrl.dispose();
    for (final c in _navTapCtrls) c.dispose();
    for (final c in _menuItemCtrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    final mapH = screenH * 0.50;
    const avatarD = 80.0;
    final isDark = ThemeState.instance.isDark;
    final bgColor = isDark ? kDarkBg : kSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      color: bgColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FadeTransition(
          opacity: _entryFade,
          child: Stack(children: [
            Positioned(
              top: 0, left: 0, right: 0,
              height: mapH,
              child: _buildMapCard(mq, mapH),
            ),
            Positioned(
              top: mapH + avatarD / 2 + 6,
              left: 0, right: 0, bottom: 0,
              child: FadeTransition(
                opacity: _menuFade,
                child: SlideTransition(
                  position: _menuSlide,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(kContentPadH, 10, kContentPadH, mq.padding.bottom + 90),
                    child: Column(children: [
                      _buildLocationToggle(),
                      const SizedBox(height: 18),
                      _buildSectionLabel('Plan za danas?'),
                      const SizedBox(height: 10),
                      _buildMenuCard(),
                    ]),
                  ),
                ),
              ),
            ),
            Positioned(
              top: mapH - avatarD / 2,
              left: 0, right: 0,
              child: Center(
                child: ScaleTransition(
                  scale: _avatarScale,
                  child: GestureDetector(
                    onTap: () => _onNavTap(3),
                    child: Stack(alignment: Alignment.center, children: [
                      Container(
                        width: avatarD + 12, height: avatarD + 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kPrimaryDark.withOpacity(0.08),
                        ),
                      ),
                      Container(
                        width: avatarD + 6, height: avatarD + 6,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                      ),
                      Container(
                        width: avatarD, height: avatarD,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kPrimaryLight,
                          boxShadow: [
                            BoxShadow(color: kPrimaryDark.withOpacity(0.25), blurRadius: 22, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: const Icon(Icons.person_rounded, color: kPrimaryDark, size: 42),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _buildNavBar(mq),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildMapCard(MediaQueryData mq, double mapH) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: kPrimaryDark.withOpacity(0.18), blurRadius: 28, offset: const Offset(0, 10)),
          BoxShadow(color: kPrimaryDark.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        child: AnimatedBuilder(
          animation: _blurAnim,
          builder: (_, child) => Stack(children: [
            child!,
            if (_blurAnim.value > 0)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: _blurAnim.value * 10, sigmaY: _blurAnim.value * 10),
                  child: Container(
                    color: kSurface.withOpacity(_blurAnim.value * 0.3),
                    child: Center(
                      child: Opacity(
                        opacity: _blurAnim.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          decoration: BoxDecoration(
                            color: kPrimaryDark,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.4), blurRadius: 20)],
                          ),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.visibility_off_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text('Lokacija isključena',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: mq.padding.top + 16,
              left: 16,
              child: _AnimatedLogo(glowAnim: _logoGlow),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0, height: 72,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, kSurface.withOpacity(0.7)],
                  ),
                ),
              ),
            ),
          ]),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation,
              initialZoom: 15.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.meetcute.app',
                maxZoom: 20,
                retinaMode: true,
              ),
              MarkerLayer(markers: [
                Marker(point: _userLocation, width: 60, height: 60, child: _buildMarker()),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarker() {
    return Stack(alignment: Alignment.center, children: [
      AnimatedBuilder(
        animation: _markerRing,
        builder: (_, __) {
          final t = _markerRing.value;
          return Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Container(
              width: 14 + t * 46, height: 14 + t * 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kPrimaryDark.withOpacity(0.50 * (1 - t)), width: 2),
              ),
            ),
          );
        },
      ),
      AnimatedBuilder(
        animation: _markerBob,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _markerBob.value),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: kPrimaryDark,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.45), blurRadius: 10, offset: const Offset(0, 4))],
              ),
            ),
            Container(width: 3, height: 9,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [kPrimaryDark, kPrimaryDark.withOpacity(0.0)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                )),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildLocationToggle() {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? kDarkPrimary : kLightPrimary;
    final cardBg  = isDark ? kDarkCard : Colors.white;
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      GestureDetector(
        onTap: _toggleLocation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 340),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withOpacity(0.10), width: 1),
            boxShadow: [BoxShadow(color: primary.withOpacity(0.10), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _locationEnabled ? Icons.location_on_rounded : Icons.location_off_rounded,
                key: ValueKey(_locationEnabled),
                color: _locationEnabled ? primary : primary.withOpacity(0.28),
                size: 15,
              ),
            ),
            const SizedBox(width: 7),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 13),
              child: const Text('Lokacija'),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: kToggleW, height: kToggleH,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kToggleH / 2),
                color: _locationEnabled ? primary : primary.withOpacity(0.10),
                border: Border.all(color: primary.withOpacity(0.18)),
              ),
              child: Stack(children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300), curve: Curves.easeInOutBack,
                  left: _locationEnabled ? kToggleW - kToggleKnob - 3 : 3,
                  top: (kToggleH - kToggleKnob) / 2,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: kToggleKnob, height: kToggleKnob,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _locationEnabled
                          ? (isDark ? kDarkBg : Colors.white)
                          : primary.withOpacity(0.28),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4)],
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildSectionLabel(String text) {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? kDarkPrimary : kLightPrimary;
    return Row(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 340),
        width: 4, height: 16,
        decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 8),
      AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 300),
        style: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        child: Text(text),
      ),
    ]);
  }

  Widget _buildMenuCard() {
    final isDark = ThemeState.instance.isDark;
    final cardBg  = isDark ? kDarkCard : Colors.white;
    final primary = isDark ? kDarkPrimary : kLightPrimary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: primary.withOpacity(0.06), width: 1),
        boxShadow: [
          BoxShadow(color: primary.withOpacity(0.10), blurRadius: 28, offset: const Offset(0, 8)),
          BoxShadow(color: primary.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: [
        _buildMenuItem(
          index: 0,
          icon: Icons.calendar_today_rounded,
          label: 'Događanja u blizini',
          subtitle: 'Otkrij aktivnosti oko sebe',
          isLocked: false,
          onTap: () => _navigateTo(const EventsNearbyScreen()),
          showDivider: true,
        ),
        // ── ORGANIZIRAJ SUSRET — OTKLJUČANO ─────────────────────────────────
        _buildMenuItem(
          index: 1,
          icon: Icons.coffee_rounded,
          label: 'Organiziraj susret',
          subtitle: 'Stvori vlastiti meetup ☕',
          isLocked: false,                           // <-- unlock
          onTap: () => _navigateTo(const OrganizeMeetupScreen()), // <-- novi screen
          showDivider: true,
        ),
        _buildMenuItem(
          index: 2,
          icon: Icons.tune_rounded,
          label: 'Filtriraj matcheve',
          subtitle: 'Pronađi savršenu osobu',
          isLocked: true,
          onTap: _showPremiumDialog,
          showDivider: false,
        ),
      ]),
    );
  }

  Widget _buildMenuItem({
    required int index, required IconData icon, required String label,
    required String subtitle, required bool isLocked,
    required VoidCallback onTap, required bool showDivider,
  }) {
    final isDark   = ThemeState.instance.isDark;
    final primary  = isDark ? kDarkPrimary : kLightPrimary;
    final accent   = isDark ? kPrimaryDark  : kPrimaryLight;
    return Column(children: [
      GestureDetector(
        onTapDown: (_) => _menuItemCtrls[index].forward(),
        onTapUp: (_) { _menuItemCtrls[index].reverse(); onTap(); },
        onTapCancel: () => _menuItemCtrls[index].reverse(),
        child: AnimatedBuilder(
          animation: _menuItemCtrls[index],
          builder: (_, __) => Transform.scale(
            scale: 1.0 - _menuItemCtrls[index].value * 0.018,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kMenuPadH, vertical: kMenuPadV),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 340),
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [accent, primary.withOpacity(0.12)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primary.withOpacity(0.08)),
                  ),
                  child: Icon(icon, color: primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 14.5),
                    child: Text(label),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(color: primary.withOpacity(0.40), fontSize: 12),
                    child: Text(subtitle),
                  ),
                ])),
                if (isLocked) Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: kGoldLock.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: kGoldLock.withOpacity(0.25)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.lock_rounded, color: kGoldLock, size: 11),
                    SizedBox(width: 3),
                    Text('PRO', style: TextStyle(color: kGoldLock, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ]),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 340),
                  width: 30, height: 30,
                  decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                  child: Icon(Icons.chevron_right, color: accent, size: 18),
                ),
              ]),
            ),
          ),
        ),
      ),
      if (showDivider) Container(
        margin: const EdgeInsets.symmetric(horizontal: kMenuPadH),
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent,
            primary.withOpacity(0.08),
            Colors.transparent,
          ]),
        ),
      ),
    ]);
  }

  Widget _buildNavBar(MediaQueryData mq) {
    final isDark = ThemeState.instance.isDark;
    final navBg  = isDark ? kDarkCard : Colors.white;
    final navPrimary = isDark ? kDarkPrimary : kLightPrimary;
    return AnimatedBuilder(
      animation: _navBarSlide,
      builder: (_, child) => Transform.translate(offset: Offset(0, _navBarSlide.value), child: child),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 380),
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: navPrimary.withOpacity(0.06), width: 1)),
          boxShadow: [BoxShadow(color: navPrimary.withOpacity(0.10), blurRadius: 30, offset: const Offset(0, -6))],
        ),
        padding: EdgeInsets.only(bottom: mq.padding.bottom + 4, top: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (i) => _buildNavItem(i)),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isDark = ThemeState.instance.isDark;
    final navPrimary = isDark ? kDarkPrimary : kLightPrimary;
    final isSelected = _selectedNavIndex == index;
    final item = kNavItems[index];
    final chatUnread  = ChatState.instance.totalUnread;
    final notifUnread = NotificationState.instance.unreadCount;
    final showChatBadge  = index == 1 && !isSelected && chatUnread > 0;
    final showNotifBadge = index == 2 && !isSelected && notifUnread > 0;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: AnimatedBuilder(
        animation: _navTapCtrls[index],
        builder: (_, __) {
          final t = _navTapCtrls[index].value;
          final scale = isSelected ? 1.0 + 0.16 * Curves.elasticOut.transform(t.clamp(0.0, 1.0)) : 1.0;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Transform.scale(scale: scale,
              child: Stack(clipBehavior: Clip.none, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: kNavPadH, vertical: kNavPadV),
                  decoration: BoxDecoration(
                    color: isSelected ? navPrimary.withOpacity(0.09) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(isSelected ? item.selected : item.unselected,
                      color: isSelected ? navPrimary : navPrimary.withOpacity(0.25),
                      size: kNavIconSize),
                ),
                if (showChatBadge) Positioned(top: 2, right: 4,
                  child: NavBadge(count: chatUnread),
                ),
                if (showNotifBadge) Positioned(top: 2, right: 4,
                  child: NavBadge(count: notifUnread),
                ),
              ]),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? kNavDotSize : 0, height: isSelected ? kNavDotSize : 0,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(color: navPrimary, shape: BoxShape.circle),
            ),
          ]);
        },
      ),
    );
  }
}


// animirani logo
class _AnimatedLogo extends StatefulWidget {
  final Animation<double> glowAnim;
  const _AnimatedLogo({required this.glowAnim});
  @override State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {

  late AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatCtrl, widget.glowAnim]),
      builder: (_, __) {
        final floatY = math.sin(_floatCtrl.value * math.pi) * 4.0;
        final aura   = widget.glowAnim.value;

        return Transform.translate(
          offset: Offset(0, floatY),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 115, height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryDark.withOpacity(0.30 + aura * 0.20),
                      blurRadius: 20 + aura * 14,
                      spreadRadius: -2,
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: kPrimaryDark.withOpacity(0.72),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.14),
                        width: 0.8,
                      ),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlassMapBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassMapBtn({required this.icon, required this.onTap});
  @override State<_GlassMapBtn> createState() => _GlassMapBtnState();
}

class _GlassMapBtnState extends State<_GlassMapBtn> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 90));
    _s = Tween<double>(begin: 1.0, end: 0.88).animate(CurvedAnimation(parent: _c, curve: Curves.easeIn));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(scale: _s,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
              ),
              child: Icon(widget.icon, color: Colors.white, size: 19),
            ),
          ),
        ),
      ),
    );
  }
}

class NavBadge extends StatelessWidget {
  final int count;
  const NavBadge({super.key, required this.count});
  @override
  Widget build(BuildContext context) {
    final label = count > 9 ? '9+' : '$count';
    return Container(
      width: 17, height: 17,
      decoration: const BoxDecoration(color: kPrimaryDark, shape: BoxShape.circle),
      child: Center(child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
    );
  }
}