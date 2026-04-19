import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'auth_state.dart';
import 'company_auth_state.dart';
import 'home_screen.dart' show HomeScreen;
import 'company_home_screen.dart';

const Color _bordo      = Color(0xFF700D25);
const Color _bordoLight = Color(0xFFF2E8E9);
const String _base = 'http://localhost:8080/api';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {

  // 0 = Osoba, 1 = Tvrtka
  int _tab = 0;

  // Controlleri — dijele se između tabova
  final _usernameCtrl = TextEditingController();
  final _passCtrl     = TextEditingController();

  bool    _loading      = false;
  bool    _showPassword = false;
  String? _error;

  late final AnimationController _entryCtrl;
  late final Animation<double>   _entryFade;
  late final AnimationController _tabAnim;
  late final Animation<double>   _tabFade;
  late final AnimationController _btnCtrl;
  late final Animation<double>   _btnScale;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _tabAnim   = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _tabFade    = CurvedAnimation(parent: _tabAnim, curve: Curves.easeOut);
    _btnCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
    _btnScale  = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn));
    _entryCtrl.forward();
    _tabAnim.forward();

    for (final c in [_usernameCtrl, _passCtrl]) {
      c.addListener(() { if (mounted) setState(() { _error = null; }); });
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose(); _tabAnim.dispose(); _btnCtrl.dispose();
    _usernameCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (_tab == index) return;
    HapticFeedback.selectionClick();
    _tabAnim.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _tab = index;
        _error = null;
        _usernameCtrl.clear();
        _passCtrl.clear();
      });
      _tabAnim.forward();
    });
  }

  bool get _isValid =>
      _usernameCtrl.text.trim().isNotEmpty &&
          _passCtrl.text.length >= 6;

  Future<void> _login() async {
    if (!_isValid || _loading) return;
    HapticFeedback.mediumImpact();
    await _btnCtrl.forward(); await _btnCtrl.reverse();
    setState(() { _loading = true; _error = null; });

    try {
      if (_tab == 0) {
        await _loginUser();
      } else {
        await _loginCompany();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Login kao korisnik ─────────────────────────────────────
  Future<void> _loginUser() async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameCtrl.text.trim().toLowerCase(),
          'password': _passCtrl.text,
        }),
      ).timeout(const Duration(seconds: 10));

      final decoded = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      if (!mounted) return;

      if (resp.statusCode == 200 && decoded['success'] == true) {
        final data = decoded['data'] as Map<String, dynamic>;
        await AuthState.instance.saveFromResponse(data);
        if (!mounted) return;
        _navigateTo(const HomeScreen());
      } else {
        setState(() => _error = decoded['message'] ?? 'Pogrešno korisničko ime ili lozinka.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Ne mogu se spojiti na server.');
    }
  }

  // ── Login kao tvrtka ───────────────────────────────────────
  Future<void> _loginCompany() async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/company/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameCtrl.text.trim().toLowerCase(),
          'password': _passCtrl.text,
        }),
      ).timeout(const Duration(seconds: 10));

      final decoded = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      if (!mounted) return;

      if (resp.statusCode == 200 && decoded['success'] == true) {
        await CompanyAuthState.instance.saveFromResponse(decoded['data']);
        if (!mounted) return;
        _navigateTo(const CompanyHomeScreen());
      } else {
        setState(() => _error = decoded['message'] ?? 'Pogrešno korisničko ime ili lozinka.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Ne mogu se spojiti na server.');
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => screen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _entryFade,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, mq.padding.top + 16, 24, mq.padding.bottom + 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Back ─────────────────────────────────────────
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: _bordoLight, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: _bordo, size: 18),
                ),
              ),
              const SizedBox(height: 28),

              // ── Naslov ────────────────────────────────────────
              const Text('Dobrodošli nazad!',
                  style: TextStyle(color: _bordo, fontSize: 28,
                      fontWeight: FontWeight.w900, letterSpacing: -0.8)),
              const SizedBox(height: 6),
              Text('Prijavite se u svoj račun',
                  style: TextStyle(color: _bordo.withOpacity(0.55), fontSize: 15)),
              const SizedBox(height: 32),

              // ── Tab odabir: Osoba / Tvrtka ────────────────────
              _TabSwitcher(selected: _tab, onChanged: _switchTab),
              const SizedBox(height: 28),

              // ── Forma ─────────────────────────────────────────
              FadeTransition(
                opacity: _tabFade,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Username
                  _label(_tab == 0 ? 'Korisničko ime' : 'Korisničko ime tvrtke'),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: _usernameCtrl,
                    hint: _tab == 0 ? 'npr. ivan123' : 'npr. eventco',
                    icon: _tab == 0 ? Icons.person_rounded : Icons.business_rounded,
                    keyboard: TextInputType.text,
                  ),
                  const SizedBox(height: 16),

                  // Lozinka
                  _label('Lozinka'),
                  const SizedBox(height: 8),
                  _passwordField(),
                  const SizedBox(height: 12),

                  // Greška
                  if (_error != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!,
                            style: const TextStyle(color: Colors.redAccent,
                                fontSize: 13, fontWeight: FontWeight.w500))),
                      ]),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 8),

                  // ── Login gumb ────────────────────────────────
                  ScaleTransition(
                    scale: _btnScale,
                    child: GestureDetector(
                      onTapDown: (_) { if (_isValid && !_loading) _btnCtrl.forward(); },
                      onTapUp: (_) { _btnCtrl.reverse(); _login(); },
                      onTapCancel: () => _btnCtrl.reverse(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        height: 54, width: double.infinity,
                        decoration: BoxDecoration(
                          color: (_isValid && !_loading) ? _bordo : _bordo.withOpacity(0.28),
                          borderRadius: BorderRadius.circular(27),
                          boxShadow: (_isValid && !_loading) ? [BoxShadow(
                              color: _bordo.withOpacity(0.32), blurRadius: 18,
                              offset: const Offset(0, 7))] : [],
                        ),
                        child: Center(child: _loading
                            ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(
                            _tab == 0 ? Icons.login_rounded : Icons.business_center_rounded,
                            color: _isValid ? Colors.white : Colors.white.withOpacity(0.45),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _tab == 0 ? 'Prijavi se' : 'Prijavi se kao tvrtka',
                            style: TextStyle(
                              color: _isValid ? Colors.white : Colors.white.withOpacity(0.45),
                              fontSize: 15.5, fontWeight: FontWeight.w800,
                            ),
                          ),
                        ])),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Divider ───────────────────────────────────
                  Row(children: [
                    Expanded(child: Divider(color: _bordo.withOpacity(0.12))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ili', style: TextStyle(
                          color: _bordo.withOpacity(0.35), fontSize: 13)),
                    ),
                    Expanded(child: Divider(color: _bordo.withOpacity(0.12))),
                  ]),
                  const SizedBox(height: 24),

                  // ── Link na registraciju ──────────────────────
                  Center(child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: RichText(text: TextSpan(
                      text: _tab == 0 ? 'Nemaš račun? ' : 'Nemaš račun tvrtke? ',
                      style: TextStyle(color: _bordo.withOpacity(0.50), fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Registriraj se',
                          style: const TextStyle(
                              color: _bordo, fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline),
                        ),
                      ],
                    )),
                  )),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────

  Widget _label(String text) => Text(text,
      style: const TextStyle(color: _bordo, fontSize: 13.5, fontWeight: FontWeight.w700));

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboard,
  }) =>
      Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _bordo.withOpacity(0.15), width: 1.2),
          boxShadow: [BoxShadow(color: _bordo.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          const SizedBox(width: 14),
          Icon(icon, color: _bordo.withOpacity(0.40), size: 20),
          const SizedBox(width: 10),
          Expanded(child: TextField(
            controller: controller, keyboardType: keyboard,
            style: const TextStyle(color: _bordo, fontSize: 15, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: _bordo.withOpacity(0.28), fontSize: 15),
              border: InputBorder.none, isDense: true,
            ),
          )),
          const SizedBox(width: 12),
        ]),
      );

  Widget _passwordField() => Container(
    height: 54,
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _bordo.withOpacity(0.15), width: 1.2),
      boxShadow: [BoxShadow(color: _bordo.withOpacity(0.05),
          blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Row(children: [
      const SizedBox(width: 14),
      Icon(Icons.lock_rounded, color: _bordo.withOpacity(0.40), size: 20),
      const SizedBox(width: 10),
      Expanded(child: TextField(
        controller: _passCtrl,
        obscureText: !_showPassword,
        style: const TextStyle(color: _bordo, fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Lozinka',
          hintStyle: TextStyle(color: _bordo.withOpacity(0.28), fontSize: 15),
          border: InputBorder.none, isDense: true,
        ),
      )),
      GestureDetector(
        onTap: () => setState(() => _showPassword = !_showPassword),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            _showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: _bordo.withOpacity(0.35), size: 20,
          ),
        ),
      ),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB SWITCHER — Osoba / Tvrtka
// ═══════════════════════════════════════════════════════════════════════════════

class _TabSwitcher extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _TabSwitcher({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _bordoLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        _tab(0, Icons.person_rounded, 'Osoba'),
        _tab(1, Icons.business_rounded, 'Tvrtka'),
      ]),
    );
  }

  Widget _tab(int index, IconData icon, String label) {
    final active = selected == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: active ? _bordo : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: active ? [BoxShadow(
                color: _bordo.withOpacity(0.28), blurRadius: 10,
                offset: const Offset(0, 3))] : [],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 17,
                color: active ? Colors.white : _bordo.withOpacity(0.50)),
            const SizedBox(width: 7),
            Text(label, style: TextStyle(
              color: active ? Colors.white : _bordo.withOpacity(0.55),
              fontSize: 14, fontWeight: FontWeight.w700,
            )),
          ]),
        ),
      ),
    );
  }
}