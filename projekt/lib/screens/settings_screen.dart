import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'change_password_dialog.dart';
import 'home_screen.dart' show kPrimaryDark, kPrimaryLight, kSurface, kNavItems,
kNavIconSize, kNavPadH, kNavPadV, kNavDotSize, NavBadge;
import 'theme_state.dart';
import 'accessibility_state.dart';
import 'notifications_screen.dart' show NotificationState, NotificationsScreen, NotificationPollingService;
import 'chat_screen.dart' show ChatState, ChatScreen;
import 'profile_screen.dart';
import 'auth_state.dart';
import 'onboarding_screen.dart' show OnboardingScreen, RegistrationState;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {

  int _selectedNavIndex = 4;

  late final AnimationController _entryCtrl;
  late final AnimationController _navBarCtrl;
  late final List<AnimationController> _navTapCtrls;
  late final List<AnimationController> _rowCtrls;
  late final Animation<double> _entryFade;
  late final Animation<Offset>  _entrySlide;
  late final Animation<double> _navBarSlide;
  late final AnimationController _aboutCtrl;

  @override
  void initState() {
    super.initState();
    ThemeState.instance.addListener(_onTheme);
    NotificationState.instance.addListener(_onBadge);
    ChatState.instance.addListener(_onBadge);

    _entryCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _navBarCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _navBarSlide = Tween<double>(begin: 80, end: 0)
        .animate(CurvedAnimation(parent: _navBarCtrl, curve: Curves.easeOutBack));

    _navTapCtrls = List.generate(5,
            (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 450)));
    _navTapCtrls[4].value = 1.0;

    _rowCtrls = List.generate(10,
            (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 480)));

    _aboutCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 440));

    _runEntry();
  }

  Future<void> _runEntry() async {
    _entryCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 80));
    _navBarCtrl.forward();
    for (int i = 0; i < _rowCtrls.length; i++) {
      await Future.delayed(const Duration(milliseconds: 45));
      if (mounted) _rowCtrls[i].forward();
    }
  }

  void _onTheme() { if (mounted) setState(() {}); }
  void _onBadge() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeState.instance.removeListener(_onTheme);
    NotificationState.instance.removeListener(_onBadge);
    ChatState.instance.removeListener(_onBadge);
    _entryCtrl.dispose(); _navBarCtrl.dispose();
    _aboutCtrl.dispose();
    for (final c in _navTapCtrls) c.dispose();
    for (final c in _rowCtrls)    c.dispose();
    super.dispose();
  }

  bool  get _dark    => ThemeState.instance.isDark;
  Color get _bg      => _dark ? kDarkBg      : kSurface;
  Color get _card    => _dark ? kDarkCard    : Colors.white;
  Color get _primary => _dark ? kDarkPrimary : kPrimaryDark;
  Color get _accent  => _dark ? kDarkCardEl  : kPrimaryLight;

  void _toggleDark() {
    HapticFeedback.selectionClick();
    ThemeState.instance.toggle();
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1.0),
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(26),
              boxShadow: [BoxShadow(color: _primary.withOpacity(0.20), blurRadius: 36, offset: const Offset(0, 14))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 56, height: 56,
                  decoration: BoxDecoration(color: const Color(0xFFD93025).withOpacity(0.10), shape: BoxShape.circle),
                  child: const Icon(Icons.logout_rounded, color: Color(0xFFD93025), size: 28)),
              const SizedBox(height: 14),
              Text('Odjava', style: TextStyle(color: _primary, fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 8),
              Text('Sigurno se želiš odjaviti?', textAlign: TextAlign.center,
                  style: TextStyle(color: _primary.withOpacity(0.55), fontSize: 13.5)),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: _primary.withOpacity(0.20))),
                  ),
                  child: Text('Odustani', style: TextStyle(color: _primary.withOpacity(0.65), fontSize: 14)),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD93025), foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 13), elevation: 0,
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    NotificationState.instance.clearLocal();
                    NotificationPollingService.stop();
                    await AuthState.instance.clear();
                    RegistrationState.instance.isRegistered = false;
                    HapticFeedback.mediumImpact();
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      PageRouteBuilder(
                        pageBuilder: (_, a, __) => const OnboardingScreen(),
                        transitionsBuilder: (_, a, __, child) => FadeTransition(
                            opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
                        transitionDuration: const Duration(milliseconds: 500),
                      ),
                          (route) => false,
                    );
                  },
                  child: const Text('Odjavi se', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                )),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    HapticFeedback.selectionClick();

    if (index == 0) {
      for (final c in _navTapCtrls) c.value = 0.0;
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    _navTapCtrls[_selectedNavIndex].reverse();
    setState(() => _selectedNavIndex = index);
    _navTapCtrls[index].forward(from: 0.0);

    final screen = switch (index) {
      1 => const ChatScreen(),
      2 => const NotificationsScreen(),
      3 => const ProfileScreen(),
      _ => null,
    };
    if (screen == null) return;

    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => screen,
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 320),
    )).then((_) {
      if (!mounted) return;
      _navTapCtrls[index].reverse();
      _navTapCtrls[4].forward(from: 0.0);
      setState(() => _selectedNavIndex = 4);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      color: _bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FadeTransition(
          opacity: _entryFade,
          child: SlideTransition(
            position: _entrySlide,
            child: Column(children: [
              _buildHeader(mq),
              Expanded(child: _buildBody(mq)),
              _buildNavBar(mq),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(MediaQueryData mq) => AnimatedContainer(
    duration: const Duration(milliseconds: 380),
    color: _card,
    padding: EdgeInsets.only(top: mq.padding.top + 18, left: 20, right: 20, bottom: 22),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(color: _primary, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.8),
          child: const Text('Postavke'),
        ),
        const SizedBox(height: 2),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(color: _primary.withOpacity(0.38), fontSize: 13, fontWeight: FontWeight.w500),
          child: const Text('Personaliziraj MeetCute'),
        ),
      ])),
      _HeartDeco(primary: _primary, accent: _accent),
    ]),
  );

  Widget _buildBody(MediaQueryData mq) => SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: EdgeInsets.fromLTRB(18, 22, 18, mq.padding.bottom + 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      _sectionLabel('Izgled', 0),
      const SizedBox(height: 10),

      const _DarkModeCard(),

      const SizedBox(height: 28),

      _sectionLabel('Pristupačnost', 2),
      const SizedBox(height: 10),
      const _A11yPanel(),

      const SizedBox(height: 28),

      _sectionLabel('Račun', 8),
      const SizedBox(height: 10),
      _buildTapRow(ctrl: _rowCtrls[8], icon: Icons.lock_rounded,
          label: 'Promjena lozinke', subtitle: 'Ažuriraj svoju lozinku',
          onTap: () => ChangePasswordDialog.show(context, isCompany: false)),
      const SizedBox(height: 8),
      _buildTapRow(ctrl: _rowCtrls[8], icon: Icons.logout_rounded,
          label: 'Odjava', subtitle: 'Vidimo se uskoro!',
          danger: true, onTap: _logout),

      const SizedBox(height: 28),

      _sectionLabel('O nama', 9),
      const SizedBox(height: 10),
      _buildTapRow(ctrl: _rowCtrls[9], icon: Icons.favorite_rounded,
          label: 'O MeetCute', subtitle: 'Naša priča', onTap: _showAboutDialog),
      const SizedBox(height: 10),
      _buildContactRow(),
      const SizedBox(height: 32),
    ]),
  );

  Widget _sectionLabel(String text, int rowIdx) => FadeTransition(
    opacity: CurvedAnimation(parent: _rowCtrls[rowIdx], curve: Curves.easeOut),
    child: SlideTransition(
      position: Tween<Offset>(begin: const Offset(-0.04, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: _rowCtrls[rowIdx], curve: Curves.easeOutCubic)),
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(color: _primary.withOpacity(0.45), fontSize: 11.5,
              fontWeight: FontWeight.w700, letterSpacing: 1.2),
          child: Text(text.toUpperCase()),
        ),
      ),
    ),
  );

  Widget _buildTapRow({
    required AnimationController ctrl, required IconData icon,
    required String label, required String subtitle,
    required VoidCallback onTap, bool danger = false,
  }) {
    final color = danger ? const Color(0xFFD93025) : _primary;
    return FadeTransition(
      opacity: CurvedAnimation(parent: ctrl, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic)),
        child: _TapCard(
          card: _card, primary: _primary,
          accent: danger ? color.withOpacity(0.10) : _accent,
          icon: icon, iconColor: color,
          label: label, subtitle: subtitle, onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildContactRow() => FadeTransition(
    opacity: CurvedAnimation(parent: _rowCtrls[9], curve: Curves.easeOut),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 340),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 340),
          width: 44, height: 44,
          decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(13)),
          child: Icon(Icons.mail_outline_rounded, color: _primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(color: _primary, fontSize: 15.5, fontWeight: FontWeight.w700),
            child: const Text('Upiti i podrška'),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(color: _primary.withOpacity(0.55), fontSize: 12.5),
            child: const Text('meetcutenow@gmail.com'),
          ),
        ])),
        Icon(Icons.copy_outlined, color: _primary.withOpacity(0.25), size: 18),
      ]),
    ),
  );

  void _showAboutDialog() {
    HapticFeedback.mediumImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true, barrierLabel: 'close',
      barrierColor: Colors.black.withOpacity(0.50),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: MediaQuery.of(ctx).padding.top + 16),
              child: _AboutCard(primary: _primary, accent: _accent, card: _card,
                  onClose: () => Navigator.of(ctx).pop()),
            )),
          ),
        );
      },
    );
  }

  Widget _buildNavBar(MediaQueryData mq) => AnimatedBuilder(
    animation: _navBarSlide,
    builder: (_, child) => Transform.translate(offset: Offset(0, _navBarSlide.value), child: child),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 340),
      decoration: BoxDecoration(
        color: _card,
        border: Border(top: BorderSide(color: _primary.withOpacity(0.06), width: 1)),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.10), blurRadius: 28, offset: const Offset(0, -5))],
      ),
      padding: EdgeInsets.only(bottom: mq.padding.bottom + 4, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(5, _buildNavItem),
      ),
    ),
  );

  Widget _buildNavItem(int index) {
    final isSelected = _selectedNavIndex == index;
    final item        = kNavItems[index];
    final chatUnread  = ChatState.instance.totalUnread;
    final notifUnread = NotificationState.instance.unreadCount;
    final showChatBadge  = index == 1 && !isSelected && chatUnread > 0;
    final showNotifBadge = index == 2 && !isSelected && notifUnread > 0;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: AnimatedBuilder(
        animation: _navTapCtrls[index],
        builder: (_, __) {
          final t     = _navTapCtrls[index].value;
          final scale = isSelected ? 1.0 + 0.16 * Curves.elasticOut.transform(t.clamp(0.0, 1.0)) : 1.0;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Transform.scale(scale: scale,
              child: Stack(clipBehavior: Clip.none, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: kNavPadH, vertical: kNavPadV),
                  decoration: BoxDecoration(
                    color: isSelected ? _primary.withOpacity(0.09) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(isSelected ? item.selected : item.unselected,
                      color: isSelected ? _primary : _primary.withOpacity(0.30), size: kNavIconSize),
                ),
                if (showChatBadge)  Positioned(top: 2, right: 4, child: NavBadge(count: chatUnread)),
                if (showNotifBadge) Positioned(top: 2, right: 4, child: NavBadge(count: notifUnread)),
              ]),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? kNavDotSize : 0, height: isSelected ? kNavDotSize : 0,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(color: _primary, shape: BoxShape.circle),
            ),
          ]);
        },
      ),
    );
  }
}

