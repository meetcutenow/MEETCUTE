import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'home_screen.dart' show kPrimaryDark, kPrimaryLight, kSurface, kNavItems,
kNavIconSize, kNavPadH, kNavPadV, kNavDotSize, NavBadge;
import 'theme_state.dart';
import 'notifications_screen.dart' show NotificationState, NotificationsScreen;
import 'chat_screen.dart' show ChatState, ChatScreen;
import 'profile_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SETTINGS SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {

  int _selectedNavIndex = 4;

  // ── animacije ───────────────────────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final AnimationController _navBarCtrl;
  late final List<AnimationController> _navTapCtrls;
  late final List<AnimationController> _rowCtrls;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;
  late final Animation<double> _navBarSlide;

  // ── dark mode botun ───────────────────────────────────────────────────────
  late final AnimationController _toggleCtrl;
  late final Animation<double> _toggleKnob;

  // ── about us ──────────────────────────────────────────────────────────
  late final AnimationController _aboutCtrl;

  @override
  void initState() {
    super.initState();

    ThemeState.instance.addListener(_onTheme);
    NotificationState.instance.addListener(_onBadge);
    ChatState.instance.addListener(_onBadge);

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _navBarCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _navBarSlide = Tween<double>(begin: 80, end: 0)
        .animate(CurvedAnimation(parent: _navBarCtrl, curve: Curves.easeOutBack));

    _navTapCtrls = List.generate(5, (_) =>
        AnimationController(vsync: this, duration: const Duration(milliseconds: 450)));
    _navTapCtrls[4].value = 1.0;

    // staggered row animations
    _rowCtrls = List.generate(6, (_) =>
        AnimationController(vsync: this, duration: const Duration(milliseconds: 480)));

    // dark mode knob
    _toggleCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320),
      value: ThemeState.instance.isDark ? 1.0 : 0.0,
    );
    _toggleKnob = CurvedAnimation(parent: _toggleCtrl, curve: Curves.easeOutBack);

    _aboutCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 440));

    _runEntry();
  }

  Future<void> _runEntry() async {
    _entryCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 80));
    _navBarCtrl.forward();
    for (int i = 0; i < _rowCtrls.length; i++) {
      await Future.delayed(const Duration(milliseconds: 55));
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
    _entryCtrl.dispose(); _navBarCtrl.dispose(); _toggleCtrl.dispose();
    _aboutCtrl.dispose();
    for (final c in _navTapCtrls) c.dispose();
    for (final c in _rowCtrls) c.dispose();
    super.dispose();
  }

  // ── helperi ────────────────────────────────────────────────────────────────
  bool get _dark => ThemeState.instance.isDark;
  Color get _bg      => _dark ? kDarkBg      : kSurface;
  Color get _card    => _dark ? kDarkCard    : Colors.white;
  Color get _primary => _dark ? kDarkPrimary : kPrimaryDark;
  Color get _accent  => _dark ? kDarkCardEl  : kPrimaryLight;

  void _toggleDark() {
    HapticFeedback.selectionClick();
    ThemeState.instance.toggle();
    ThemeState.instance.isDark ? _toggleCtrl.forward() : _toggleCtrl.reverse();
  }

  // ── navigacija ────────────────────────────────────────────────────────────────────
  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    HapticFeedback.selectionClick();
    _navTapCtrls[_selectedNavIndex].reverse();
    setState(() => _selectedNavIndex = index);
    _navTapCtrls[index].forward(from: 0.0);

    Widget? screen;
    switch (index) {
      case 0: Navigator.pop(context); return;
      case 1: screen = const ChatScreen(); break;
      case 2: screen = const NotificationsScreen(); break;
      case 3: screen = const ProfileScreen(); break;
      default: return;
    }
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => screen!,
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 320),
    )).then((_) {
      _navTapCtrls[index].reverse();
      _navTapCtrls[4].forward(from: 0.0);
      setState(() => _selectedNavIndex = 4);
    });
  }


  // BUILD

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

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(MediaQueryData mq) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      color: _card,
      padding: EdgeInsets.only(
          top: mq.padding.top + 18, left: 20, right: 20, bottom: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: _primary, fontSize: 26,
                  fontWeight: FontWeight.w900, letterSpacing: -0.8,
                ),
                child: const Text('Postavke'),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: _primary.withOpacity(0.38), fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                child: const Text('Personaliziraj MeetCute'),
              ),
            ]),
          ),
          // decorative heart
          _HeartDeco(primary: _primary, accent: _accent),
        ]),
      ]),
    );
  }

  // ── BODY ────────────────────────────────────────────────────────────────────
  Widget _buildBody(MediaQueryData mq) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(18, 22, 18, mq.padding.bottom + 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ──Izgled ─────────────────────────────────────────────────
        _sectionLabel('Izgled', 0),
        const SizedBox(height: 10),
        _buildDarkModeRow(1),
        const SizedBox(height: 24),

        // ── Racun ──────────────────────────────────────────────────
        _sectionLabel('Račun', 2),
        const SizedBox(height: 10),
        _buildTapRow(
          ctrl: _rowCtrls[3],
          icon: Icons.logout_rounded,
          label: 'Odjava',
          subtitle: 'Vidimo se uskoro 👋',
          danger: true,
          onTap: () {}, // no-op for now
        ),
        const SizedBox(height: 24),

        // ─O nama ─────────────────────────────────────────────────
        _sectionLabel('O nama', 4),
        const SizedBox(height: 10),
        _buildTapRow(
          ctrl: _rowCtrls[5],
          icon: Icons.favorite_rounded,
          label: 'O MeetCute',
          subtitle: 'Naša priča ♡',
          onTap: _showAboutDialog,
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _sectionLabel(String text, int rowIdx) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _rowCtrls[rowIdx], curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(-0.04, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: _rowCtrls[rowIdx], curve: Curves.easeOutCubic)),
        child: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              color: _primary.withOpacity(0.45), fontSize: 11.5,
              fontWeight: FontWeight.w700, letterSpacing: 1.2,
            ),
            child: Text(text.toUpperCase()),
          ),
        ),
      ),
    );
  }

  // ── DARK MODe ───────────────────────────────────────────────────────────
  Widget _buildDarkModeRow(int rowIdx) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _rowCtrls[rowIdx], curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(CurvedAnimation(parent: _rowCtrls[rowIdx], curve: Curves.easeOutCubic)),
        child: GestureDetector(
          onTap: _toggleDark,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 340),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _primary.withOpacity(0.08), width: 1),
              boxShadow: [BoxShadow(
                color: _primary.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 5),
              )],
            ),
            child: Row(children: [
              // icon bubble
              AnimatedContainer(
                duration: const Duration(milliseconds: 340),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  _dark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                  color: _primary, size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(color: _primary, fontSize: 15.5, fontWeight: FontWeight.w700),
                  child: const Text('Tamni mod'),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(color: _primary.withOpacity(0.42), fontSize: 12.5, fontWeight: FontWeight.w400),
                  child: Text(_dark ? 'Upaljeno' : 'Ugašeno'),
                ),
              ])),
              // custom toggle
              _DarkToggle(
                value: _dark,
                primary: _primary,
                accent: _accent,
                onTap: _toggleDark,
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── TAP ROW ────────────────────────────────────────────────────────────────
  Widget _buildTapRow({
    required AnimationController ctrl,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? const Color(0xFFD93025) : _primary;
    return FadeTransition(
      opacity: CurvedAnimation(parent: ctrl, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic)),
        child: _TapCard(
          card: _card,
          primary: _primary,
          accent: danger ? color.withOpacity(0.10) : _accent,
          icon: icon,
          iconColor: color,
          label: label,
          subtitle: subtitle,
          onTap: onTap,
        ),
      ),
    );
  }

  // ── O NAMA ───────────────────────────────────────────────────────────
  void _showAboutDialog() {
    HapticFeedback.mediumImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: Colors.black.withOpacity(0.50),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: Center(
              child: _AboutCard(
                primary: _primary,
                accent: _accent,
                card: _card,
                onClose: () => Navigator.of(ctx).pop(),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── NAVIGACIJA ────────────────────────────────────────────────────────────────
  Widget _buildNavBar(MediaQueryData mq) {
    return AnimatedBuilder(
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
          children: List.generate(5, (i) => _buildNavItem(i)),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
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
          final scale = isSelected
              ? 1.0 + 0.16 * Curves.elasticOut.transform(t.clamp(0.0, 1.0))
              : 1.0;
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
                      color: isSelected ? _primary : _primary.withOpacity(0.30),
                      size: kNavIconSize),
                ),
                if (showChatBadge) Positioned(top: 2, right: 4,
                    child: NavBadge(count: chatUnread)),
                if (showNotifBadge) Positioned(top: 2, right: 4,
                    child: NavBadge(count: notifUnread)),
              ]),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? kNavDotSize : 0,
              height: isSelected ? kNavDotSize : 0,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(color: _primary, shape: BoxShape.circle),
            ),
          ]);
        },
      ),
    );
  }
}


