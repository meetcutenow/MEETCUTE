import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart' show HomeScreen, kPrimaryDark;
import 'onboarding_screen.dart' show RegistrationState;
import 'auth_state.dart';

// ─── Boje (iste kao u onboarding) ────────────────────────────────────────────
const Color _bordo      = Color(0xFF700D25);
const Color _bordoLight = Color(0xFFF2E8E9);

// ─── Backend base URL ─────────────────────────────────────────────────────────
// Android emulator → 10.0.2.2   |   fizički uređaj → IP tvog računala
const String _base = 'http://localhost:8080/api';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {

  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _userFocus    = FocusNode();
  final _passFocus    = FocusNode();

  bool    _obscure  = true;
  bool    _loading  = false;
  String? _error;

  late final AnimationController _bgCtrl;
  late final AnimationController _cardCtrl;
  late final AnimationController _btnCtrl;
  late final Animation<double>   _bgAnim;
  late final Animation<double>   _cardFade;
  late final Animation<Offset>   _cardSlide;
  late final Animation<double>   _btnScale;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 5))..repeat();
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _cardCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 650));
    _cardFade  = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));

    _btnCtrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 120));
    _btnScale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn));

    _cardCtrl.forward();

    for (final c in [_usernameCtrl, _passwordCtrl]) {
      c.addListener(() { if (mounted) setState(() => _error = null); });
    }
  }

  @override
  void dispose() {
    _bgCtrl.dispose(); _cardCtrl.dispose(); _btnCtrl.dispose();
    _usernameCtrl.dispose(); _passwordCtrl.dispose();
    _userFocus.dispose(); _passFocus.dispose();
    super.dispose();
  }

  bool get _valid =>
      _usernameCtrl.text.trim().isNotEmpty &&
          _passwordCtrl.text.isNotEmpty;

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_valid || _loading) return;
    HapticFeedback.mediumImpact();

    setState(() { _loading = true; _error = null; });

    try {
      final resp = await http.post(
        Uri.parse('$_base/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameCtrl.text.trim().toLowerCase(),
          'password': _passwordCtrl.text,
        }),
      ).timeout(const Duration(seconds: 10));

      final decoded = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;

      if (resp.statusCode == 200 && decoded['success'] == true) {
        final data = decoded['data'] as Map<String, dynamic>;

        // Spremi tokene
        await AuthState.instance.saveFromResponse(data);

        // Postavi RegistrationState da HomeScreen ne redirecta na onboarding
        final user = data['user'] as Map<String, dynamic>? ?? {};
        RegistrationState.instance.isRegistered = true;
        RegistrationState.instance.username     = user['username'] ?? '';
        RegistrationState.instance.displayName  = user['displayName'] ?? '';

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, a, __) => const HomeScreen(),
            transitionsBuilder: (_, a, __, child) => FadeTransition(
              opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 500),
          ),
              (r) => false,
        );
      } else {
        setState(() => _error =
            decoded['message'] ?? 'Pogrešno korisničko ime ili lozinka.');
      }
    } on http.ClientException {
      setState(() => _error = 'Ne mogu se spojiti na server. Provjeri vezu.');
    } catch (e) {
      setState(() => _error = 'Greška: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(children: [
          // ── Pozadina ──────────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgAnim,
              builder: (_, __) => CustomPaint(painter: _GradBgPainter(_bgAnim.value)),
            ),
          ),

          // ── Kartica ───────────────────────────────────────────────
          Center(
            child: FadeTransition(
              opacity: _cardFade,
              child: SlideTransition(
                position: _cardSlide,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      28, mq.padding.top + 20, 28, mq.padding.bottom + 20),
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
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                          // Naslov
                          Text('Dobrodošao/la nazad!',
                              style: TextStyle(color: _bordo, fontSize: 22,
                                  fontWeight: FontWeight.w900, letterSpacing: -0.4)),
                          const SizedBox(height: 5),
                          Text('Prijavi se sa svojim računom.',
                              style: TextStyle(color: _bordo.withOpacity(0.50),
                                  fontSize: 13.5, fontWeight: FontWeight.w400)),
                          const SizedBox(height: 24),

                          // Username
                          _Lbl('Korisničko ime'),
                          const SizedBox(height: 6),
                          _FieldBox(
                            ctrl: _usernameCtrl, focus: _userFocus,
                            next: _passFocus, hint: 'npr. noa123',
                            icon: Icons.alternate_email_rounded,
                          ),
                          const SizedBox(height: 14),

                          // Lozinka
                          _Lbl('Lozinka'),
                          const SizedBox(height: 6),
                          _FieldBox(
                            ctrl: _passwordCtrl, focus: _passFocus,
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            obs: _obscure,
                            onTog: () => setState(() => _obscure = !_obscure),
                            action: TextInputAction.done,
                            onSub: (_) => _login(),
                          ),

                          // Error box
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            _ErrBox(msg: _error!),
                          ],

                          const SizedBox(height: 24),

                          // Gumb
                          ScaleTransition(
                            scale: _btnScale,
                            child: GestureDetector(
                              onTapDown: (_) { if (_valid && !_loading) _btnCtrl.forward(); },
                              onTapUp: (_) { _btnCtrl.reverse(); _login(); },
                              onTapCancel: () => _btnCtrl.reverse(),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 260),
                                height: 50, width: double.infinity,
                                decoration: BoxDecoration(
                                  color: (_valid && !_loading)
                                      ? _bordo
                                      : _bordo.withOpacity(0.30),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: (_valid && !_loading) ? [BoxShadow(
                                    color: _bordo.withOpacity(0.40),
                                    blurRadius: 18, offset: const Offset(0, 7),
                                    spreadRadius: -3,
                                  )] : [],
                                ),
                                child: Center(
                                  child: _loading
                                      ? const SizedBox(width: 22, height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5))
                                      : Text('Prijavi se',
                                      style: TextStyle(
                                        color: _valid ? Colors.white : Colors.white.withOpacity(0.45),
                                        fontSize: 15, fontWeight: FontWeight.w700,
                                      )),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Link nazad na registraciju
                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text.rich(TextSpan(
                                text: 'Nemaš račun? ',
                                style: TextStyle(color: _bordo.withOpacity(0.50), fontSize: 13.5),
                                children: [
                                  TextSpan(
                                    text: 'Registriraj se',
                                    style: TextStyle(
                                      color: _bordo, fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              )),
                            ),
                          ),
                        ]),
                      ),
                    ),

                    // MeetCute pill na vrhu kartice
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

// ── Shared field widgets (kopirani stil iz onboarding) ───────────────────────

class _Lbl extends StatelessWidget {
  final String text;
  const _Lbl(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(color: _bordo.withOpacity(0.60),
          fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.2));
}

class _FieldBox extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final FocusNode? next;
  final String hint;
  final IconData icon;
  final bool obs;
  final VoidCallback? onTog;
  final TextInputAction action;
  final void Function(String)? onSub;

  const _FieldBox({
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

// ── Gradient painter ─────────────────────────────────────────────────────────
class _GradBgPainter extends CustomPainter {
  final double t;
  _GradBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final wave = math.sin(t * math.pi * 2) * 0.5 + 0.5;
    final grad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF700D25),
        Color(0xFF4A0818),
        Color(0xFF0D0005),
      ],
      stops: [0.0, 0.40 + wave * 0.08, 1.0],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader =
      grad.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF9E1535).withOpacity(0.35 + wave * 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.22),
        width: size.width * 1.4,
        height: size.height * 0.50,
      ));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.22),
        width: size.width * 1.4,
        height: size.height * 0.50,
      ),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(_GradBgPainter o) => o.t != t;
}