class _DarkModeCard extends StatefulWidget {
  const _DarkModeCard();
  @override State<_DarkModeCard> createState() => _DarkModeCardState();
}

class _DarkModeCardState extends State<_DarkModeCard> {
  @override
  void initState() {
    super.initState();
    ThemeState.instance.addListener(_rebuild);
  }
  @override
  void dispose() {
    ThemeState.instance.removeListener(_rebuild);
    super.dispose();
  }
  void _rebuild() { if (mounted) setState(() {}); }

  void _toggle() {
    HapticFeedback.selectionClick();
    ThemeState.instance.toggle();
  }

  @override
  Widget build(BuildContext context) {
    final dark    = ThemeState.instance.isDark;
    final primary = dark ? kDarkPrimary : kPrimaryDark;
    final card    = dark ? kDarkCard    : Colors.white;
    final accent  = dark ? kDarkCardEl  : kPrimaryLight;

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: card, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withOpacity(0.08), width: 1),
          boxShadow: [BoxShadow(color: primary.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 5))],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(13)),
            child: Icon(dark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded, color: primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tamni mod', style: TextStyle(color: primary, fontSize: 15.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(dark ? 'Upaljeno' : 'Ugašeno',
                style: TextStyle(color: primary.withOpacity(0.42), fontSize: 12.5)),
          ])),
          _Toggle(value: dark, primary: primary, accent: accent, onTap: _toggle),
        ]),
      ),
    );
  }
}

