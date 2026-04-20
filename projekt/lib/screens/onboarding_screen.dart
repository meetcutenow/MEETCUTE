import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart' show kPrimaryDark, kPrimaryLight, HomeScreen;
import 'login_screen.dart' show LoginScreen;
import 'auth_state.dart';
import 'company_auth_state.dart';
import 'company_register_screen.dart';
import 'profile_setup_screen.dart'
    show ProfileSetupData, ProfileStep1, ProfileStep2, ProfileStep3;
import 'notifications_screen.dart'
    show NotificationState, AppNotification, NotifType;
import '../services/profile_storage.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GLOBAL STATE
// ═══════════════════════════════════════════════════════════════════════════════

class RegistrationState {
  static final RegistrationState instance = RegistrationState._();
  RegistrationState._();
  bool isRegistered = false;
  String username   = '';
  String displayName = '';
}

ProfileSetupData globalProfileData = ProfileSetupData(
  photoPaths: [],
  iceBreaker: '',
);

const Color _bordo      = Color(0xFF700D25);
const Color _bordoLight = Color(0xFFF2E8E9);
const String _base = 'http://localhost:8080/api';

// ═══════════════════════════════════════════════════════════════════════════════
// ONBOARDING SCREEN — simplified & pretty
// ═══════════════════════════════════════════════════════════════════════════════

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {

  late final AnimationController _bgCtrl;
  late final AnimationController _entryCtrl;
  late final AnimationController _btnCtrl;

  late final Animation<double> _bgAnim;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _contentFade;
  late final Animation<Offset>  _contentSlide;
  late final Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    _logoFade = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _entryCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)));

    _contentFade = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut));
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic)));

    _btnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _btnScale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose(); _entryCtrl.dispose(); _btnCtrl.dispose();
    super.dispose();
  }

  void _onPersonTap() async {
    HapticFeedback.mediumImpact();
    await _btnCtrl.forward(); await _btnCtrl.reverse();
    if (!mounted) return;
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, a, __) => const RegistrationScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  void _onCompanyTap() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, a, __) => const CompanyRegisterScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  void _onLoginTap() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, a, __) => const LoginScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          )),
      transitionDuration: const Duration(milliseconds: 350),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _bgAnim,
          builder: (_, __) => Stack(children: [
            // Gradient background
            Positioned.fill(child: CustomPaint(painter: _GradBgPainter(_bgAnim.value))),

            // Content
            SafeArea(
              child: Column(children: [
                // ── Logo area — occupies upper half ─────────────────────
                Expanded(
                  flex: 5,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Center(
                        child: SizedBox(
                          width: 160,
                          child: Image.asset('assets/images/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _FallbackLogo()),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Buttons area ─────────────────────────────────────────
                Expanded(
                  flex: 4,
                  child: FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(28, 0, 28, mq.padding.bottom + 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Tagline
                            Text(
                              'Izađi. Upoznaj. Poveži se.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.90),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pronađi događanja u svom gradu.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.50),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // ── Registracija (osoba) ──────────────────
                            ScaleTransition(
                              scale: _btnScale,
                              child: GestureDetector(
                                onTapDown: (_) => _btnCtrl.forward(),
                                onTapUp: (_) { _btnCtrl.reverse(); _onPersonTap(); },
                                onTapCancel: () => _btnCtrl.reverse(),
                                child: Container(
                                  height: 54,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(27),
                                    boxShadow: [BoxShadow(
                                      color: Colors.black.withOpacity(0.20),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    )],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Registriraj se',
                                      style: TextStyle(
                                        color: _bordo,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ── Prijava ───────────────────────────────
                            GestureDetector(
                              onTap: _onLoginTap,
                              child: Container(
                                height: 54,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(27),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.30),
                                    width: 1.2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Prijava',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.90),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Za organizacije ───────────────────────
                            GestureDetector(
                              onTap: _onCompanyTap,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Organiziraš događanja? ',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.45),
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'Registriraj organizaciju',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.75),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.white.withOpacity(0.50),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
      Icon(Icons.favorite_rounded, color: Colors.white, size: 64),
      SizedBox(height: 8),
      Text('MeetCute',
          style: TextStyle(color: Colors.white, fontSize: 28,
              fontWeight: FontWeight.w900, letterSpacing: -0.8)),
    ]);
  }
}

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

    // Subtle glow in the middle
    final glow = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFF9E1535).withOpacity(0.25 + wave * 0.05),
        Colors.transparent,
      ]).createShader(Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.35),
        width: size.width * 1.2, height: size.height * 0.55,
      ));
    canvas.drawOval(Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.35),
      width: size.width * 1.2, height: size.height * 0.55,
    ), glow);
  }
  @override bool shouldRepaint(_GradBgPainter o) => o.t != t;
}

// ═══════════════════════════════════════════════════════════════════════════════
// REGISTRATION SCREEN — unchanged from original
// ═══════════════════════════════════════════════════════════════════════════════

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with TickerProviderStateMixin {

  final _nameCtrl     = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  final _nameFocus    = FocusNode();
  final _userFocus    = FocusNode();
  final _passFocus    = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  String? _error;

  bool get _hasMin8   => _passwordCtrl.text.length >= 8;
  bool get _hasUpper  => _passwordCtrl.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNum    => _passwordCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _passMatch =>
      _passwordCtrl.text == _confirmCtrl.text && _confirmCtrl.text.isNotEmpty;
  bool get _valid =>
      _nameCtrl.text.trim().length >= 2 &&
          _usernameCtrl.text.trim().length >= 3 &&
          _hasMin8 && _hasUpper && _hasNum && _passMatch;

  late final AnimationController _bgCtrl;
  late final AnimationController _cardCtrl;
  late final AnimationController _btnCtrl;
  late final Animation<double>   _bgAnim;
  late final Animation<double>   _cardFade;
  late final Animation<Offset>   _cardSlide;
  late final Animation<double>   _btnScale;
  late final List<AnimationController> _fieldCtrls;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);
    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _cardFade  = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _btnCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _btnScale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn));
    _fieldCtrls = List.generate(6,
            (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 460)));
    _cardCtrl.forward();
    Future.microtask(() async {
      for (final c in _fieldCtrls) {
        await Future.delayed(const Duration(milliseconds: 65));
        if (mounted) c.forward();
      }
    });
    for (final c in [_nameCtrl, _usernameCtrl, _passwordCtrl, _confirmCtrl]) {
      c.addListener(() { if (mounted) setState(() => _error = null); });
    }
  }

  @override
  void dispose() {
    _bgCtrl.dispose(); _cardCtrl.dispose(); _btnCtrl.dispose();
    for (final c in _fieldCtrls) c.dispose();
    _nameCtrl.dispose(); _usernameCtrl.dispose();
    _passwordCtrl.dispose(); _confirmCtrl.dispose();
    _nameFocus.dispose(); _userFocus.dispose();
    _passFocus.dispose(); _confirmFocus.dispose();
    super.dispose();
  }

  void _submit() async {
    FocusScope.of(context).unfocus();
    if (_nameCtrl.text.trim().length < 2) {
      setState(() => _error = 'Ime mora imati najmanje 2 znaka.'); return;
    }
    if (_usernameCtrl.text.trim().length < 3) {
      setState(() => _error = 'Korisničko ime mora imati najmanje 3 znaka.'); return;
    }
    if (!_hasMin8 || !_hasUpper || !_hasNum) {
      setState(() => _error = 'Lozinka ne zadovoljava uvjete.'); return;
    }
    if (!_passMatch) {
      setState(() => _error = 'Lozinke se ne podudaraju.'); return;
    }
    HapticFeedback.mediumImpact();
    await _btnCtrl.forward(); await _btnCtrl.reverse();
    RegistrationState.instance.username    = _usernameCtrl.text.trim();
    RegistrationState.instance.displayName = _nameCtrl.text.trim();
    _PasswordHolder.instance.password = _passwordCtrl.text;
    if (!mounted) return;
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, a, __) => const RegistrationProfileSetupScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  Widget _stagger(int i, Widget child) {
    final ctrl = i < _fieldCtrls.length ? _fieldCtrls[i] : _fieldCtrls.last;
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, c) {
        final v = Curves.easeOutCubic.transform(ctrl.value.clamp(0.0, 1.0));
        return Opacity(opacity: v,
            child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: c));
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgAnim,
              builder: (_, __) => CustomPaint(painter: _GradBgPainter(_bgAnim.value)),
            ),
          ),
          Positioned(
            top: mq.padding.top + 14, left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white.withOpacity(0.30), width: 1),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _cardFade,
              child: SlideTransition(
                position: _cardSlide,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(28, mq.padding.top + 20, 28, mq.padding.bottom + 20),
                  child: Stack(clipBehavior: Clip.none, children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0E8EA),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.30),
                          blurRadius: 32, offset: const Offset(0, 12),
                        )],
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(22, 48, 22, mq.padding.bottom + 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _stagger(0, _Lbl('Ime')),
                            const SizedBox(height: 6),
                            _stagger(0, _Field(
                              ctrl: _nameCtrl, focus: _nameFocus,
                              next: _userFocus, hint: 'npr. Noa',
                              icon: Icons.person_outline_rounded,
                            )),
                            const SizedBox(height: 14),
                            _stagger(1, _Lbl('Korisničko ime')),
                            const SizedBox(height: 6),
                            _stagger(1, _Field(
                              ctrl: _usernameCtrl, focus: _userFocus,
                              next: _passFocus, hint: 'npr. noa123',
                              icon: Icons.alternate_email_rounded,
                            )),
                            const SizedBox(height: 14),
                            _stagger(2, _Lbl('Lozinka')),
                            const SizedBox(height: 6),
                            _stagger(2, _Field(
                              ctrl: _passwordCtrl, focus: _passFocus,
                              next: _confirmFocus, hint: '••••••••',
                              icon: Icons.lock_outline_rounded,
                              obs: _obscurePass,
                              onTog: () => setState(() => _obscurePass = !_obscurePass),
                            )),
                            const SizedBox(height: 14),
                            _stagger(3, _Lbl('Ponovi lozinku')),
                            const SizedBox(height: 6),
                            _stagger(3, _Field(
                              ctrl: _confirmCtrl, focus: _confirmFocus,
                              hint: '••••••••',
                              icon: Icons.lock_outline_rounded,
                              obs: _obscureConfirm,
                              onTog: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              action: TextInputAction.done,
                              onSub: (_) => _submit(),
                            )),
                            const SizedBox(height: 16),
                            _stagger(4, _PassRules(
                              h8: _hasMin8, hU: _hasUpper,
                              hN: _hasNum, hM: _passMatch,
                            )),
                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              _stagger(5, _ErrBox(msg: _error!)),
                            ],
                            const SizedBox(height: 22),
                            _stagger(5,
                              ScaleTransition(
                                scale: _btnScale,
                                child: GestureDetector(
                                  onTapDown: (_) { if (_valid) _btnCtrl.forward(); },
                                  onTapUp: (_) { _btnCtrl.reverse(); _submit(); },
                                  onTapCancel: () => _btnCtrl.reverse(),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 260),
                                    height: 50, width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: _valid ? _bordo : _bordo.withOpacity(0.30),
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: _valid ? [BoxShadow(
                                        color: _bordo.withOpacity(0.40),
                                        blurRadius: 18, offset: const Offset(0, 7),
                                        spreadRadius: -3,
                                      )] : [],
                                    ),
                                    child: Center(
                                      child: Text('Nastavi',
                                          style: TextStyle(
                                            color: _valid ? Colors.white : Colors.white.withOpacity(0.45),
                                            fontSize: 15, fontWeight: FontWeight.w700,
                                          )),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(top: -15, left: 0, right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                          decoration: BoxDecoration(
                            color: _bordo,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(
                              color: Colors.black.withOpacity(0.22),
                              blurRadius: 10, offset: const Offset(0, 3),
                            )],
                          ),
                          child: Image.asset('assets/images/logo.png',
                              height: 22, fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Text('MeetCute',
                                  style: TextStyle(color: Colors.white,
                                      fontSize: 14, fontWeight: FontWeight.w900))),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Shared field widgets (unchanged) ─────────────────────────────────────────

class _Lbl extends StatelessWidget {
  final String text;
  const _Lbl(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(color: _bordo.withOpacity(0.60),
          fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.2));
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final FocusNode? next;
  final String hint;
  final IconData icon;
  final bool obs;
  final VoidCallback? onTog;
  final TextInputAction action;
  final void Function(String)? onSub;

  const _Field({
    required this.ctrl, required this.focus, this.next,
    required this.hint, required this.icon,
    this.obs = false, this.onTog,
    this.action = TextInputAction.next, this.onSub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: _bordo.withOpacity(0.07),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        const SizedBox(width: 13),
        Icon(icon, color: _bordo.withOpacity(0.32), size: 16),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: ctrl, focusNode: focus, obscureText: obs,
          textInputAction: action,
          onSubmitted: onSub ?? (_) { next?.requestFocus(); },
          style: TextStyle(color: _bordo.withOpacity(0.88),
              fontSize: 14.5, fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _bordo.withOpacity(0.26), fontSize: 14.5),
            border: InputBorder.none, isDense: true,
          ),
        )),
        if (onTog != null)
          GestureDetector(onTap: onTog,
              child: Padding(padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    obs ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: _bordo.withOpacity(0.28), size: 16,
                  ))),
      ]),
    );
  }
}

