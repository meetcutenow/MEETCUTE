import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'company_auth_state.dart';
import 'onboarding_screen.dart';

const Color _bordo      = Color(0xFF700D25);
const Color _bordoLight = Color(0xFFF2E8E9);
const String _base = 'http://localhost:8080/api';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});
  @override State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {

  bool _loggingOut = false;

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      // Pozovi backend logout da invalidira refresh token
      await http.post(
        Uri.parse('$_base/company/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${CompanyAuthState.instance.accessToken}',
        },
        body: jsonEncode({'refreshToken': CompanyAuthState.instance.refreshToken}),
      ).timeout(const Duration(seconds: 6));
    } catch (_) {
      // Svejedno odjavi lokalno
    } finally {
      // Očisti lokalni session
      await CompanyAuthState.instance.clear();

      if (!mounted) return;

      // Idi na Onboarding i ukloni sav stack
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => const OnboardingScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
            (route) => false,
      );
    }
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: _bordo.withOpacity(0.18), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: _bordoLight, shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded, color: _bordo, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Odjava', style: TextStyle(color: _bordo,
                fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text('Jeste li sigurni da se želite odjaviti?',
                textAlign: TextAlign.center,
                style: TextStyle(color: _bordo.withOpacity(0.60), fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(ctx, false),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: _bordoLight, borderRadius: BorderRadius.circular(23),
                    border: Border.all(color: _bordo.withOpacity(0.20)),
                  ),
                  child: const Center(child: Text('Odustani', style: TextStyle(
                      color: _bordo, fontSize: 14.5, fontWeight: FontWeight.w700))),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(ctx, true),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: _bordo, borderRadius: BorderRadius.circular(23),
                    boxShadow: [BoxShadow(color: _bordo.withOpacity(0.30),
                        blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Center(child: Text('Odjavi se', style: TextStyle(
                      color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700))),
                ),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F0F1),
      body: Column(children: [
        // ── Header ──────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: EdgeInsets.only(top: mq.padding.top + 10, left: 6, right: 16, bottom: 18),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _bordo, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Postavke', style: TextStyle(color: _bordo, fontSize: 22,
                  fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              Text('Upravljanje računom', style: TextStyle(
                  color: _bordo, fontSize: 13, fontWeight: FontWeight.w400)),
            ])),
          ]),
        ),

        // ── Sadržaj ─────────────────────────────────────────
        Expanded(child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 20, 16, mq.padding.bottom + 24),
          child: Column(children: [

            // ── Profil kartica ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: _bordo.withOpacity(0.07),
                    blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Row(children: [
                Container(
                  width: 58, height: 58,
                  decoration: BoxDecoration(color: _bordoLight, shape: BoxShape.circle),
                  child: const Icon(Icons.business_rounded, color: _bordo, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(company.orgName ?? 'Tvrtka', style: const TextStyle(
                      color: _bordo, fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text('@${company.username ?? ''}', style: TextStyle(
                      color: _bordo.withOpacity(0.55), fontSize: 13.5)),
                  if (company.email != null) ...[
                    const SizedBox(height: 2),
                    Text(company.email!, style: TextStyle(
                        color: _bordo.withOpacity(0.45), fontSize: 12.5)),
                  ],
                ])),
              ]),
            ),
            const SizedBox(height: 12),

            // ── Opcije ─────────────────────────────────────
            _settingsTile(
              icon: Icons.business_center_rounded,
              label: 'Podaci tvrtke',
              subtitle: 'Naziv, kontakt, opis',
              onTap: () => _showSnack('Uskoro dostupno'),
            ),
            const SizedBox(height: 8),
            _settingsTile(
              icon: Icons.lock_rounded,
              label: 'Promjena lozinke',
              subtitle: 'Ažuriraj lozinku računa',
              onTap: () => _showSnack('Uskoro dostupno'),
            ),
            const SizedBox(height: 24),

            // ── Odjava ─────────────────────────────────────
            GestureDetector(
              onTap: _loggingOut ? null : _showLogoutDialog,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _bordo.withOpacity(0.25)),
                  boxShadow: [BoxShadow(color: _bordo.withOpacity(0.06),
                      blurRadius: 12, offset: const Offset(0, 3))],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (_loggingOut)
                    const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: _bordo, strokeWidth: 2))
                  else ...[
                    const Icon(Icons.logout_rounded, color: _bordo, size: 20),
                    const SizedBox(width: 10),
                    const Text('Odjavi se', style: TextStyle(color: _bordo,
                        fontSize: 15.5, fontWeight: FontWeight.w800)),
                  ],
                ]),
              ),
            ),
          ]),
        )),
      ]),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _bordo.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: _bordoLight, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: _bordo, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: _bordo, fontSize: 14.5, fontWeight: FontWeight.w700)),
          Text(subtitle, style: TextStyle(color: _bordo.withOpacity(0.50), fontSize: 12.5)),
        ])),
        Icon(Icons.arrow_forward_ios_rounded, color: _bordo.withOpacity(0.30), size: 15),
      ]),
    ),
  );

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    backgroundColor: _bordo, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    margin: const EdgeInsets.all(16),
  ));
}