class _A11yPanel extends StatelessWidget {
  const _A11yPanel();

  @override
  Widget build(BuildContext context) {
    final dark    = ThemeState.instance.isDark;
    final primary = dark ? kDarkPrimary : kPrimaryDark;
    final card    = dark ? kDarkCard    : Colors.white;
    final accent  = dark ? kDarkCardEl  : kPrimaryLight;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.accessibility_new_rounded, color: primary, size: 18),
          const SizedBox(width: 8),
          Text('Prilagodba prikaza',
              style: TextStyle(color: primary, fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        Text('Za osobe s disleksijom, slabovidnošću i sličnim poteškoćama',
            style: TextStyle(color: primary.withOpacity(0.45), fontSize: 12, height: 1.4)),
        const SizedBox(height: 16),

        Text('Veličina fonta', style: TextStyle(color: primary.withOpacity(0.55), fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ValueListenableBuilder<int>(
          valueListenable: AccessibilityState.fontSizeStep,
          builder: (_, step, __) => Row(children: [
            _FontBtn(label: 'A', size: 13, active: step == 0, primary: primary, accent: accent,
                onTap: () => AccessibilityState.setFontStep(0)),
            const SizedBox(width: 8),
            _FontBtn(label: 'A', size: 17, active: step == 1, primary: primary, accent: accent,
                onTap: () => AccessibilityState.setFontStep(1)),
            const SizedBox(width: 8),
            _FontBtn(label: 'A', size: 22, active: step == 2, primary: primary, accent: accent,
                onTap: () => AccessibilityState.setFontStep(2)),
          ]),
        ),

        const SizedBox(height: 16),
        Divider(color: primary.withOpacity(0.08), height: 1),
        const SizedBox(height: 16),

        ValueListenableBuilder<bool>(
          valueListenable: AccessibilityState.dyslexia,
          builder: (_, dys, __) => _A11yRow(
            icon: Icons.text_fields_rounded,
            label: 'Font za disleksiju',
            subtitle: 'OpenDyslexic font — lakše čitanje',
            active: dys,
            primary: primary,
            accent: accent,
            onTap: () { HapticFeedback.selectionClick(); AccessibilityState.toggleDyslexia(); },
          ),
        ),

        const SizedBox(height: 16),
        Divider(color: primary.withOpacity(0.08), height: 1),
        const SizedBox(height: 12),

        GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); AccessibilityState.reset(); },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primary.withOpacity(0.12)),
            ),
            child: Text('Poništi sve izmjene',
                textAlign: TextAlign.center,
                style: TextStyle(color: primary, fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

class _FontBtn extends StatelessWidget {
  final String label;
  final double size;
  final bool active;
  final Color primary, accent;
  final VoidCallback onTap;
  const _FontBtn({required this.label, required this.size, required this.active,
    required this.primary, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 52, height: 44,
      decoration: BoxDecoration(
        color: active ? primary : accent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? primary : primary.withOpacity(0.15), width: active ? 2 : 1),
      ),
      child: Center(child: Text(label,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w700,
            color: active ? (ThemeState.instance.isDark ? kDarkBg : Colors.white) : primary,
          ))),
    ),
  );
}

class _A11yRow extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool active;
  final Color primary, accent;
  final VoidCallback onTap;
  const _A11yRow({required this.icon, required this.label, required this.subtitle,
    required this.active, required this.primary, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Row(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: active ? primary.withOpacity(0.15) : accent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: active ? primary : primary.withOpacity(0.5), size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: primary, fontSize: 14,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600)),
        Text(subtitle, style: TextStyle(color: primary.withOpacity(0.42), fontSize: 12)),
      ])),

      AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 46, height: 26,
        decoration: BoxDecoration(
          color: active ? primary : primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(13),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          alignment: active ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? (ThemeState.instance.isDark ? kDarkBg : Colors.white) : Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4)],
              ),
            ),
          ),
        ),
      ),
    ]),
  );
}