// DARK MODE TOGGLE

class _DarkToggle extends StatelessWidget {
  final bool value;
  final Color primary;
  final Color accent;
  final VoidCallback onTap;
  const _DarkToggle({required this.value, required this.primary,
    required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        width: 52, height: 29,
        decoration: BoxDecoration(
          color: value ? primary : primary.withOpacity(0.18),
          borderRadius: BorderRadius.circular(15),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 23, height: 23,
              decoration: BoxDecoration(
                color: value ? accent : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.18), blurRadius: 6, offset: const Offset(0, 2),
                )],
              ),
              child: Icon(
                value ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                size: 13,
                color: value ? primary : const Color(0xFFFFB300),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// TAP CARD  — reusable pressable row card

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
  @override void initState() {
    super.initState();
    _press = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
  }
  @override void dispose() { _press.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) { _press.reverse(); widget.onTap(); },
      onTapCancel: () => _press.reverse(),
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) => Transform.scale(
            scale: 1.0 - _press.value * 0.025, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 340),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: widget.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.primary.withOpacity(0.08)),
            boxShadow: [BoxShadow(
              color: widget.primary.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 5),
            )],
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 340),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: widget.accent, borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(color: widget.iconColor, fontSize: 15.5, fontWeight: FontWeight.w700),
                child: Text(widget.label),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(color: widget.primary.withOpacity(0.42), fontSize: 12.5),
                child: Text(widget.subtitle),
              ),
            ])),
            Icon(Icons.chevron_right_rounded, color: widget.primary.withOpacity(0.28), size: 22),
          ]),
        ),
      ),
    );
  }
}

