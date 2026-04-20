import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'company_auth_state.dart';
import 'company_home_screen.dart';

const Color _bordo      = Color(0xFF700D25);
const Color _bordoLight = Color(0xFFF2E8E9);
const String _base = 'http://localhost:8080/api';

class CompanyRegisterScreen extends StatefulWidget {
  const CompanyRegisterScreen({super.key});
  @override State<CompanyRegisterScreen> createState() => _CompanyRegisterScreenState();
}

class _CompanyRegisterScreenState extends State<CompanyRegisterScreen>
    with TickerProviderStateMixin {

  final _orgNameCtrl  = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _loading        = false;
  String? _error;

  // Logo upload
  String? _logoPath;        // lokalna putanja do slike
  String? _logoUrl;         // URL ako se pusti na CDN ili base64 za demo
  final ImagePicker _picker = ImagePicker();

  late final AnimationController _bgCtrl;
  late final AnimationController _cardCtrl;
  late final AnimationController _btnCtrl;
  late final Animation<double>   _bgAnim;
  late final Animation<double>   _cardFade;
  late final Animation<Offset>   _cardSlide;
  late final Animation<double>   _btnScale;

  bool get _hasMin8   => _passCtrl.text.length >= 8;
  bool get _hasUpper  => _passCtrl.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNum    => _passCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _passMatch => _passCtrl.text == _confirmCtrl.text && _confirmCtrl.text.isNotEmpty;
  bool get _valid =>
      _orgNameCtrl.text.trim().length >= 2 &&
          _usernameCtrl.text.trim().length >= 3 &&
          _emailCtrl.text.contains('@') &&
          _hasMin8 && _hasUpper && _hasNum && _passMatch;

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
    _cardCtrl.forward();
    for (final c in [_orgNameCtrl, _usernameCtrl, _emailCtrl, _passCtrl, _confirmCtrl]) {
      c.addListener(() { if (mounted) setState(() => _error = null); });
    }
  }

  @override
  void dispose() {
    _bgCtrl.dispose(); _cardCtrl.dispose(); _btnCtrl.dispose();
    _orgNameCtrl.dispose(); _usernameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    HapticFeedback.lightImpact();
    final xFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xFile == null) return;
    setState(() {
      _logoPath = xFile.path;
      // U produkciji ovdje bi se uploadalo na Cloudinary i dobio URL.
      // Za demo šaljemo null (logo_url ostaje prazan u bazi).
      // Ako imaš Cloudinary integration, dodaj ovdje.
      _logoUrl = null;
    });
  }

  void _removeLogo() {
    setState(() { _logoPath = null; _logoUrl = null; });
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_valid || _loading) return;
    HapticFeedback.mediumImpact();
    setState(() { _loading = true; _error = null; });

    final emailRegex = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(_emailCtrl.text.trim())) {
      setState(() => _error = 'Unesite ispravnu email adresu.');
      return;
    }

    try {
      final resp = await http.post(
        Uri.parse('$_base/company/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameCtrl.text.trim().toLowerCase(),
          'orgName':  _orgNameCtrl.text.trim(),
          'email':    _emailCtrl.text.trim().toLowerCase(),
          'password': _passCtrl.text,
          'logoUrl':  _logoUrl,  // null za demo, URL kad integriraš Cloudinary
        }),
      ).timeout(const Duration(seconds: 10));

      final decoded = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;

      if (resp.statusCode == 200 && decoded['success'] == true) {
        await CompanyAuthState.instance.saveFromResponse(decoded['data']);
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, a, __) => const CompanyHomeScreen(),
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
              (r) => false,
        );
      } else {
        setState(() => _error = decoded['message'] ?? 'Greška pri registraciji.');
      }
    } catch (e) {
      setState(() => _error = 'Ne mogu se spojiti na server.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(children: [
        Positioned.fill(child: AnimatedBuilder(
          animation: _bgAnim,
          builder: (_, __) => CustomPaint(painter: _GradBgPainter(_bgAnim.value)),
        )),

        // ── Back gumb ──────────────────────────────────────────────────────
        Positioned(
          top: mq.padding.top + 14,
          left: 16,
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
                padding: EdgeInsets.fromLTRB(24, mq.padding.top + 64, 24, mq.padding.bottom + 16),
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0E8EA),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.30),
                          blurRadius: 32, offset: const Offset(0, 12))],
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(22, 48, 22, mq.padding.bottom + 24),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Registracija organizacije',
                            style: TextStyle(color: _bordo, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
                        const SizedBox(height: 4),
                        Text('Organizirajte događanja i spajajte ljude.',
                            style: TextStyle(color: _bordo.withOpacity(0.50), fontSize: 13.5)),
                        const SizedBox(height: 20),

                        // ── Logo upload ──────────────────────────────────────
                        _lbl('Logo'),
                        const SizedBox(height: 10),
                        _buildLogoUploader(),
                        const SizedBox(height: 16),

                        _lbl('Naziv organizacije'),
                        const SizedBox(height: 6),
                        _field(ctrl: _orgNameCtrl, hint: 'npr. EventCo d.o.o.', icon: Icons.business_rounded),
                        const SizedBox(height: 14),

                        _lbl('Korisničko ime'),
                        const SizedBox(height: 6),
                        _field(ctrl: _usernameCtrl, hint: 'npr. eventco', icon: Icons.alternate_email_rounded),
                        const SizedBox(height: 14),

                        _lbl('Email adresa'),
                        const SizedBox(height: 6),
                        _field(ctrl: _emailCtrl, hint: 'info@eventco.hr',
                            icon: Icons.email_outlined, keyboard: TextInputType.emailAddress),
                        const SizedBox(height: 14),

                        _lbl('Lozinka'),
                        const SizedBox(height: 6),
                        _field(ctrl: _passCtrl, hint: '••••••••',
                            icon: Icons.lock_outline_rounded, obs: _obscurePass,
                            onTog: () => setState(() => _obscurePass = !_obscurePass)),
                        const SizedBox(height: 14),

                        _lbl('Ponovi lozinku'),
                        const SizedBox(height: 6),
                        _field(ctrl: _confirmCtrl, hint: '••••••••',
                            icon: Icons.lock_outline_rounded, obs: _obscureConfirm,
                            onTog: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            action: TextInputAction.done,
                            onSub: (_) => _register()),
                        const SizedBox(height: 14),

                        _passRules(),

                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          _errBox(_error!),
                        ],
                        const SizedBox(height: 22),

                        ScaleTransition(
                          scale: _btnScale,
                          child: GestureDetector(
                            onTapDown: (_) { if (_valid && !_loading) _btnCtrl.forward(); },
                            onTapUp: (_) { _btnCtrl.reverse(); _register(); },
                            onTapCancel: () => _btnCtrl.reverse(),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              height: 50, width: double.infinity,
                              decoration: BoxDecoration(
                                color: (_valid && !_loading) ? _bordo : _bordo.withOpacity(0.30),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: (_valid && !_loading) ? [BoxShadow(
                                    color: _bordo.withOpacity(0.40), blurRadius: 18,
                                    offset: const Offset(0, 7), spreadRadius: -3)] : [],
                              ),
                              child: Center(child: _loading
                                  ? const SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : Text('Registriraj organizaciju',
                                  style: TextStyle(
                                    color: _valid ? Colors.white : Colors.white.withOpacity(0.45),
                                    fontSize: 15, fontWeight: FontWeight.w700,
                                  ))),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Center(child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text('Već imaš račun? Prijava',
                              style: TextStyle(color: _bordo.withOpacity(0.60), fontSize: 13.5,
                                  decoration: TextDecoration.underline)),
                        )),
                      ]),
                    ),
                  ),

                  // Pill na vrhu
                  Positioned(top: -15, left: 0, right: 0,
                    child: Center(child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                      decoration: BoxDecoration(
                        color: _bordo, borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Image.asset('assets/images/logo.png', height: 22, fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Text('MeetCute',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900))),
                      ]),
                    )),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildLogoUploader() {
    return GestureDetector(
      onTap: _logoPath == null ? _pickLogo : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _logoPath != null ? _bordo.withOpacity(0.40) : _bordo.withOpacity(0.15),
            width: _logoPath != null ? 1.5 : 1.2,
          ),
          boxShadow: [BoxShadow(color: _bordo.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: _logoPath != null
            ? Row(children: [
          const SizedBox(width: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(File(_logoPath!), width: 62, height: 62, fit: BoxFit.cover),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Logo odabran ✓', style: TextStyle(color: _bordo, fontSize: 13.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text('Logo će biti prikazan na tvojim eventima', style: TextStyle(color: _bordo.withOpacity(0.50), fontSize: 12)),
          ])),
          GestureDetector(
            onTap: _removeLogo,
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              width: 32, height: 32,
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent.withOpacity(0.30))),
              child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 17),
            ),
          ),
        ])
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: _bordoLight, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.add_photo_alternate_rounded, color: _bordo, size: 24),
          ),
          const SizedBox(width: 14),
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dodaj logo', style: TextStyle(color: _bordo, fontSize: 14, fontWeight: FontWeight.w700)),
            Text('PNG, JPG (opcionalno)', style: TextStyle(color: _bordo.withOpacity(0.45), fontSize: 12)),
          ]),
        ]),
      ),
    );
  }

  Widget _lbl(String text) => Text(text,
      style: TextStyle(color: _bordo.withOpacity(0.60), fontSize: 11.5, fontWeight: FontWeight.w700));

  Widget _field({
    required TextEditingController ctrl, required String hint, required IconData icon,
    bool obs = false, VoidCallback? onTog, TextInputType? keyboard,
    TextInputAction action = TextInputAction.next, void Function(String)? onSub,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: _bordo.withOpacity(0.07), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Row(children: [
        const SizedBox(width: 13),
        Icon(icon, color: _bordo.withOpacity(0.32), size: 16),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: ctrl, obscureText: obs, keyboardType: keyboard,
          textInputAction: action, onSubmitted: onSub,
          style: TextStyle(color: _bordo.withOpacity(0.88), fontSize: 14.5),
          decoration: InputDecoration(
            hintText: hint, hintStyle: TextStyle(color: _bordo.withOpacity(0.26), fontSize: 14.5),
            border: InputBorder.none, isDense: true,
          ),
        )),
        if (onTog != null)
          GestureDetector(onTap: onTog, child: Padding(padding: const EdgeInsets.only(right: 12),
              child: Icon(obs ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: _bordo.withOpacity(0.28), size: 16))),
      ]),
    );
  }

  Widget _passRules() {
    bool h8  = _hasMin8;
    bool hU  = _hasUpper;
    bool hN  = _hasNum;
    bool hM  = _passMatch;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _bordo.withOpacity(0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('UVJETI ZA LOZINKU', style: TextStyle(color: _bordo.withOpacity(0.38),
            fontSize: 8.5, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(height: 9),
        _rule('Najmanje 8 znakova', h8),
        const SizedBox(height: 5),
        _rule('Jedno veliko slovo (A–Z)', hU),
        const SizedBox(height: 5),
        _rule('Jedan broj (0–9)', hN),
        const SizedBox(height: 5),
        _rule('Lozinke se podudaraju', hM),
      ]),
    );
  }

  Widget _rule(String t, bool ok) => Row(children: [
    AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 16, height: 16,
      decoration: BoxDecoration(
        color: ok ? _bordo : Colors.transparent, shape: BoxShape.circle,
        border: Border.all(color: ok ? _bordo : _bordo.withOpacity(0.20), width: 1.4),
      ),
      child: ok ? const Icon(Icons.check_rounded, color: Colors.white, size: 9) : null,
    ),
    const SizedBox(width: 8),
    Text(t, style: TextStyle(color: ok ? _bordo : _bordo.withOpacity(0.38),
        fontSize: 11.5, fontWeight: ok ? FontWeight.w600 : FontWeight.w400)),
  ]);

  Widget _errBox(String msg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.redAccent.withOpacity(0.22)),
    ),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 13),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5))),
    ]),
  );
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
  }
  @override bool shouldRepaint(_GradBgPainter o) => o.t != t;
}