class _Toggle extends StatelessWidget {
  final bool value;
  final Color primary, accent;
  final VoidCallback onTap;
  const _Toggle({required this.value, required this.primary, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic,
      width: 50, height: 28,
      decoration: BoxDecoration(
        color: value ? primary : primary.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 280), curve: Curves.easeOutBack,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? accent : Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 5, offset: const Offset(0, 2))],
            ),
          ),
        ),
      ),
    ),
  );
}

class _TapCard extends StatefulWidget {
  final Color card, primary, accent, iconColor;
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;
  const _TapCard({required this.card, required this.primary, required this.accent,
    required this.iconColor, required this.icon, required this.label,
    required this.subtitle, required this.onTap});
  @override State<_TapCard> createState() => _TapCardState();
}

class _TapCardState extends State<_TapCard> with SingleTickerProviderStateMixin {
  late AnimationController _press;
  @override
  void initState() { super.initState(); _press = AnimationController(vsync: this, duration: const Duration(milliseconds: 100)); }
  @override void dispose() { _press.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _press.forward(),
    onTapUp: (_) { _press.reverse(); widget.onTap(); },
    onTapCancel: () => _press.reverse(),
    child: AnimatedBuilder(
      animation: _press,
      builder: (_, child) => Transform.scale(scale: 1.0 - _press.value * 0.025, child: child),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 340),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: widget.card, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.primary.withOpacity(0.08)),
          boxShadow: [BoxShadow(color: widget.primary.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 5))],
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 340),
            width: 44, height: 44,
            decoration: BoxDecoration(color: widget.accent, borderRadius: BorderRadius.circular(13)),
            child: Icon(widget.icon, color: widget.iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.label,
                style: TextStyle(color: widget.iconColor, fontSize: 15.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(widget.subtitle,
                style: TextStyle(color: widget.primary.withOpacity(0.42), fontSize: 12.5)),
          ])),
          Icon(Icons.chevron_right_rounded, color: widget.primary.withOpacity(0.28), size: 22),
        ]),
      ),
    ),
  );
}

