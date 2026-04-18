import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'company_auth_state.dart';
import 'company_events_screen.dart';
import 'company_organize_screen.dart';
import 'company_settings_screen.dart';

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
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _cardCtrls = List.generate(2,
            (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 120)));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    for (final c in _cardCtrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq    = MediaQuery.of(context);
    final name  = CompanyAuthState.instance.orgName ?? 'Tvrtka';

    return Scaffold(
      backgroundColor: const Color(0xFFF5EDEF),
      body: FadeTransition(
        opacity: _entryFade,
        child: SlideTransition(
          position: _entrySlide,
          child: Column(children: [
            // Header
            Container(
              color: Colors.white,
              padding: EdgeInsets.only(top: mq.padding.top + 18, left: 22, right: 22, bottom: 22),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Dobrodošli,', style: TextStyle(color: _bordo.withOpacity(0.50), fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(name, style: const TextStyle(color: _bordo, fontSize: 24,
                      fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ])),
                GestureDetector(
                  onTap: () => Navigator.push(context, PageRouteBuilder(
                    pageBuilder: (_, a, __) => const CompanySettingsScreen(),
                    transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
                    transitionDuration: const Duration(milliseconds: 300),
                  )),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _bordoLight, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _bordo.withOpacity(0.12)),
                    ),
                    child: const Icon(Icons.settings_rounded, color: _bordo, size: 22),
                  ),
                ),
              ]),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  const SizedBox(height: 12),
                  // Badge "Tvrtka"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _bordo.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _bordo.withOpacity(0.15)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.business_rounded, color: _bordo, size: 14),
                      const SizedBox(width: 7),
                      Text('Organizatorski račun', style: TextStyle(
                          color: _bordo, fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  const SizedBox(height: 32),

                  // Moji događaji
                  Expanded(
                    child: _BigMenuCard(
                      index: 0,
                      ctrl: _cardCtrls[0],
                      icon: Icons.event_rounded,
                      title: 'Moji događaji',
                      subtitle: 'Pregled događanja, statistike i sudionici',
                      gradient: const [Color(0xFF700D25), Color(0xFF9E1535)],
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

                  // Organiziraj događaj
                  Expanded(
                    child: _BigMenuCard(
                      index: 1,
                      ctrl: _cardCtrls[1],
                      icon: Icons.add_circle_outline_rounded,
                      title: 'Organiziraj događaj',
                      subtitle: 'Kreiraj novi event s ulazninama i detaljima',
                      gradient: const [Color(0xFF4A0818), Color(0xFF700D25)],
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
                  const SizedBox(height: 12),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _BigMenuCard extends StatelessWidget {
  final int index;
  final AnimationController ctrl;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _BigMenuCard({
    required this.index, required this.ctrl, required this.icon,
    required this.title, required this.subtitle, required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => ctrl.forward(),
      onTapUp: (_) { ctrl.reverse(); onTap(); },
      onTapCancel: () => ctrl.reverse(),
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (_, child) => Transform.scale(scale: 1.0 - ctrl.value * 0.02, child: child),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(
                color: gradient.last.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(
                color: Colors.white.withOpacity(0.65), fontSize: 13.5, height: 1.4)),
            const SizedBox(height: 14),
            Row(children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Otvori', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 15),
                ]),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}