// Srce

class _HeartDeco extends StatefulWidget {
  final Color primary, accent;
  const _HeartDeco({required this.primary, required this.accent});
  @override State<_HeartDeco> createState() => _HeartDecoState();
}

class _HeartDecoState extends State<_HeartDeco> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  @override void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
  }
  @override void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Transform.scale(
        scale: 1.0 + _pulse.value * 0.08,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 340),
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: widget.accent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [BoxShadow(
              color: widget.primary.withOpacity(0.15 + _pulse.value * 0.10),
              blurRadius: 14 + _pulse.value * 6,
              offset: const Offset(0, 4),
            )],
          ),
          child: Icon(Icons.settings_rounded, color: widget.primary, size: 22),
        ),
      ),
    );
  }
}


// O NAMA pop up

class _AboutCard extends StatefulWidget {
  final Color primary, accent, card;
  final VoidCallback onClose;
  const _AboutCard({required this.primary, required this.accent,
    required this.card, required this.onClose});
  @override State<_AboutCard> createState() => _AboutCardState();
}

class _AboutCardState extends State<_AboutCard> with TickerProviderStateMixin {
  late AnimationController _sparkleCtrl;
  late AnimationController _floatCtrl;
  final List<_Sparkle> _sparkles = [];

  @override
  void initState() {
    super.initState();
    _sparkleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);