class _HeartDeco extends StatefulWidget {
  final Color primary, accent;
  const _HeartDeco({required this.primary, required this.accent});
  @override State<_HeartDeco> createState() => _HeartDecoState();
}
class _HeartDecoState extends State<_HeartDeco> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  @override
  void initState() { super.initState(); _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true); }
  @override void dispose() { _pulse.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _pulse,
    builder: (_, __) => Transform.scale(scale: 1.0 + _pulse.value * 0.08,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 340),
        width: 44, height: 44,
        decoration: BoxDecoration(color: widget.accent, borderRadius: BorderRadius.circular(13),
            boxShadow: [BoxShadow(color: widget.primary.withOpacity(0.15 + _pulse.value * 0.10), blurRadius: 14 + _pulse.value * 6, offset: const Offset(0, 4))]),
        child: Icon(Icons.settings_rounded, color: widget.primary, size: 22),
      ),
    ),
  );
}

class _AboutCard extends StatefulWidget {
  final Color primary, accent, card;
  final VoidCallback onClose;
  const _AboutCard({required this.primary, required this.accent, required this.card, required this.onClose});
  @override State<_AboutCard> createState() => _AboutCardState();
}
class _AboutCardState extends State<_AboutCard> with TickerProviderStateMixin {
  late AnimationController _sparkleCtrl;
  late AnimationController _floatCtrl;
  final List<_Sparkle> _sparkles = [];

