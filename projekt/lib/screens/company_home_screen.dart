import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'company_auth_state.dart';
import 'company_events_screen.dart';
import 'company_organize_screen.dart';
import 'company_settings_screen.dart';
import 'theme_state.dart';

const Color _bordo      = Color(0xFF700D25);
const Color _bordoLight = Color(0xFFF2E8E9);
const String _base = 'http://localhost:8080/api';

class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({super.key});
  @override State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> with TickerProviderStateMixin {

  late final AnimationController _entryCtrl;
  late final Animation<double>   _entryFade;
  late final Animation<Offset>   _entrySlide;
  late final List<AnimationController> _cardCtrls;

  @override
  void initState() {
    super.initState();
    ThemeState.instance.addListener(_onTheme);
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _cardCtrls = List.generate(2,
            (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 120)));
    _entryCtrl.forward();
  }

  void _onTheme() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeState.instance.removeListener(_onTheme);
    _entryCtrl.dispose();
    for (final c in _cardCtrls) c.dispose();
    super.dispose();
  }

  bool get _isDark => ThemeState.instance.isDark;
  Color get _bg     => _isDark ? kDarkBg    : const Color(0xFFF5EDEF);
  Color get _card   => _isDark ? kDarkCard  : Colors.white;
  Color get _primary => _isDark ? kDarkPrimary : _bordo;

  @override
  Widget build(BuildContext context) {
    final mq    = MediaQuery.of(context);
    final name  = CompanyAuthState.instance.orgName ?? 'Organizacija';

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
              // ── Header ──────────────────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 380),
                color: _card,
                padding: EdgeInsets.only(top: mq.padding.top + 10, left: 22, right: 22, bottom: 14),
                child: Row(children: [
                  // Logo
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Text('MC',
                          style: TextStyle(color: _isDark ? kDarkBg : Colors.white,
                              fontSize: 13, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Dobrodošli,', style: TextStyle(
                        color: _primary.withOpacity(0.50), fontSize: 11.5, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 1),
                    Text(name, style: TextStyle(color: _primary, fontSize: 17,
                        fontWeight: FontWeight.w900, letterSpacing: -0.4),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ])),
                  // Settings gumb
                  GestureDetector(
                    onTap: () => Navigator.push(context, PageRouteBuilder(
                      pageBuilder: (_, a, __) => const CompanySettingsScreen(),
                      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
                      transitionDuration: const Duration(milliseconds: 300),
                    )),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 380),
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _primary.withOpacity(0.18)),
                      ),
                      child: Icon(Icons.settings_rounded, color: _primary, size: 20),
                    ),
                  ),
                ]),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(children: [
                    // Badge "Organizacija"
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 380),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _primary.withOpacity(0.20)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.business_rounded, color: _primary, size: 14),
                        const SizedBox(width: 7),
                        Text('Organizatorski račun', style: TextStyle(
                            color: _primary, fontSize: 12.5, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    const SizedBox(height: 28),

                    // ── Moji događaji ────────────────────────────────────
                    Expanded(
                      child: _MenuCard(
                        index: 0,
                        ctrl: _cardCtrls[0],
                        icon: Icons.event_rounded,
                        title: 'Moji događaji',
                        subtitle: 'Pregled događanja, statistike i sudionici',
                        isDark: _isDark,
                        primary: _primary,
                        onTap: () => Navigator.push(context, PageRouteBuilder(
                          pageBuilder: (_, a, __) => const CompanyEventsScreen(),
                          transitionsBuilder: (_, a, __, child) => FadeTransition(
                            opacity: a,
                            child: SlideTransition(
                              position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
                                  .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
                              child: child,
                            ),
                          ),
                          transitionDuration: const Duration(milliseconds: 320),
                        )),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Organiziraj događaj ──────────────────────────────
                    Expanded(
                      child: _MenuCard(
                        index: 1,
                        ctrl: _cardCtrls[1],
                        icon: Icons.add_circle_outline_rounded,
                        title: 'Organiziraj događaj',
                        subtitle: 'Kreiraj novi događaj s ulazninama i detaljima',
                        isDark: _isDark,
                        primary: _primary,
                        onTap: () => Navigator.push(context, PageRouteBuilder(
                          pageBuilder: (_, a, __) => const CompanyOrganizeScreen(),
                          transitionsBuilder: (_, a, __, child) => SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero)
                                .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
                            child: child,
                          ),
                          transitionDuration: const Duration(milliseconds: 400),
                        )).then((_) => setState(() {})),
                      ),
                    ),
                    SizedBox(height: mq.padding.bottom + 20),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Elegantna kartica menija s bordo rubom ──────────────────────────────────

class _MenuCard extends StatelessWidget {
  final int index;
  final AnimationController ctrl;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  const _MenuCard({
    required this.index, required this.ctrl, required this.icon,
    required this.title, required this.subtitle,
    required this.isDark, required this.primary, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? kDarkCard : Colors.white;

    return GestureDetector(
      onTapDown: (_) => ctrl.forward(),
      onTapUp: (_) { ctrl.reverse(); onTap(); },
      onTapCancel: () => ctrl.reverse(),
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (_, child) => Transform.scale(scale: 1.0 - ctrl.value * 0.02, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 380),
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primary.withOpacity(0.35), width: 1.5),
            boxShadow: [
              BoxShadow(color: primary.withOpacity(isDark ? 0.20 : 0.12),
                  blurRadius: 20, offset: const Offset(0, 6)),
              BoxShadow(color: primary.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          padding: const EdgeInsets.all(26),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Ikona s bordo pozadinom
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: primary.withOpacity(0.25), width: 1.2),
              ),
              child: Icon(icon, color: primary, size: 26),
            ),
            const Spacer(),
            Text(title, style: TextStyle(
                color: primary, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(
                color: primary.withOpacity(0.55), fontSize: 13.5, height: 1.4)),
            const SizedBox(height: 16),
            // Gumb "Otvori"
            Row(children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primary.withOpacity(0.30), width: 1.2),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Otvori', style: TextStyle(
                      color: primary, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, color: primary, size: 15),
                ]),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}