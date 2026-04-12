import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'home_screen.dart' show kPrimaryDark, kPrimaryLight, HomeScreen;
import 'profile_setup_screen.dart'
    show ProfileSetupData, ProfileStep1, ProfileStep2, ProfileStep3;
import 'notifications_screen.dart'
    show NotificationState, AppNotification, NotifType;

// ═══════════════════════════════════════════════════════════════════════════════
// GLOBAL STATE
// ═══════════════════════════════════════════════════════════════════════════════

class RegistrationState {
  static final RegistrationState instance = RegistrationState._();
  RegistrationState._();
  bool isRegistered = false;
  String username = '';
  String displayName = ''; // ime koje se prikazuje na profilu
}

ProfileSetupData globalProfileData = ProfileSetupData(
  photoPaths: [],
  iceBreaker: '',
);

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED PAINTERS & PARTICLES
// ═══════════════════════════════════════════════════════════════════════════════

class _Particle {
  final double x, y, size, speed, phase, opacity;
  const _Particle({
    required this.x, required this.y, required this.size,
    required this.speed, required this.phase, required this.opacity,
  });
}

class _BgPainter extends CustomPainter {
  final double t;
  _BgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final wave = math.sin(t * math.pi * 2);
    final gradient = LinearGradient(
      begin: Alignment(-0.4 + wave * 0.25, -1),
      end: Alignment(0.4 - wave * 0.18, 1),
      colors: const [
        Color(0xFF0D0003), Color(0xFF3A0610), Color(0xFF700D25),
        Color(0xFF3A0610), Color(0xFF060001),
      ],
      stops: const [0.0, 0.22, 0.50, 0.78, 1.0],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.36),
        width: size.width * 1.6, height: size.height * 0.85,
      ),
      Paint()..shader = RadialGradient(colors: [
        const Color(0xFFFF6B8A).withOpacity(0.14 + wave.abs() * 0.04),
        Colors.transparent,
      ]).createShader(Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.36),
        width: size.width * 1.6, height: size.height * 0.85,
      )),
    );
  }

  @override
  bool shouldRepaint(_BgPainter o) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// ONBOARDING SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {

  late final AnimationController _bgCtrl;
  late final AnimationController _particleCtrl;
  late final AnimationController _heartCtrl;
  late final AnimationController _logoCtrl;
  late final AnimationController _contentCtrl;
  late final AnimationController _btnCtrl;

  late final Animation<double> _logoBigFade;
  late final Animation<double> _logoMoveUp;
  late final Animation<double> _logoShrink;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _btnScale;

  final List<_Particle> _particles = [];
  final _rng = math.Random(42);

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 22; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(), y: _rng.nextDouble(),
        size: 2.0 + _rng.nextDouble() * 6.5,
        speed: 0.22 + _rng.nextDouble() * 0.55,
        phase: _rng.nextDouble(),
        opacity: 0.05 + _rng.nextDouble() * 0.18,
      ));
    }

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))..repeat();
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 9000))..repeat();
    _heartCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));
    _logoBigFade = CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.45, curve: Curves.easeOut));
    _logoMoveUp = CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.38, 0.78, curve: Curves.easeOutCubic));
    _logoShrink = CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.38, 0.78, curve: Curves.easeOutCubic));

    _contentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 820));
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.09), end: Offset.zero)
        .animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic));

    _btnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 130));
    _btnScale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1380));
    _contentCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose(); _particleCtrl.dispose(); _heartCtrl.dispose();
    _logoCtrl.dispose(); _contentCtrl.dispose(); _btnCtrl.dispose();
    super.dispose();
  }

  void _onStart() async {
    HapticFeedback.mediumImpact();
    await _btnCtrl.forward();
    await _btnCtrl.reverse();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, a, __) => const RegistrationScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 480),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final sh = mq.size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: AnimatedBuilder(
          animation: Listenable.merge([_bgCtrl, _particleCtrl]),
          builder: (_, child) => Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _BgPainter(_bgCtrl.value))),
            ..._particles.map((p) {
              final t = (_particleCtrl.value + p.phase) % 1.0;
              final yp = (p.y - t * p.speed * 0.26 + 1.0) % 1.0;
              final pulse = math.sin(t * math.pi * 2) * 0.5 + 0.5;
              return Positioned(
                left: p.x * sw, top: yp * sh,
                child: Opacity(
                  opacity: (p.opacity * (0.35 + pulse * 0.65)).clamp(0.0, 1.0),
                  child: Container(
                    width: p.size, height: p.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.white,
                      boxShadow: [BoxShadow(
                        color: const Color(0xFFFF6B8A).withOpacity(0.38),
                        blurRadius: p.size * 2.5,
                      )],
                    ),
                  ),
                ),
              );
            }),
            child!,
          ]),
          child: Stack(children: [
            AnimatedBuilder(
              animation: Listenable.merge([_logoCtrl, _heartCtrl]),
              builder: (_, __) {
                final topOrig = sh * 0.38;
                final topDest = mq.padding.top + 50.0;
                final top = lerpDouble(topOrig, topDest, _logoMoveUp.value)!;
                final scale = lerpDouble(1.0, 0.60, _logoShrink.value)!;
                return Positioned(
                  top: top, left: 0, right: 0,
                  child: FadeTransition(
                    opacity: _logoBigFade,
                    child: Center(
                      child: Transform.scale(
                        scale: scale,
                        child: _LogoBadge(heartT: _heartCtrl.value),
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: mq.padding.top + 112, left: 0, right: 0, bottom: 0,
              child: FadeTransition(
                opacity: _contentFade,
                child: SlideTransition(
                  position: _contentSlide,
                  child: _buildContent(mq),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildContent(MediaQueryData mq) {
    final features = <Map<String, String>>[
      {'emoji': '🗺️', 'text': 'izaći i istraživati'},
      {'emoji': '🎉', 'text': 'otkriti događanja u blizini'},
      {'emoji': '☕', 'text': 'organizirati vlastita događanja'},
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 70),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Colors.white, Color(0xFFFFD0DC)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ).createShader(b),
          child: const Text('Pozdrav! 💘',
              style: TextStyle(
                color: Colors.white, fontSize: 34,
                fontWeight: FontWeight.w900, letterSpacing: -0.8, height: 1.1,
              )),
        ),
        const SizedBox(height: 13),
        Text('Jesi li spreman/na...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 17, fontWeight: FontWeight.w400, letterSpacing: 0.3,
            )),
        const SizedBox(height: 24),
        for (int i = 0; i < features.length; i++)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 520 + i * 120),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.translate(
              offset: Offset(0, 16 * (1 - v.clamp(0.0, 1.0))),
              child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 32),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(features[i]['emoji']!, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Text(features[i]['text']!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.84),
                      fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.2,
                    )),
              ]),
            ),
          ),
        const SizedBox(height: 14),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 950),
          curve: Curves.easeOut,
          builder: (_, v, __) => Opacity(
            opacity: v.clamp(0.0, 1.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    const Color(0xFFFF6B8A).withOpacity(0.20),
                    const Color(0xFFAA1535).withOpacity(0.20),
                  ]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.16), width: 1),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('✨', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 10),
                  Text('i upoznati svoju osobu?', style: TextStyle(
                    color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.w800, letterSpacing: -0.2,
                  )),
                ]),
              ),
            ),
          ),
        ),
        const Spacer(),
        Padding(
          padding: EdgeInsets.fromLTRB(28, 0, 28, mq.padding.bottom + 30),
          child: ScaleTransition(
            scale: _btnScale,
            child: GestureDetector(
              onTapDown: (_) => _btnCtrl.forward(),
              onTapUp: (_) { _btnCtrl.reverse(); _onStart(); },
              onTapCancel: () => _btnCtrl.reverse(),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFFFF6B8A), Color(0xFF700D25), Color(0xFF3A0410)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF700D25).withOpacity(0.55),
                    blurRadius: 26, offset: const Offset(0, 10),
                  )],
                ),
                child: Stack(alignment: Alignment.center, children: [
                  AnimatedBuilder(
                    animation: _particleCtrl,
                    builder: (_, __) => Positioned(
                      left: -60 + _particleCtrl.value * 400,
                      top: 0, bottom: 0,
                      child: Container(width: 50,
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [
                            Colors.white.withOpacity(0),
                            Colors.white.withOpacity(0.14),
                            Colors.white.withOpacity(0),
                          ]))),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text('Napravi moj profil!', style: TextStyle(
                        color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w800, letterSpacing: 0.2,
                      )),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoBadge extends StatelessWidget {
  final double heartT;
  const _LogoBadge({required this.heartT});
  @override
  Widget build(BuildContext context) {
    final pulse = math.sin(heartT * math.pi) * 0.09 + 1.0;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Transform.scale(scale: pulse,
        child: Container(width: 130, height: 130,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              const Color(0xFFFF6B8A).withOpacity(0.26),
              const Color(0xFF700D25).withOpacity(0.07),
              Colors.transparent,
            ]),
          ),
        ),
      ),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 56, padding: const EdgeInsets.symmetric(horizontal: 26),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF700D25).withOpacity(0.90),
                  const Color(0xFF3A0610).withOpacity(0.96),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
              boxShadow: [BoxShadow(
                color: const Color(0xFF700D25).withOpacity(0.65),
                blurRadius: 34, spreadRadius: -4,
              )],
            ),
            child: Center(
              child: Image.asset('assets/images/logo.png', height: 28, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text('MeetCute',
                    style: TextStyle(color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// REGISTRATION SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override State<RegistrationScreen> createState() => _RegistrationScreenState();
}


class _RegistrationScreenState extends State<RegistrationScreen>
    with TickerProviderStateMixin {

  // ── Controllers ─────────────────────────────────────────────────────────────
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

  // Password rules
  bool get _hasMin8   => _passwordCtrl.text.length >= 8;
  bool get _hasUpper  => _passwordCtrl.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNum    => _passwordCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _passMatch => _passwordCtrl.text == _confirmCtrl.text && _confirmCtrl.text.isNotEmpty;

  bool get _valid =>
      _nameCtrl.text.trim().length >= 2 &&
          _usernameCtrl.text.trim().length >= 3 &&
          _hasMin8 && _hasUpper && _hasNum && _passMatch;

  // ── Animations ───────────────────────────────────────────────────────────────
  late final AnimationController _bgCtrl;
  late final AnimationController _entryCtrl;
  late final AnimationController _btnCtrl;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;
  late final Animation<double> _btnScale;

  // stagger for fields
  late final List<AnimationController> _fieldCtrls;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200))..repeat();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _btnCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _btnScale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn));

    _fieldCtrls = List.generate(5,
            (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 500)));

    _entryCtrl.forward();
    Future.microtask(() async {
      for (final c in _fieldCtrls) {
        await Future.delayed(const Duration(milliseconds: 90));
        if (mounted) c.forward();
      }
    });

    for (final c in [_nameCtrl, _usernameCtrl, _passwordCtrl, _confirmCtrl]) {
      c.addListener(() { if (mounted) setState(() => _error = null); });
    }
  }

  @override
  void dispose() {
    _bgCtrl.dispose(); _entryCtrl.dispose(); _btnCtrl.dispose();
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
      setState(() => _error = 'Username mora imati najmanje 3 znaka.'); return;
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
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, a, __) => const RegistrationProfileSetupScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 420),
    ));
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0005),
        body: Stack(children: [

          // ── Animated background ───────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgCtrl,
              builder: (_, __) {
                final t = _bgCtrl.value;
                return CustomPaint(painter: _RegBgPainter(t));
              },
            ),
          ),

          // ── Main content ──────────────────────────────────────────────────
          Positioned.fill(
            child: FadeTransition(
              opacity: _entryFade,
              child: SlideTransition(
                position: _entrySlide,
                child: _buildContent(mq),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildContent(MediaQueryData mq) {
    return Column(children: [

      // ── TOP: logo + heading ───────────────────────────────────────────────
      Expanded(
        flex: 4,
        child: Padding(
          padding: EdgeInsets.fromLTRB(32, mq.padding.top + 20, 32, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // back
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 14),
              ),
            ),

            const Spacer(),

            // logo mark
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: kPrimaryDark,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.55), blurRadius: 18, offset: const Offset(0, 6))],
              ),
              child: Center(
                child: Image.asset('assets/images/logo.png', height: 22, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.favorite_rounded, color: Colors.white, size: 22)),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Stvori račun',
                style: TextStyle(color: Colors.white, fontSize: 32,
                    fontWeight: FontWeight.w800, letterSpacing: -1.0, height: 1.1)),
            const SizedBox(height: 8),
            Text('Ispuni podatke i pronađi svoju osobu.',
                style: TextStyle(color: Colors.white.withOpacity(0.42),
                    fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: 0.1)),

            const SizedBox(height: 28),
          ]),
        ),
      ),

      // ── BOTTOM: form card ─────────────────────────────────────────────────
      Expanded(
        flex: 7,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 40, offset: const Offset(0, -8)),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(28, 32, 28, mq.padding.bottom + 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Osobni podaci ─────────────────────────────────────────────
              _staggerField(0, _regField(
                ctrl: _nameCtrl, focus: _nameFocus, next: _userFocus,
                label: 'Ime', hint: 'Npr. Ana, Luka...',
                icon: Icons.person_outline_rounded,
              )),
              const SizedBox(height: 14),
              _staggerField(1, _regField(
                ctrl: _usernameCtrl, focus: _userFocus, next: _passFocus,
                label: 'Username', hint: 'korisnickoime',
                icon: Icons.alternate_email_rounded,
              )),
              const SizedBox(height: 24),

              // ── Lozinka ───────────────────────────────────────────────────
              _staggerField(2, _regField(
                ctrl: _passwordCtrl, focus: _passFocus, next: _confirmFocus,
                label: 'Lozinka', hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscure: _obscurePass,
                togObs: () => setState(() => _obscurePass = !_obscurePass),
              )),
              const SizedBox(height: 14),
              _staggerField(3, _regField(
                ctrl: _confirmCtrl, focus: _confirmFocus,
                label: 'Ponovi lozinku', hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscure: _obscureConfirm,
                togObs: () => setState(() => _obscureConfirm = !_obscureConfirm),
                action: TextInputAction.done,
                onSub: (_) => _submit(),
              )),

              // ── Pravila lozinke ispod oba unosa ───────────────────────────
              const SizedBox(height: 16),
              _staggerField(4, _passwordRules()),

              // ── Error ─────────────────────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.30)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 15),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5))),
                  ]),
                ),
              ],

              const SizedBox(height: 28),

              // ── Submit ────────────────────────────────────────────────────
              ScaleTransition(
                scale: _btnScale,
                child: GestureDetector(
                  onTapDown: (_) { if (_valid) _btnCtrl.forward(); },
                  onTapUp: (_) { _btnCtrl.reverse(); _submit(); },
                  onTapCancel: () => _btnCtrl.reverse(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    height: 54,
                    decoration: BoxDecoration(
                      color: _valid ? kPrimaryDark : const Color(0xFFE0D4D6),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _valid ? [BoxShadow(
                        color: kPrimaryDark.withOpacity(0.38),
                        blurRadius: 18, offset: const Offset(0, 7),
                      )] : [],
                    ),
                    child: Center(child: Text(
                      'Nastavi',
                      style: TextStyle(
                        color: _valid ? Colors.white : Colors.white.withOpacity(0.50),
                        fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2,
                      ),
                    )),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Center(child: Text('Tvoji podaci su sigurni i privatni.',
                  style: TextStyle(color: Colors.black.withOpacity(0.28), fontSize: 12))),
            ]),
          ),
        ),
      ),
    ]);
  }

  // ── Stagger wrapper ──────────────────────────────────────────────────────────
  Widget _staggerField(int idx, Widget child) {
    final ctrl = idx < _fieldCtrls.length ? _fieldCtrls[idx] : _fieldCtrls.last;
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, c) {
        final v = Curves.easeOutCubic.transform(ctrl.value.clamp(0.0, 1.0));
        return Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: c));
      },
      child: child,
    );
  }

  // ── Field widget ─────────────────────────────────────────────────────────────
  Widget _regField({
    required TextEditingController ctrl,
    required FocusNode focus,
    FocusNode? next,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? togObs,
    TextInputAction action = TextInputAction.next,
    void Function(String)? onSub,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(
        color: Colors.black.withOpacity(0.55),
        fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.4,
      )),
      const SizedBox(height: 6),
      Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F3F4),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: kPrimaryDark.withOpacity(0.10), width: 1),
        ),
        child: Row(children: [
          const SizedBox(width: 14),
          Icon(icon, color: kPrimaryDark.withOpacity(0.38), size: 17),
          const SizedBox(width: 10),
          Expanded(child: TextField(
            controller: ctrl, focusNode: focus, obscureText: obscure,
            textInputAction: action,
            onChanged: (_) { if (mounted) setState(() {}); },
            onSubmitted: onSub ?? (_) { next?.requestFocus(); },
            style: const TextStyle(color: Color(0xFF1A0A12), fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.black.withOpacity(0.25), fontSize: 15),
              border: InputBorder.none, isDense: true,
            ),
          )),
          if (togObs != null) GestureDetector(
            onTap: togObs,
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: kPrimaryDark.withOpacity(0.30), size: 17),
            ),
          ),
        ]),
      ),
    ]);
  }

  // ── Password rules ───────────────────────────────────────────────────────────
  Widget _passwordRules() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3F4),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Uvjeti za lozinku', style: TextStyle(
          color: Colors.black.withOpacity(0.45),
          fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5,
        )),
        const SizedBox(height: 10),
        _rule('Najmanje 8 znakova', _hasMin8),
        const SizedBox(height: 6),
        _rule('Jedno veliko slovo (A–Z)', _hasUpper),
        const SizedBox(height: 6),
        _rule('Jedan broj (0–9)', _hasNum),
        const SizedBox(height: 6),
        _rule('Lozinke se podudaraju', _passMatch),
      ]),
    );
  }

  Widget _rule(String text, bool ok) {
    return Row(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 16, height: 16,
        decoration: BoxDecoration(
          color: ok ? kPrimaryDark : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: ok ? kPrimaryDark : Colors.black.withOpacity(0.18),
            width: 1.5,
          ),
        ),
        child: ok ? const Icon(Icons.check_rounded, color: Colors.white, size: 9) : null,
      ),
      const SizedBox(width: 8),
      Text(text, style: TextStyle(
        color: ok ? kPrimaryDark : Colors.black.withOpacity(0.38),
        fontSize: 12, fontWeight: ok ? FontWeight.w600 : FontWeight.w400,
      )),
    ]);
  }
}

