import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'company_auth_state.dart';
import 'onboarding_screen.dart';
import 'theme_state.dart';
import 'package:http/http.dart' as http;

const String _base = 'http://localhost:8080/api';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});
  @override State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen>
    with TickerProviderStateMixin {

  bool _loggingOut = false;
  late final AnimationController _toggleCtrl;

  @override
  void initState() {
    super.initState();
    ThemeState.instance.addListener(_onTheme);
    _toggleCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320),
      value: ThemeState.instance.isDark ? 1.0 : 0.0,
    );
  }

  void _onTheme() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeState.instance.removeListener(_onTheme);
    _toggleCtrl.dispose();
    super.dispose();
  }

  bool  get _isDark   => ThemeState.instance.isDark;
  Color get _bg       => _isDark ? kDarkBg      : const Color(0xFFF8F0F1);
  Color get _card     => _isDark ? kDarkCard    : Colors.white;
  Color get _primary  => _isDark ? kDarkPrimary : const Color(0xFF700D25);
  Color get _accent   => _isDark ? kDarkCardEl  : const Color(0xFFF2E8E9);
  Color get _onPrimary => _isDark ? kDarkBg : Colors.white;

  void _toggleDark() {
    HapticFeedback.selectionClick();
    ThemeState.instance.toggle();
    ThemeState.instance.isDark ? _toggleCtrl.forward() : _toggleCtrl.reverse();
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await http.post(
        Uri.parse('$_base/company/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${CompanyAuthState.instance.accessToken}',
        },
        body: jsonEncode({'refreshToken': CompanyAuthState.instance.refreshToken}),
      ).timeout(const Duration(seconds: 6));
    } catch (_) {}
    await CompanyAuthState.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const OnboardingScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
          (route) => false,
    );
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _card, borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _primary.withOpacity(0.20)),
            boxShadow: [BoxShadow(color: _primary.withOpacity(0.18), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 60, height: 60,
                decoration: BoxDecoration(color: _primary.withOpacity(0.10), shape: BoxShape.circle,
                    border: Border.all(color: _primary.withOpacity(0.25))),
                child: Icon(Icons.logout_rounded, color: _primary, size: 28)),
            const SizedBox(height: 16),
            Text('Odjava', style: TextStyle(color: _primary, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text('Jeste li sigurni da se želite odjaviti?',
                textAlign: TextAlign.center,
                style: TextStyle(color: _primary.withOpacity(0.60), fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(ctx, false),
                child: Container(height: 46,
                    decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(23),
                        border: Border.all(color: _primary.withOpacity(0.25))),
                    child: Center(child: Text('Odustani', style: TextStyle(
                        color: _primary, fontSize: 14.5, fontWeight: FontWeight.w700)))),
              )),
              const SizedBox(width: 10),
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(ctx, true),
                child: Container(height: 46,
                    decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(23),
                        boxShadow: [BoxShadow(color: _primary.withOpacity(0.30), blurRadius: 12, offset: const Offset(0, 4))]),
                    child: Center(child: Text('Odjavi se', style: TextStyle(
                        color: _onPrimary, fontSize: 14.5, fontWeight: FontWeight.w700)))),
              )),
            ]),
          ]),
        ),
      ),
    );
    if (confirmed == true) await _logout();
  }

  @override
  Widget build(BuildContext context) {
    final mq      = MediaQuery.of(context);
    final company = CompanyAuthState.instance;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      color: _bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 380),
            color: _card,
            padding: EdgeInsets.only(top: mq.padding.top + 10, left: 6, right: 16, bottom: 16),
            child: Row(children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: _primary, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Postavke', style: TextStyle(color: _primary, fontSize: 22,
                    fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                Text('Upravljanje računom', style: TextStyle(
                    color: _primary.withOpacity(0.45), fontSize: 13)),
              ])),
            ]),
          ),

          Expanded(child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 20, 16, mq.padding.bottom + 24),
            child: Column(children: [

              // Profil kartica
              AnimatedContainer(
                duration: const Duration(milliseconds: 380),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _card, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _primary.withOpacity(0.15)),
                  boxShadow: [BoxShadow(color: _primary.withOpacity(_isDark ? 0.12 : 0.07),
                      blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Row(children: [
                  Container(width: 58, height: 58,
                      decoration: BoxDecoration(color: _primary.withOpacity(0.10), shape: BoxShape.circle,
                          border: Border.all(color: _primary.withOpacity(0.25), width: 1.5)),
                      child: Icon(Icons.business_rounded, color: _primary, size: 28)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(company.orgName ?? 'Organizacija', style: TextStyle(
                        color: _primary, fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text('@${company.username ?? ''}', style: TextStyle(
                        color: _primary.withOpacity(0.55), fontSize: 13.5)),
                    if (company.email != null) ...[
                      const SizedBox(height: 2),
                      Text(company.email!, style: TextStyle(
                          color: _primary.withOpacity(0.40), fontSize: 12.5)),
                    ],
                  ])),
                ]),
              ),
              const SizedBox(height: 20),

              _sectionLabel('Izgled'),
              const SizedBox(height: 10),
              _darkModeRow(),
              const SizedBox(height: 20),

              _sectionLabel('Račun'),
              const SizedBox(height: 10),
              _settingsTile(icon: Icons.business_center_rounded,
                  label: 'Podaci organizacije', subtitle: 'Naziv, kontakt, opis',
                  onTap: () => _showSnack('Uskoro dostupno')),
              const SizedBox(height: 8),
              _settingsTile(icon: Icons.lock_rounded,
                  label: 'Promjena lozinke', subtitle: 'Ažuriraj lozinku računa',
                  onTap: () => _showSnack('Uskoro dostupno')),
              const SizedBox(height: 24),

              GestureDetector(
                onTap: _loggingOut ? null : _showLogoutDialog,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 380),
                  height: 54,
                  decoration: BoxDecoration(
                    color: _card, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _primary.withOpacity(0.30), width: 1.2),
                    boxShadow: [BoxShadow(color: _primary.withOpacity(0.06),
                        blurRadius: 12, offset: const Offset(0, 3))],
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (_loggingOut)
                      SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: _primary, strokeWidth: 2))
                    else ...[
                      Icon(Icons.logout_rounded, color: _primary, size: 20),
                      const SizedBox(width: 10),
                      Text('Odjavi se', style: TextStyle(
                          color: _primary, fontSize: 15.5, fontWeight: FontWeight.w800)),
                    ],
                  ]),
                ),
              ),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(text.toUpperCase(), style: TextStyle(
        color: _primary.withOpacity(0.45), fontSize: 11.5,
        fontWeight: FontWeight.w700, letterSpacing: 1.2)),
  );

  Widget _darkModeRow() => GestureDetector(
    onTap: _toggleDark,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 340),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 340),
          width: 44, height: 44,
          decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _primary.withOpacity(0.15))),
          child: Icon(_isDark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
              color: _primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tamni mod', style: TextStyle(
              color: _primary, fontSize: 15.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(_isDark ? 'Upaljeno' : 'Ugašeno', style: TextStyle(
              color: _primary.withOpacity(0.45), fontSize: 12.5)),
        ])),
        _DarkToggle(value: _isDark, primary: _primary, accent: _accent, onTap: _toggleDark),
      ]),
    ),
  );

  Widget _settingsTile({required IconData icon, required String label,
    required String subtitle, required VoidCallback onTap}) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 340),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withOpacity(0.12)),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 340),
          width: 42, height: 42,
          decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primary.withOpacity(0.15))),
          child: Icon(icon, color: _primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: _primary, fontSize: 14.5, fontWeight: FontWeight.w700)),
          Text(subtitle, style: TextStyle(color: _primary.withOpacity(0.50), fontSize: 12.5)),
        ])),
        Icon(Icons.arrow_forward_ios_rounded, color: _primary.withOpacity(0.30), size: 15),
      ]),
    ),
  );

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: TextStyle(color: _onPrimary, fontWeight: FontWeight.w600)),
    backgroundColor: _primary, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    margin: const EdgeInsets.all(16),
  ));
}

class _DarkToggle extends StatelessWidget {
  final bool value;
  final Color primary, accent;
  final VoidCallback onTap;
  const _DarkToggle({required this.value, required this.primary,
    required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic,
        width: 52, height: 29,
        decoration: BoxDecoration(
          color: value ? primary : primary.withOpacity(0.18),
          borderRadius: BorderRadius.circular(15),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 320), curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 23, height: 23,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? accent : Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Icon(value ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                  size: 13, color: value ? primary : const Color(0xFFFFB300)),
            ),
          ),
        ),
      ),
    );
  }
}