  @override
  void initState() {
    super.initState();
    _sparkleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
    _floatCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    final rng = math.Random(42);
    for (int i = 0; i < 8; i++) {
      _sparkles.add(_Sparkle(x: rng.nextDouble(), y: rng.nextDouble() * 0.5, size: 4.0 + rng.nextDouble() * 5, phase: rng.nextDouble()));
    }
  }
  @override void dispose() { _sparkleCtrl.dispose(); _floatCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28, vertical: MediaQuery.of(context).padding.top + 16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 380),
          decoration: BoxDecoration(color: widget.card, borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: widget.primary.withOpacity(0.22), blurRadius: 40, offset: const Offset(0, 16)),
                BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 20, offset: const Offset(0, 6))]),
          child: ClipRRect(borderRadius: BorderRadius.circular(28),
            child: SingleChildScrollView(physics: const BouncingScrollPhysics(),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AnimatedBuilder(animation: _sparkleCtrl,
                  builder: (_, __) => SizedBox(height: 110, child: Stack(children: [
                    Positioned.fill(child: AnimatedContainer(duration: const Duration(milliseconds: 380),
                        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [widget.primary, widget.primary.withOpacity(0.75)])))),
                    ..._sparkles.map((s) {
                      final t = ((_sparkleCtrl.value + s.phase) % 1.0);
                      final opacity = math.sin(t * math.pi).clamp(0.0, 1.0);
                      return Positioned(left: s.x * 300, top: s.y * 110,
                          child: Opacity(opacity: opacity * 0.7, child: Icon(Icons.star_rounded, color: widget.accent, size: s.size)));
                    }),
                    AnimatedBuilder(animation: _floatCtrl, builder: (_, __) => Positioned(left: 24, top: 18 + _floatCtrl.value * 8,
                        child: Icon(Icons.favorite_rounded, color: widget.accent.withOpacity(0.30), size: 22))),
                    AnimatedBuilder(animation: _floatCtrl, builder: (_, __) => Positioned(right: 28, top: 28 - _floatCtrl.value * 6,
                        child: Icon(Icons.favorite_rounded, color: widget.accent.withOpacity(0.22), size: 16))),
                    Center(child: AnimatedBuilder(animation: _floatCtrl, builder: (_, __) =>
                        Transform.translate(offset: Offset(0, -4 + _floatCtrl.value * 8),
                            child: Container(width: 64, height: 64,
                                decoration: BoxDecoration(color: widget.accent.withOpacity(0.18), shape: BoxShape.circle,
                                    border: Border.all(color: widget.accent.withOpacity(0.35), width: 2)),
                                child: Icon(Icons.favorite_rounded, color: widget.accent, size: 32))))),
                  ])),
                ),
                Padding(padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                  child: Column(children: [
                    Text('O MeetCute ♡', textAlign: TextAlign.center,
                        style: TextStyle(color: widget.primary, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    const SizedBox(height: 14),
                    Text(
                      'MeetCute je nastao kao projekt dviju studentica, Lane i Iris, druge godine računarstva.'
                          'Ideja se rodila dok su sjedile u svom omiljenom kafiću, pile ledenu kavu i razmišljale o aplikaciji koja bi ljude spajala na malo drugačiji način.\n\n'
                          'Nisu željele napraviti još jednu swipe-left-swipe-right aplikaciju. Htjele su nešto toplije - mjesto gdje možeš upoznati ljude iz svog grada kroz stvarna događanja i druženja uživo.\n\n'
                          'Tako je nastao MeetCute - s idejom vraćanja upoznavanja u stvarni svijet. 🍵✨',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: widget.primary.withOpacity(0.72), fontSize: 14.5, height: 1.65),
                    ),
                    const SizedBox(height: 20),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: widget.accent.withOpacity(0.18), borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: widget.primary.withOpacity(0.10))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.coffee_rounded, color: widget.primary, size: 14),
                        const SizedBox(width: 6),
                        Flexible(child: Text('Napravljeno s ljubavlju i ledenom kavom', textAlign: TextAlign.center,
                            style: TextStyle(color: widget.primary.withOpacity(0.65), fontSize: 12.5, fontWeight: FontWeight.w600))),
                        const SizedBox(width: 6),
                        Icon(Icons.favorite_rounded, color: widget.primary, size: 12),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(onTap: widget.onClose,
                      child: AnimatedContainer(duration: const Duration(milliseconds: 340), height: 48,
                        decoration: BoxDecoration(color: widget.primary, borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: widget.primary.withOpacity(0.30), blurRadius: 16, offset: const Offset(0, 6))]),
                        child: Center(child: Text('Natrag',
                            style: TextStyle(color: widget.accent, fontSize: 15, fontWeight: FontWeight.w800))),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Sparkle {
  final double x, y, size, phase;
  const _Sparkle({required this.x, required this.y, required this.size, required this.phase});
}