// ── Registration background painter ─────────────────────────────────────────

class _RegBgPainter extends CustomPainter {
  final double t;
  _RegBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Deep dark base
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF0A0005));

    // Subtle gradient overlay
    final wave = math.sin(t * math.pi * 2);
    final grad = LinearGradient(
      begin: Alignment(wave * 0.3 - 0.2, -1),
      end: Alignment(-wave * 0.2 + 0.2, 0.6),
      colors: const [Color(0xFF2A0510), Color(0xFF0A0005)],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.65),
      Paint()..shader = grad.createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.65)),
    );

    // Single soft glow — top center
    final glowPaint = Paint()..shader = RadialGradient(
      colors: [
        const Color(0xFF700D25).withOpacity(0.30 + wave.abs() * 0.08),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.18),
      width: size.width * 1.2, height: size.height * 0.55,
    ));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.18),
        width: size.width * 1.2, height: size.height * 0.55,
      ),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(_RegBgPainter o) => true;
}


// ═══════════════════════════════════════════════════════════════════════════════
// REGISTRATION PROFILE SETUP SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class RegistrationProfileSetupScreen extends StatefulWidget {
  const RegistrationProfileSetupScreen({super.key});
  @override State<RegistrationProfileSetupScreen> createState() => _RegProfileState();
}