    final rng = math.Random(42);
    for (int i = 0; i < 8; i++) {
      _sparkles.add(_Sparkle(
        x: rng.nextDouble(),
        y: rng.nextDouble() * 0.5,
        size: 4.0 + rng.nextDouble() * 5,
        phase: rng.nextDouble(),
      ));
    }
  }

  @override
  void dispose() { _sparkleCtrl.dispose(); _floatCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 380),
          decoration: BoxDecoration(
            color: widget.card,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: widget.primary.withOpacity(0.22), blurRadius: 40, offset: const Offset(0, 16)),
              BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 20, offset: const Offset(0, 6)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // ── sparkle banner ─────────────────────────────────────────────
              AnimatedBuilder(
                animation: _sparkleCtrl,
                builder: (_, __) {
                  return SizedBox(
                    height: 110,
                    child: Stack(children: [
                      // gradient bg
                      Positioned.fill(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 380),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                              colors: [widget.primary, widget.primary.withOpacity(0.75)],
                            ),
                          ),
                        ),
                      ),
                      // sparkles
                      ..._sparkles.map((s) {
                        final t = ((_sparkleCtrl.value + s.phase) % 1.0);
                        final opacity = math.sin(t * math.pi).clamp(0.0, 1.0);
                        return Positioned(
                          left: s.x * 300,
                          top: s.y * 110,
                          child: Opacity(
                            opacity: opacity * 0.7,
                            child: Icon(
                              Icons.star_rounded,
                              color: widget.accent,
                              size: s.size,
                            ),
                          ),
                        );
                      }),
                      // floating hearts
                      AnimatedBuilder(
                        animation: _floatCtrl,
                        builder: (_, __) => Positioned(
                          left: 24,
                          top: 18 + _floatCtrl.value * 8,
                          child: Icon(Icons.favorite_rounded,
                              color: widget.accent.withOpacity(0.30), size: 22),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _floatCtrl,
                        builder: (_, __) => Positioned(
                          right: 28,
                          top: 28 - _floatCtrl.value * 6,
                          child: Icon(Icons.favorite_rounded,
                              color: widget.accent.withOpacity(0.22), size: 16),
                        ),
                      ),
                      // main icon
                      Center(
                        child: AnimatedBuilder(
                          animation: _floatCtrl,
                          builder: (_, __) => Transform.translate(
                            offset: Offset(0, -4 + _floatCtrl.value * 8),
                            child: Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                color: widget.accent.withOpacity(0.18),
                                shape: BoxShape.circle,
                                border: Border.all(color: widget.accent.withOpacity(0.35), width: 2),
                              ),
                              child: Icon(Icons.favorite_rounded,
                                  color: widget.accent, size: 32),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  );
                },
              ),

              //text
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                child: Column(children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: widget.primary, fontSize: 20,
                      fontWeight: FontWeight.w900, letterSpacing: -0.5,
                    ),
                    child: const Text('O MeetCute ♡', textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 14),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: widget.primary.withOpacity(0.72),
                      fontSize: 14.5, height: 1.65, fontWeight: FontWeight.w400,
                    ),
                    child: const Text(
                      'MeetCute nastao je kao projekt dvije studentice, Lane i Iris, '
                          'druge godine računarstva — dok su sjedile u svom omiljenom kafiću, '
                          'pile ledenu kavu i sanjale o aplikaciji koja spaja ljude na poseban način '
                          '\n\n'
                          'Nisu htjele još jedan swipe-left-swipe-right. Htjele su nešto toplije '
                          '— mjesto gdje upoznaješ ljude iz svog grada, na stvarnim događanjima, '
                          'u pravom životu. I tako je MeetCute dobio srce. 🍵✨',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // made with love tag — wrapped so it doesn't overflow on narrow screens
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 340),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: widget.accent.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: widget.primary.withOpacity(0.10)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.coffee_rounded, color: widget.primary, size: 14),
                      const SizedBox(width: 6),
                      Flexible(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            color: widget.primary.withOpacity(0.65),
                            fontSize: 12.5, fontWeight: FontWeight.w600,
                          ),
                          child: const Text(
                            'Napravljeno s ljubavlju i ledenom kavom',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.favorite_rounded, color: widget.primary, size: 12),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  // close button
                  GestureDetector(
                    onTap: widget.onClose,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 340),
                      height: 48,
                      decoration: BoxDecoration(
                        color: widget.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(
                          color: widget.primary.withOpacity(0.30),
                          blurRadius: 16, offset: const Offset(0, 6),
                        )],
                      ),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            color: widget.accent, fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                          child: const Text('Preslatko! ♡'),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
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