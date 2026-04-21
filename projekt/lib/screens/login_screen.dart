import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/profile_storage.dart';
import 'auth_state.dart';
import 'company_auth_state.dart';
import 'home_screen.dart' show HomeScreen;
import 'company_home_screen.dart';
import 'onboarding_screen.dart';
import 'onboarding_screen.dart' show globalProfileData, RegistrationState;
import 'profile_setup_screen.dart' show ProfileSetupData;

const Color _bordo      = Color(0xFF700D25);
const Color _bordoLight = Color(0xFFF2E8E9);
const String _base = 'http://localhost:8080/api';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {

  int _tab = 0; // 0 = Osoba, 1 = Organizacija

  final _usernameCtrl = TextEditingController();
  final _passCtrl     = TextEditingController();

  bool    _loading      = false;
  bool    _showPassword = false;
  String? _error;

  late final AnimationController _entryCtrl;
  late final Animation<double>   _entryFade;

  late final AnimationController _bgCtrl;
  late final Animation<double>   _bgAnim;

  late final AnimationController _btnCtrl;
  late final Animation<double>   _btnScale;

  // Tab switching — smooth crossfade + slide
  late final AnimationController _tabCtrl;
  late final Animation<double>   _tabFade;
  late final Animation<Offset>   _tabSlide;
  int _animatingTab = 0; // koji je tab trenutno vidljiv u animaciji

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();

    _btnCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
    _btnScale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn));

    // Tab animation — starts at full (visible)
    _tabCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _tabFade = CurvedAnimation(parent: _tabCtrl, curve: Curves.easeInOut);
    _tabSlide = Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _tabCtrl, curve: Curves.easeOutCubic));
    _tabCtrl.value = 1.0;
    _animatingTab = 0;

    for (final c in [_usernameCtrl, _passCtrl]) {
      c.addListener(() { if (mounted) setState(() => _error = null); });
    }
  }

  @override
  void dispose() {
    _bgCtrl.dispose(); _entryCtrl.dispose(); _btnCtrl.dispose(); _tabCtrl.dispose();
    _usernameCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (_tab == index) return;
    HapticFeedback.selectionClick();

    // Fade out → switch content → fade + slide in
    _tabCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _tab = index;
        _animatingTab = index;
        _error = null;
        _usernameCtrl.clear();
        _passCtrl.clear();
      });
      _tabCtrl.forward();
    });
  }

  bool get _isValid =>
      _usernameCtrl.text.trim().isNotEmpty && _passCtrl.text.length >= 6;

  Future<void> _login() async {
    if (!_isValid || _loading) return;
    HapticFeedback.mediumImpact();
    await _btnCtrl.forward(); await _btnCtrl.reverse();
    setState(() { _loading = true; _error = null; });
    try {
      if (_tab == 0) await _loginUser();
      else           await _loginCompany();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginUser() async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': _usernameCtrl.text.trim().toLowerCase(), 'password': _passCtrl.text}),
      ).timeout(const Duration(seconds: 10));
      final decoded = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      if (!mounted) return;
      if (resp.statusCode == 200 && decoded['success'] == true) {
        await AuthState.instance.saveFromResponse(decoded['data']);
        try {
          final profileResp = await http.get(
            Uri.parse('$_base/users/me'),
            headers: {
              'Authorization': 'Bearer ${AuthState.instance.accessToken}',
            },
          ).timeout(const Duration(seconds: 8));

          if (profileResp.statusCode == 200) {
            final data = jsonDecode(utf8.decode(profileResp.bodyBytes))['data']
            as Map<String, dynamic>;
            final profile   = data['profile'] as Map<String, dynamic>? ?? {};
            final photos    = List<String>.from(data['photoUrls'] ?? []);
            final interests = List<String>.from(data['interests'] ?? []);

            RegistrationState.instance.displayName = data['displayName'] ?? '';
            RegistrationState.instance.username    = data['username'] ?? '';

            globalProfileData = ProfileSetupData(
              photoPaths:    photos,
              birthDay:      profile['birthDay'],
              birthMonth:    profile['birthMonth'],
              birthYear:     profile['birthYear'],
              height:        profile['heightCm']?.toString(),
              gender:        profile['gender'],
              hairColor:     profile['hairColor'],
              eyeColor:      profile['eyeColor'],
              piercing:   profile['hasPiercing'] == true ? 'da' : 'ne',
              tattoo:     profile['hasTattoo']   == true ? 'da' : 'ne',
              interests:     interests,
              iceBreaker:    profile['iceBreaker'] ?? '',
              seekingGender: profile['seekingGender'],
              prefAgeFrom:   profile['prefAgeFrom'],
              prefAgeTo:     profile['prefAgeTo'],
            );
            await ProfileStorage.saveProfile(globalProfileData);
          }
        } catch (_) {}
        if (!mounted) return;
        _navigateTo(const HomeScreen());
      } else {
        setState(() => _error = decoded['message'] ?? 'Pogrešno korisničko ime ili lozinka.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Ne mogu se spojiti na server.');
    }
  }

  Future<void> _loginCompany() async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/company/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': _usernameCtrl.text.trim().toLowerCase(), 'password': _passCtrl.text}),
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
    } catch (_) {
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(children: [
          Positioned.fill(child: AnimatedBuilder(
            animation: _bgAnim,
            builder: (_, __) => CustomPaint(painter: _GradBgPainter(_bgAnim.value)),
          )),

          Center(
            child: FadeTransition(
              opacity: _entryFade,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(24, mq.padding.top + 20, 24, mq.padding.bottom + 24),
                child: Stack(clipBehavior: Clip.none, children: [
                  // Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0E8EA).withOpacity(0.95),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.40), width: 1),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 40, offset: const Offset(0, 16))],
                        ),
                        padding: const EdgeInsets.fromLTRB(22, 48, 22, 28),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                          // Naslov
                          const Text('Dobrodošli nazad!', style: TextStyle(color: _bordo, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.6)),
                          const SizedBox(height: 5),
                          Text('Prijavite se u svoj račun', style: TextStyle(color: _bordo.withOpacity(0.55), fontSize: 14)),
                          const SizedBox(height: 24),

                          // Tab switcher
                          _SmoothTabSwitcher(selected: _tab, onChanged: _switchTab),
                          const SizedBox(height: 24),

                          // Forma s animacijom
                          FadeTransition(
                            opacity: _tabFade,
                            child: SlideTransition(
                              position: _tabSlide,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                _label(_tab == 0 ? 'Korisničko ime' : 'Korisničko ime organizacije'),
                                const SizedBox(height: 8),
                                _inputField(
                                  controller: _usernameCtrl,
                                  hint: _tab == 0 ? 'npr. ivan123' : 'npr. eventco',
                                  icon: _tab == 0 ? Icons.person_rounded : Icons.business_rounded,
                                ),
                                const SizedBox(height: 16),
                                _label('Lozinka'),
                                const SizedBox(height: 8),
                                _passwordField(),
                                if (_error != null) ...[
                                  const SizedBox(height: 12),
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
                                      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500))),
                                    ]),
                                  ),
                                ],
                              ]),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Login gumb
                          ScaleTransition(
                            scale: _btnScale,
                            child: GestureDetector(
                              onTapDown: (_) { if (_isValid && !_loading) _btnCtrl.forward(); },
                              onTapUp: (_) { _btnCtrl.reverse(); _login(); },
                              onTapCancel: () => _btnCtrl.reverse(),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 260),
                                height: 52, width: double.infinity,
                                decoration: BoxDecoration(
                                  color: (_isValid && !_loading) ? _bordo : _bordo.withOpacity(0.28),
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: (_isValid && !_loading) ? [BoxShadow(color: _bordo.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 7))] : [],
                                ),
                                child: Center(child: _loading
                                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                    : Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(_tab == 0 ? Icons.login_rounded : Icons.business_center_rounded,
                                      color: _isValid ? Colors.white : Colors.white.withOpacity(0.45), size: 18),
                                  const SizedBox(width: 10),
                                  Text(_tab == 0 ? 'Prijavi se' : 'Prijavi se kao organizacija',
                                      style: TextStyle(color: _isValid ? Colors.white : Colors.white.withOpacity(0.45), fontSize: 15, fontWeight: FontWeight.w800)),
                                ])),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          Row(children: [
                            Expanded(child: Divider(color: _bordo.withOpacity(0.12))),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('ili', style: TextStyle(color: _bordo.withOpacity(0.35), fontSize: 13))),
                            Expanded(child: Divider(color: _bordo.withOpacity(0.12))),
                          ]),
                          const SizedBox(height: 20),

                          Center(child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: RichText(text: TextSpan(
                              text: _tab == 0 ? 'Nemaš račun? ' : 'Nemaš račun organizacije? ',
                              style: TextStyle(color: _bordo.withOpacity(0.50), fontSize: 14),
                              children: [TextSpan(text: 'Registriraj se', style: const TextStyle(color: _bordo, fontWeight: FontWeight.w800, decoration: TextDecoration.underline))],
                            )),
                          )),
                        ]),
                      ),
                    ),
                  ),

                  // Logo pill
                  Positioned(top: -17, left: 0, right: 0,
                    child: Center(child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                      decoration: BoxDecoration(color: _bordo, borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))]),
                      child: Image.asset('assets/images/logo.png', height: 22, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Text('MeetCute', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900))),
                    )),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(color: _bordo, fontSize: 13.5, fontWeight: FontWeight.w700));

  Widget _inputField({required TextEditingController controller, required String hint, required IconData icon}) =>
      Container(
        height: 52,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _bordo.withOpacity(0.15), width: 1.2),
            boxShadow: [BoxShadow(color: _bordo.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
        child: Row(children: [
          const SizedBox(width: 14),
          Icon(icon, color: _bordo.withOpacity(0.40), size: 20),
          const SizedBox(width: 10),
          Expanded(child: TextField(
            controller: controller,
            style: const TextStyle(color: _bordo, fontSize: 15, fontWeight: FontWeight.w500),
            decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: _bordo.withOpacity(0.28), fontSize: 15), border: InputBorder.none, isDense: true),
          )),
          const SizedBox(width: 12),
        ]),
      );

  Widget _passwordField() => Container(
    height: 52,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _bordo.withOpacity(0.15), width: 1.2),
        boxShadow: [BoxShadow(color: _bordo.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
    child: Row(children: [
      const SizedBox(width: 14),
      Icon(Icons.lock_rounded, color: _bordo.withOpacity(0.40), size: 20),
      const SizedBox(width: 10),
      Expanded(child: TextField(
        controller: _passCtrl, obscureText: !_showPassword,
        style: const TextStyle(color: _bordo, fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(hintText: 'Lozinka', hintStyle: TextStyle(color: _bordo.withOpacity(0.28), fontSize: 15), border: InputBorder.none, isDense: true),
      )),
      GestureDetector(
        onTap: () => setState(() => _showPassword = !_showPassword),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(_showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: _bordo.withOpacity(0.35), size: 20)),
      ),
    ]),
  );
}