class _RegProfileState extends State<RegistrationProfileSetupScreen>
    with TickerProviderStateMixin {

  int _step = 0;
  late ProfileSetupData _data;
  late AnimationController _progressCtrl;
  late AnimationController _pageCtrl;
  late Animation<Offset> _pageSlide;

  @override
  void initState() {
    super.initState();
    _data = globalProfileData.copy();
    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600), value: 1 / 3);
    _pageCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _pageSlide = Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOutCubic));
    _pageCtrl.value = 1.0;
  }

  @override void dispose() { _progressCtrl.dispose(); _pageCtrl.dispose(); super.dispose(); }

  void _next() {
    final err = _validateStep();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: kPrimaryDark,
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
      NotificationState.instance.push(AppNotification(
        id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
        type: NotifType.general,
        title: 'Dobrodošao/la na MeetCute, $name! 💘',
        body: 'Tvoj profil je spreman! Istraži događanja oko sebe i pronađi svog Cutieja. 🚀✨',
        accentColor: const Color(0xFF700D25),
        timestamp: DateTime.now(),
        isRead: false,
      ));
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (ctx, a, __) => _WelcomeWrapper(username: name),
          transitionsBuilder: (_, a, __, child) => FadeTransition(
              opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
            (r) => false,
      );
      return;
    }
    HapticFeedback.lightImpact();
    _pageCtrl.reset(); _pageCtrl.forward();
    setState(() => _step++);
    _progressCtrl.animateTo((_step + 1) / 3,
        duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
  }

  String? _validateStep() {
    if (_step == 0) {
      if (_data.photoPaths.length < 2) return 'Potrebne su najmanje 2 fotografije.';
      if (_data.birthDay == null || _data.birthMonth == null || _data.birthYear == null)
        return 'Datum rođenja je obavezan.';
      final y = _data.birthYear!;
      final now = DateTime.now().year;
      if (y < 1900 || y > now - 16) return 'Unesite ispravnu godinu (mora imati 16+ godina).';
      if (_data.birthMonth! < 1 || _data.birthMonth! > 12) return 'Neispravan mjesec (1–12).';
      if (_data.birthDay! < 1 || _data.birthDay! > 31) return 'Neispravan dan (1–31).';
      if (_data.height == null || _data.height!.isEmpty) return 'Visina je obavezna.';
      final h = int.tryParse(_data.height ?? '');
      if (h == null || h < 100 || h > 250) return 'Unesite ispravnu visinu (100–250 cm).';
      if (_data.gender == null) return 'Spol je obavezan.';
      if (_data.hairColor == null) return 'Boja kose je obavezna.';
      if (_data.eyeColor == null) return 'Boja očiju je obavezna.';
      if (_data.piercing == null) return 'Odaberite opciju za pirsing.';
      if (_data.tattoo == null) return 'Odaberite opciju za tetovažu.';
    }
    if (_step == 1) {
      if (_data.interests.isEmpty) return 'Odaberi najmanje jedan interes.';
    }
    if (_step == 2) {
      if (_data.iceBreaker.trim().isEmpty) return 'Icebreaker rečenica je obavezna.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        _SetupHeader(step: _step, progressCtrl: _progressCtrl, mq: mq),
        Expanded(child: SlideTransition(position: _pageSlide, child: _buildStep(mq))),
        _SetupNextBtn(step: _step, onTap: _next, mq: mq),
      ]),
    );
  }

  Widget _buildStep(MediaQueryData mq) {
    switch (_step) {
      case 0:  return ProfileStep1(key: const ValueKey('s1'), data: _data, onChange: (d) => setState(() => _data = d), mq: mq);
      case 1:  return ProfileStep2(key: const ValueKey('s2'), data: _data, onChange: (d) => setState(() => _data = d));
      default: return ProfileStep3(key: const ValueKey('s3'), data: _data, onChange: (d) => setState(() => _data = d));
    }
  }
}