class _PassRules extends StatelessWidget {
  final bool h8, hU, hN, hM;
  const _PassRules({required this.h8, required this.hU,
    required this.hN, required this.hM});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _bordo.withOpacity(0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('UVJETI ZA LOZINKU',
            style: TextStyle(color: _bordo.withOpacity(0.38),
                fontSize: 8.5, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(height: 9),
        _r('Najmanje 8 znakova', h8),
        const SizedBox(height: 5),
        _r('Jedno veliko slovo (A–Z)', hU),
        const SizedBox(height: 5),
        _r('Jedan broj (0–9)', hN),
        const SizedBox(height: 5),
        _r('Lozinke se podudaraju', hM),
      ]),
    );
  }

  Widget _r(String t, bool ok) => Row(children: [
    AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 16, height: 16,
      decoration: BoxDecoration(
        color: ok ? _bordo : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
            color: ok ? _bordo : _bordo.withOpacity(0.20), width: 1.4),
      ),
      child: ok ? const Icon(Icons.check_rounded, color: Colors.white, size: 9) : null,
    ),
    const SizedBox(width: 8),
    Text(t, style: TextStyle(
      color: ok ? _bordo : _bordo.withOpacity(0.38),
      fontSize: 11.5, fontWeight: ok ? FontWeight.w600 : FontWeight.w400,
    )),
  ]);
}

