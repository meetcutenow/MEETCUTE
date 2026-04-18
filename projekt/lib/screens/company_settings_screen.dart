// ============================================================
// FILE 1: company_settings_screen.dart
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'company_auth_state.dart';
import 'onboarding_screen.dart';

const Color _bordo      = Color(0xFF700D25);
const Color _bordoLight = Color(0xFFF2E8E9);
const String _base = 'http://localhost:8080/api';

class CompanySettingsScreen extends StatelessWidget {
  const CompanySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mq    = MediaQuery.of(context);
    final state = CompanyAuthState.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF5EDEF),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: EdgeInsets.only(top: mq.padding.top + 12, left: 8, right: 18, bottom: 16),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _bordo, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            const Expanded(child: Text('Postavke', style: TextStyle(color: _bordo, fontSize: 22,
                fontWeight: FontWeight.w900, letterSpacing: -0.5))),
          ]),
        ),

        Expanded(child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 22, 18, mq.padding.bottom + 20),
          child: Column(children: [
            // Info kartica
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _bordo.withOpacity(0.08)),
                  boxShadow: [BoxShadow(color: _bordo.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 5))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [Color(0xFF700D25), Color(0xFF9E1535)]),
                        borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.business_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(state.orgName ?? '', style: const TextStyle(color: _bordo, fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('@${state.username ?? ''}', style: TextStyle(color: _bordo.withOpacity(0.50), fontSize: 13)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: _bordoLight, borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _bordo.withOpacity(0.15))),
                    child: const Text('Tvrtka', style: TextStyle(color: _bordo, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 14),
                Divider(height: 1, color: _bordo.withOpacity(0.10)),
                const SizedBox(height: 14),
                Row(children: [
                  Icon(Icons.email_outlined, color: _bordo.withOpacity(0.50), size: 15),
                  const SizedBox(width: 8),
                  Text(state.email ?? '', style: TextStyle(color: _bordo.withOpacity(0.65), fontSize: 13.5)),
                ]),
              ]),
            ),
            const SizedBox(height: 24),

            // Odjava
            GestureDetector(
              onTap: () => _showLogoutDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _bordo.withOpacity(0.08)),
                    boxShadow: [BoxShadow(color: _bordo.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 5))]),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                        color: const Color(0xFFD93025).withOpacity(0.10), borderRadius: BorderRadius.circular(13)),
                    child: const Icon(Icons.logout_rounded, color: Color(0xFFD93025), size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Odjava', style: TextStyle(color: Color(0xFFD93025), fontSize: 15.5, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('Odjavi se iz računa tvrtke', style: TextStyle(color: Color(0xFFD93025), fontSize: 12.5)),
                  ])),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFFD93025), size: 22),
                ]),
              ),
            ),

            const SizedBox(height: 24),
            Text('© MeetCute za Tvrtke', style: TextStyle(color: _bordo.withOpacity(0.30), fontSize: 12)),
          ]),
        )),
      ]),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26),
              boxShadow: [BoxShadow(color: _bordo.withOpacity(0.18), blurRadius: 36, offset: const Offset(0, 14))]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 54, height: 54,
                decoration: BoxDecoration(color: const Color(0xFFD93025).withOpacity(0.10), shape: BoxShape.circle),
                child: const Icon(Icons.logout_rounded, color: Color(0xFFD93025), size: 28)),
            const SizedBox(height: 14),
            const Text('Odjava', style: TextStyle(color: _bordo, fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 8),
            Text('Sigurno se želite odjaviti iz računa tvrtke?', textAlign: TextAlign.center,
                style: TextStyle(color: _bordo.withOpacity(0.55), fontSize: 13.5)),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: _bordo.withOpacity(0.20))),
                ),
                child: Text('Odustani', style: TextStyle(color: _bordo.withOpacity(0.65), fontSize: 14)),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD93025), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 13), elevation: 0,
                ),
                onPressed: () async {
                  try {
                    await http.post(Uri.parse('$_base/company/auth/logout'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({'refreshToken': CompanyAuthState.instance.refreshToken}),
                    );
                  } catch (_) {}
                  await CompanyAuthState.instance.clear();
                  if (!context.mounted) return;
                  // Navigate to onboarding
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  // Then pop the company home
                  Navigator.of(context).pop();
                },
                child: const Text('Odjavi se', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}