// ── Smooth Tab Switcher ───────────────────────────────────────────────────────

class _SmoothTabSwitcher extends StatefulWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _SmoothTabSwitcher({required this.selected, required this.onChanged});
  @override State<_SmoothTabSwitcher> createState() => _SmoothTabSwitcherState();
}

class _SmoothTabSwitcherState extends State<_SmoothTabSwitcher>
    with SingleTickerProviderStateMixin {

  late AnimationController _indicatorCtrl;
  // Smooth interpolation: 0.0 = Osoba, 1.0 = Organizacija
  late Animation<double> _indicatorPos;

  @override
  void initState() {
    super.initState();
    _indicatorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.selected.toDouble(),
    );
    _indicatorPos = CurvedAnimation(
      parent: _indicatorCtrl,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(_SmoothTabSwitcher old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) {
      // Animate indicator smoothly to new position
      if (widget.selected == 1) {
        _indicatorCtrl.animateTo(1.0, curve: Curves.easeOutCubic);
      } else {
        _indicatorCtrl.animateTo(0.0, curve: Curves.easeOutCubic);
      }
    }
  }

  @override
  void dispose() { _indicatorCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _bordoLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _bordo.withOpacity(0.15)),
      ),
      child: LayoutBuilder(builder: (_, box) {
        final tabW = (box.maxWidth - 8) / 2;
        return Stack(children: [
          // Sliding indicator
          AnimatedBuilder(
            animation: _indicatorPos,
            builder: (_, __) => Transform.translate(
              offset: Offset(_indicatorPos.value * tabW, 0),
              child: Container(
                width: tabW,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: _bordo,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: _bordo.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 3))],
                ),
              ),
            ),
          ),
          // Tab labels
          Row(children: [
            _tab(0, Icons.person_rounded, 'Osoba', tabW),
            _tab(1, Icons.business_rounded, 'Organizacija', tabW),
          ]),
        ]);
      }),
    );
  }

  Widget _tab(int index, IconData icon, String label, double w) {
    final active = widget.selected == index;
    return GestureDetector(
      onTap: () => widget.onChanged(index),
      child: SizedBox(width: w, height: double.infinity,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Icon crossfades between active/inactive colour
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Icon(icon, key: ValueKey('icon_${index}_$active'),
                size: 16, color: active ? Colors.white : _bordo.withOpacity(0.50)),
          ),
          const SizedBox(width: 6),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              color: active ? Colors.white : _bordo.withOpacity(0.55),
              fontSize: 13.5, fontWeight: FontWeight.w700,
            ),
            child: Text(label),
          ),
        ]),
      ),
    );
  }
}

// Gradient background
class _GradBgPainter extends CustomPainter {
  final double t;
  _GradBgPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final wave = math.sin(t * math.pi * 2) * 0.5 + 0.5;
    final grad = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: const [Color(0xFF700D25), Color(0xFF4A0818), Color(0xFF0D0005)],
      stops: [0.0, 0.40 + wave * 0.08, 1.0],
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..shader = grad.createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
  }
  @override bool shouldRepaint(_GradBgPainter o) => o.t != t;
}