class _ErrBox extends StatelessWidget {
  final String msg;
  const _ErrBox({required this.msg});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0F0),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.redAccent.withOpacity(0.22)),
    ),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 13),
      const SizedBox(width: 8),
      Expanded(child: Text(msg,
          style: const TextStyle(color: Colors.redAccent, fontSize: 12.5))),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// REGISTRATION PROFILE SETUP — unchanged
// ═══════════════════════════════════════════════════════════════════════════════

class RegistrationProfileSetupScreen extends StatefulWidget {
  const RegistrationProfileSetupScreen({super.key});
  @override
  State<RegistrationProfileSetupScreen> createState() => _RegProfileState();
}

class _RegProfileState extends State<RegistrationProfileSetupScreen>
    with TickerProviderStateMixin {

  int _step = 0;
  late ProfileSetupData _data;
  bool _sending = false;
  late AnimationController _progressCtrl;
  late AnimationController _pageCtrl;
  late Animation<Offset> _pageSlide;

  static const int _defaultQuestionId = 1;
  static const String _defaultAnswer  = 'moja tajna';

  @override
  void initState() {
    super.initState();
    _data = globalProfileData.copy();
    _progressCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600), value: 1 / 3);
    _pageCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 380));
    _pageSlide = Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOutCubic));
    _pageCtrl.value = 1.0;
  }

  @override
  void dispose() { _progressCtrl.dispose(); _pageCtrl.dispose(); super.dispose(); }

  void _next() async {
    final err = _validateStep();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: _bordo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ));
      return;
    }

    if (_step == 2) {
      globalProfileData = _data;
      RegistrationState.instance.isRegistered = true;
      final name = RegistrationState.instance.displayName.isNotEmpty
          ? RegistrationState.instance.displayName
          : RegistrationState.instance.username;

      await _registerOnBackend();
      return;
    }

    HapticFeedback.lightImpact();
    _pageCtrl.reset(); _pageCtrl.forward();
    setState(() => _step++);
    _progressCtrl.animateTo((_step + 1) / 3,
        duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
  }

  Future<void> _registerOnBackend() async {
    setState(() => _sending = true);

    final regState = RegistrationState.instance;
    final gender    = _mapGender(_data.gender);
    final hairColor = _mapHair(_data.hairColor);
    final eyeColor  = _mapEye(_data.eyeColor);
    final piercing  = _data.piercing == 'da';
    final tattoo    = _data.tattoo == 'da';
    final height    = int.tryParse(_data.height ?? '170') ?? 170;
    final interestIds = _mapInterestIds(_data.interests);

    final body = {
      'username':          regState.username.trim().toLowerCase(),
      'displayName':       regState.displayName.trim(),
      'password':          _getStoredPassword(),
      'birthDay':          _data.birthDay ?? 1,
      'birthMonth':        _data.birthMonth ?? 1,
      'birthYear':         _data.birthYear ?? 2000,
      'heightCm':          height,
      'gender':            gender,
      'hairColor':         hairColor,
      'eyeColor':          eyeColor,
      'hasPiercing':       piercing,
      'hasTattoo':         tattoo,
      'interestIds':       interestIds.isEmpty ? [1] : interestIds,
      'iceBreaker':        _data.iceBreaker.trim().isEmpty
          ? 'Pozdrav! Priđi mi i reci nešto zanimljivo!'
          : _data.iceBreaker.trim(),
      'secretQuestionId':  _defaultQuestionId,
      'secretAnswer':      _defaultAnswer,
      'seekingGender': _data.seekingGender ?? 'sve',
      'prefAgeFrom':   _data.prefAgeFrom ?? 18,
      'prefAgeTo':     _data.prefAgeTo   ?? 99,
    };
    try {
      final resp = await http.post(
        Uri.parse('$_base/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;

      if (resp.statusCode == 200 && decoded['success'] == true) {
        await AuthState.instance.saveFromResponse(decoded['data']);

        globalProfileData = _data;
        RegistrationState.instance.isRegistered = true;
        ProfileStorage.saveProfile(_data);
        ProfileStorage.saveRegistration(
          RegistrationState.instance.username,
          RegistrationState.instance.displayName,
        );
        final name = regState.displayName.isNotEmpty
            ? regState.displayName : regState.username;

        NotificationState.instance.push(AppNotification(
          id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
          type: NotifType.general,
          title: 'Dobrodošao/la na MeetCute, $name!',
          body: 'Tvoj profil je spreman. Istražuj i upoznaj ljude.',
          accentColor: _bordo,
          timestamp: DateTime.now(),
          isRead: false,
        ));

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (ctx, a, __) => _WelcomeWrapper(username: name),
            transitionsBuilder: (_, a, __, child) => FadeTransition(
                opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
                child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
              (r) => false,
        );
      } else {
        if (mounted) {
          setState(() => _sending = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(decoded['message'] ?? 'Greška pri registraciji.',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ne mogu se spojiti na server: $e',
              style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  String _getStoredPassword() => _PasswordHolder.instance.password;

  String _normalize(String s) => s.toLowerCase()
      .replaceAll('\u0111', 'd').replaceAll('\u0161', 's')
      .replaceAll('\u010d', 'c').replaceAll('\u0107', 'c')
      .replaceAll('\u017e', 'z').replaceAll('\u010c', 'c')
      .replaceAll('\u0106', 'c').replaceAll('\u017d', 'z')
      .replaceAll('\u0160', 's').replaceAll('\u0110', 'd');

  String _mapGender(String? g) {
    if (g == null) return 'ostalo';
    final v = _normalize(g);
    if (v.contains('zen') || v.contains('female')) return 'zensko';
    if (v.contains('mus') || v.contains('male')) return 'musko';
    return 'ostalo';
  }

  String _mapHair(String? h) {
    if (h == null) return 'ostalo';
    final v = _normalize(h);
    if (v.contains('smed')) return 'smeda';
    if (v.contains('plav')) return 'plava';
    if (v.contains('crven')) return 'crvena';
    if (v.contains('crn')) return 'crna';
    if (v.contains('sijed')) return 'sijeda';
    return 'ostalo';
  }

  String _mapEye(String? e) {
    if (e == null) return 'smede';
    final v = _normalize(e);
    if (v.contains('smed')) return 'smede';
    if (v.contains('zelen')) return 'zelene';
    if (v.contains('plav')) return 'plave';
    if (v.contains('siv')) return 'sive';
    return 'smede';
  }

  List<int> _mapInterestIds(List<String> names) {
    const map = {
      'Crtanje': 1, 'Fotografija': 2, 'Pisanje': 3, 'Film': 4,
      'Trčanje': 5, 'Biciklizam': 6, 'Planinarenje': 7, 'Teretana': 8,
      'Boks': 9, 'Tenis': 10, 'Nogomet': 11, 'Odbojka': 12,
      'Kuhanje': 13, 'Putovanja': 14, 'Gaming': 15, 'Formula': 16, 'Glazba': 17,
    };
    return names.map((n) => map[n]).whereType<int>().toList();
  }

  String? _validateStep() {
    if (_step == 0) {
      if (_data.photoPaths.length < 2) return 'Potrebne su najmanje 2 fotografije.';
      if (_data.birthDay == null || _data.birthMonth == null || _data.birthYear == null)
        return 'Datum rođenja je obavezan.';
      final y = _data.birthYear!;
      if (y < 1900 || y > DateTime.now().year - 18) return 'Mora imati 18+ godina.';
      if (_data.birthMonth! < 1 || _data.birthMonth! > 12) return 'Neispravan mjesec (1-12).';
      if (_data.birthDay! < 1 || _data.birthDay! > 31) return 'Neispravan dan (1-31).';
      if (_data.height == null || _data.height!.isEmpty) return 'Visina je obavezna.';
      final h = int.tryParse(_data.height ?? '');
      if (h == null || h < 50 || h > 250) return 'Visina: 50-250 cm.';
      if (_data.gender == null) return 'Spol je obavezan.';
      if (_data.hairColor == null) return 'Boja kose je obavezna.';
      if (_data.eyeColor == null) return 'Boja ociju je obavezna.';
      if (_data.piercing == null) return 'Odaberite opciju za pirsing.';
      if (_data.tattoo == null) return 'Odaberite opciju za tetovazu.';
    }
    if (_step == 1 && _data.interests.isEmpty) return 'Odaberi najmanje jedan interes.';
    if (_step == 2 && _data.iceBreaker.trim().isEmpty) return 'Icebreaker rečenica je obavezna.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: _sending
          ? const Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _bordo),
            SizedBox(height: 18),
            Text('Registracija u tijeku...',
                style: TextStyle(color: _bordo, fontWeight: FontWeight.w600)),
          ]))
          : Column(children: [
        _SetupHeader(step: _step, progressCtrl: _progressCtrl, mq: mq),
        Expanded(child: SlideTransition(
            position: _pageSlide, child: _buildStep(mq))),
        _SetupNextBtn(step: _step, onTap: _next, mq: mq),
      ]),
    );
  }

  Widget _buildStep(MediaQueryData mq) {
    switch (_step) {
      case 0: return ProfileStep1(key: const ValueKey('s1'), data: _data,
          onChange: (d) => setState(() => _data = d), mq: mq);
      case 1: return ProfileStep2(key: const ValueKey('s2'), data: _data,
          onChange: (d) => setState(() => _data = d));
      default: return ProfileStep3(key: const ValueKey('s3'), data: _data,
          onChange: (d) => setState(() => _data = d));
    }
  }
}

class _PasswordHolder {
  static final _PasswordHolder instance = _PasswordHolder._();
  _PasswordHolder._();
  String password = '';
}

class _SetupHeader extends StatelessWidget {
  final int step;
  final AnimationController progressCtrl;
  final MediaQueryData mq;
  const _SetupHeader({required this.step, required this.progressCtrl, required this.mq});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(top: mq.padding.top + 16, left: 24, right: 24, bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AnimatedBuilder(
          animation: progressCtrl,
          builder: (_, __) => LayoutBuilder(builder: (_, box) {
            final w = box.maxWidth * progressCtrl.value;
            return Container(
              height: 10,
              decoration: BoxDecoration(
                  color: _bordo.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8)),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: w.clamp(0.0, box.maxWidth),
                    decoration: BoxDecoration(
                        color: _bordo,
                        borderRadius: BorderRadius.circular(8)),
                  )),
            );
          }),
        ),
        const SizedBox(height: 12),
        Text('Izrada profila',
            style: TextStyle(color: _bordo, fontSize: 22,
                fontWeight: FontWeight.w900, letterSpacing: -0.4)),
      ]),
    );
  }
}