class _SetupHeader extends StatelessWidget {
  final int step;
  final AnimationController progressCtrl;
  final MediaQueryData mq;
  const _SetupHeader({required this.step, required this.progressCtrl, required this.mq});
  static const _subs = ['Slike & osobni podaci', 'Tvoji interesi', 'Tvoj icebreaker'];
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(top: mq.padding.top + 16, left: 22, right: 22, bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Izrada profila', style: TextStyle(color: kPrimaryDark, fontSize: 28,
            fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(_subs[step], style: TextStyle(color: kPrimaryDark.withOpacity(0.45),
            fontSize: 13.5, fontWeight: FontWeight.w500)),
        const SizedBox(height: 14),
        AnimatedBuilder(
          animation: progressCtrl,
          builder: (_, __) => LayoutBuilder(builder: (_, box) {
            final filled = box.maxWidth * progressCtrl.value;
            return Container(
              height: 8,
              decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(4)),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: filled.clamp(0.0, box.maxWidth),
                  decoration: BoxDecoration(color: kPrimaryDark, borderRadius: BorderRadius.circular(4)),
                ),
              ]),
            );
          }),
        ),
      ]),
    );
  }
}

class _SetupNextBtn extends StatefulWidget {
  final int step; final VoidCallback onTap; final MediaQueryData mq;
  const _SetupNextBtn({required this.step, required this.onTap, required this.mq});
  @override State<_SetupNextBtn> createState() => _SetupNextBtnState();
}
class _SetupNextBtnState extends State<_SetupNextBtn> with SingleTickerProviderStateMixin {
  late AnimationController _c; late Animation<double> _s;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.94).animate(CurvedAnimation(parent: _c, curve: Curves.easeIn));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final label = widget.step == 2 ? 'Završetak' : 'Iduće';
    return Padding(
      padding: EdgeInsets.only(bottom: widget.mq.padding.bottom + 16, top: 10),
      child: Center(
        child: GestureDetector(
          onTapDown: (_) => _c.forward(),
          onTapUp: (_) { _c.reverse(); widget.onTap(); },
          onTapCancel: () => _c.reverse(),
          child: ScaleTransition(scale: _s,
            child: Container(
              height: 48, padding: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: kPrimaryDark, borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.30), blurRadius: 16, offset: const Offset(0, 5))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.20), shape: BoxShape.circle),
                  child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WELCOME WRAPPER + DIALOG
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
      barrierColor: Colors.black.withOpacity(0.48),
      transitionDuration: const Duration(milliseconds: 460),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.83, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
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

class _WelcomeDialog extends StatefulWidget {
  final String username; final VoidCallback onClose;
  const _WelcomeDialog({required this.username, required this.onClose});
  @override State<_WelcomeDialog> createState() => _WelcomeDialogState();
}
class _WelcomeDialogState extends State<_WelcomeDialog> with TickerProviderStateMixin {
  late final AnimationController _sparkCtrl;
  late final AnimationController _floatCtrl;
  final _rng = math.Random(17);
  final List<_Particle> _sparks = [];
  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 14; i++) {
      _sparks.add(_Particle(x: _rng.nextDouble(), y: _rng.nextDouble(),
          size: 2.5 + _rng.nextDouble() * 5, speed: 0.35 + _rng.nextDouble() * 0.5,
          phase: _rng.nextDouble(), opacity: 0.10 + _rng.nextDouble() * 0.20));
    }
    _sparkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
  }
  @override void dispose() { _sparkCtrl.dispose(); _floatCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.22), blurRadius: 48, offset: const Offset(0, 18))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedBuilder(
                animation: Listenable.merge([_sparkCtrl, _floatCtrl]),
                builder: (_, __) => SizedBox(height: 118, child: Stack(children: [
                  Positioned.fill(child: Container(decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [Color(0xFF700D25), Color(0xFF3A0610), Color(0xFF0D0003)]),
                  ))),
                  ..._sparks.map((s) {
                    final t = (_sparkCtrl.value + s.phase) % 1.0;
                    final op = math.sin(t * math.pi).clamp(0.0, 1.0);
                    return Positioned(left: s.x * 340, top: s.y * 118,
                        child: Opacity(opacity: op * s.opacity,
                            child: Icon(Icons.star_rounded, color: kPrimaryLight, size: s.size)));
                  }),
                  Center(child: Transform.translate(
                    offset: Offset(0, -3 + _floatCtrl.value * 7),
                    child: Container(width: 66, height: 66,
                        decoration: BoxDecoration(color: kPrimaryLight.withOpacity(0.13),
                            shape: BoxShape.circle, border: Border.all(color: kPrimaryLight.withOpacity(0.26), width: 2)),
                        child: const Icon(Icons.celebration_rounded, color: Colors.white, size: 30)),
                  )),
                ])),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                child: Column(children: [
                  Text('Dobrodošao/la, ${widget.username}! 💘',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: kPrimaryDark, fontSize: 19,
                          fontWeight: FontWeight.w900, letterSpacing: -0.4)),
                  const SizedBox(height: 10),
                  Text('Tvoj profil je spreman! 🎉\n\nIstraži događanja u blizini i pronađi svog Cutieja. Kreni van — avantura čeka! ✨',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kPrimaryDark.withOpacity(0.60), fontSize: 13.5, height: 1.65)),
                  const SizedBox(height: 16),
                  Wrap(spacing: 7, runSpacing: 7, alignment: WrapAlignment.center,
                      children: const [_WChip('🗺️ Exploriraj'), _WChip('🎉 Events'),
                        _WChip('☕ Meetupi'), _WChip('💬 Chat')]),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF6B8A), Color(0xFF700D25)]),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.33), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: const Center(child: Text('Krećemo! 🚀',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
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

class _WChip extends StatelessWidget {
  final String label;
  const _WChip(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimaryDark.withOpacity(0.10))),
    child: Text(label, style: const TextStyle(color: kPrimaryDark, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}