class _SetupNextBtn extends StatefulWidget {
  final int step; final VoidCallback onTap; final MediaQueryData mq;
  const _SetupNextBtn({required this.step, required this.onTap, required this.mq});
  @override State<_SetupNextBtn> createState() => _SetupNextBtnState();
}

class _SetupNextBtnState extends State<_SetupNextBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _c; late Animation<double> _s;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeIn));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final label = widget.step == 2 ? 'Završi' : 'Nastavi';
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 10, 24, widget.mq.padding.bottom + 14),
      child: GestureDetector(
        onTapDown: (_) => _c.forward(),
        onTapUp: (_) { _c.reverse(); widget.onTap(); },
        onTapCancel: () => _c.reverse(),
        child: ScaleTransition(scale: _s,
          child: Container(
            height: 54, width: double.infinity,
            decoration: BoxDecoration(
              color: _bordo,
              borderRadius: BorderRadius.circular(27),
              boxShadow: [BoxShadow(color: _bordo.withOpacity(0.35),
                  blurRadius: 18, offset: const Offset(0, 7), spreadRadius: -3)],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(label, style: const TextStyle(color: Colors.white,
                  fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(width: 10),
              Container(width: 26, height: 26,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.chevron_right_rounded,
                      color: Colors.white, size: 18)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WELCOME WRAPPER + DIALOG — unchanged
// ═══════════════════════════════════════════════════════════════════════════════

class _WelcomeWrapper extends StatefulWidget {
  final String username;
  const _WelcomeWrapper({required this.username});
  @override State<_WelcomeWrapper> createState() => _WelcomeWrapperState();
}

class _WelcomeWrapperState extends State<_WelcomeWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showDialog());
  }

  void _showDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true, barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final c = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(c),
            child: Center(child: _WelcomeDialog(
              username: widget.username,
              onClose: () => Navigator.pop(ctx),
            )),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => const HomeScreen();
}

class _WelcomeDialog extends StatelessWidget {
  final String username;
  final VoidCallback onClose;
  const _WelcomeDialog({required this.username, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF0E8EA),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 40, offset: const Offset(0, 14),
            )],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              height: 100, width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xFF700D25), Color(0xFF4A0818)],
                ),
              ),
              child: Center(
                child: SizedBox(
                  height: 58,
                  child: Image.asset('assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Text('MeetCute',
                          style: TextStyle(color: Colors.white, fontSize: 22,
                              fontWeight: FontWeight.w900))),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Dobrodošao/la,',
                    style: TextStyle(color: _bordo.withOpacity(0.40),
                        fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(username,
                    style: const TextStyle(color: _bordo, fontSize: 22,
                        fontWeight: FontWeight.w900, letterSpacing: -0.4)),
                const SizedBox(height: 11),
                Container(height: 1, color: _bordo.withOpacity(0.08)),
                const SizedBox(height: 11),
                Text('Tvoj profil je spreman. Istražuj događanja '
                    'i upoznaj ljude koji dijele tvoje interese.',
                    style: TextStyle(color: _bordo.withOpacity(0.52),
                        fontSize: 13.5, height: 1.55)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    height: 50, width: double.infinity,
                    decoration: BoxDecoration(
                      color: _bordo,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: _bordo.withOpacity(0.35),
                          blurRadius: 16, offset: const Offset(0, 6), spreadRadius: -3)],
                    ),
                    child: const Center(child: Text('Kreni',
                        style: TextStyle(color: Colors.white,
                            fontSize: 15, fontWeight: FontWeight.w700))),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}