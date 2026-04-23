import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'change_password_dialog.dart';
import 'company_auth_state.dart';
import 'onboarding_screen.dart';
import 'theme_state.dart';

const String _baseUrl = 'http://localhost:8080/api';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});
  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
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
      vsync: this,
      duration: const Duration(milliseconds: 320),
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

  bool  get _isDark    => ThemeState.instance.isDark;
  Color get _bg        => _isDark ? kDarkBg      : const Color(0xFFF8F0F1);
  Color get _card      => _isDark ? kDarkCard    : Colors.white;
  Color get _primary   => _isDark ? kDarkPrimary : const Color(0xFF700D25);
  Color get _accent    => _isDark ? kDarkCardEl  : const Color(0xFFF2E8E9);
  Color get _onPrimary => _isDark ? kDarkBg      : Colors.white;

  void _toggleDark() {
    HapticFeedback.selectionClick();
    ThemeState.instance.toggle();
    ThemeState.instance.isDark ? _toggleCtrl.forward() : _toggleCtrl.reverse();
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await http.post(
        Uri.parse('$_baseUrl/company/auth/logout'),
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
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
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
            color: _card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _primary.withOpacity(0.20)),
            boxShadow: [BoxShadow(
                color: _primary.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, 10))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.10),
                shape: BoxShape.circle,
                border: Border.all(color: _primary.withOpacity(0.25)),
              ),
              child: Icon(Icons.logout_rounded, color: _primary, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Odjava',
                style: TextStyle(
                    color: _primary, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text('Jeste li sigurni da se želite odjaviti?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _primary.withOpacity(0.60), fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(ctx, false),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(color: _primary.withOpacity(0.25)),
                  ),
                  child: Center(child: Text('Odustani',
                      style: TextStyle(
                          color: _primary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700))),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(ctx, true),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(23),
                    boxShadow: [BoxShadow(
                        color: _primary.withOpacity(0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 4))],
                  ),
                  child: Center(child: Text('Odjavi se',
                      style: TextStyle(
                          color: _onPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700))),
                ),
              )),
            ]),
          ]),
        ),
      ),
    );
    if (confirmed == true) await _logout();
  }

  void _openEditProfile() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProfileEditDialog(
        isDark: _isDark,
        primary: _primary,
        accent: _accent,
        card: _card,
        onPrimary: _onPrimary,
        onSaved: () => setState(() {}),
      ),
    );
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
          // Header
          AnimatedContainer(
            duration: const Duration(milliseconds: 380),
            color: _card,
            padding: EdgeInsets.only(
                top: mq.padding.top + 10, left: 6, right: 16, bottom: 16),
            child: Row(children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: _primary, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Postavke',
                        style: TextStyle(
                            color: _primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5)),
                    Text('Upravljanje računom',
                        style: TextStyle(
                            color: _primary.withOpacity(0.45),
                            fontSize: 13)),
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
                  color: _card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _primary.withOpacity(0.15)),
                  boxShadow: [BoxShadow(
                      color: _primary.withOpacity(_isDark ? 0.12 : 0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 4))],
                ),
                child: Row(children: [
                  // Logo avatar
                  Container(
                    width: 58, height: 58,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.10),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _primary.withOpacity(0.25), width: 1.5),
                    ),
                    child: company.logoUrl != null &&
                        company.logoUrl!.isNotEmpty
                        ? ClipOval(child: Image.network(
                        company.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                            Icons.business_rounded,
                            color: _primary,
                            size: 28)))
                        : Icon(Icons.business_rounded,
                        color: _primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(company.orgName ?? 'Organizacija',
                            style: TextStyle(
                                color: _primary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text('@${company.username ?? ''}',
                            style: TextStyle(
                                color: _primary.withOpacity(0.55),
                                fontSize: 13.5)),
                        if (company.email != null) ...[
                          const SizedBox(height: 2),
                          Text(company.email!,
                              style: TextStyle(
                                  color: _primary.withOpacity(0.40),
                                  fontSize: 12.5)),
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
              _settingsTile(
                icon: Icons.business_center_rounded,
                label: 'Podaci organizacije',
                subtitle: 'Logo, naziv, kontakt email',
                onTap: _openEditProfile,
              ),
              const SizedBox(height: 8),
              _settingsTile(
                icon: Icons.lock_rounded,
                label: 'Promjena lozinke',
                subtitle: 'Ažuriraj lozinku računa',
                onTap: () => ChangePasswordDialog.show(context, isCompany: true),
              ),
              const SizedBox(height: 24),

              // Odjava
              GestureDetector(
                onTap: _loggingOut ? null : _showLogoutDialog,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 380),
                  height: 54,
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: _primary.withOpacity(0.30), width: 1.2),
                    boxShadow: [BoxShadow(
                        color: _primary.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 3))],
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_loggingOut)
                          SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: _primary, strokeWidth: 2))
                        else ...[
                          Icon(Icons.logout_rounded,
                              color: _primary, size: 20),
                          const SizedBox(width: 10),
                          Text('Odjavi se',
                              style: TextStyle(
                                  color: _primary,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800)),
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
    child: Text(text.toUpperCase(),
        style: TextStyle(
            color: _primary.withOpacity(0.45),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2)),
  );

  Widget _darkModeRow() => GestureDetector(
    onTap: _toggleDark,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 340),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary.withOpacity(0.15)),
        boxShadow: [BoxShadow(
            color: _primary.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 5))],
      ),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 340),
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _primary.withOpacity(0.15))),
          child: Icon(
              _isDark
                  ? Icons.nights_stay_rounded
                  : Icons.wb_sunny_rounded,
              color: _primary,
              size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tamni mod',
                  style: TextStyle(
                      color: _primary,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(_isDark ? 'Upaljeno' : 'Ugašeno',
                  style: TextStyle(
                      color: _primary.withOpacity(0.45),
                      fontSize: 12.5)),
            ])),
        _DarkToggle(
            value: _isDark,
            primary: _primary,
            accent: _accent,
            onTap: _toggleDark),
      ]),
    ),
  );

  Widget _settingsTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 340),
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primary.withOpacity(0.12)),
            boxShadow: [BoxShadow(
                color: _primary.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 3))],
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 340),
              width: 42, height: 42,
              decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(12),
                  border:
                  Border.all(color: _primary.withOpacity(0.15))),
              child: Icon(icon, color: _primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: _primary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: TextStyle(
                          color: _primary.withOpacity(0.50),
                          fontSize: 12.5)),
                ])),
            Icon(Icons.arrow_forward_ios_rounded,
                color: _primary.withOpacity(0.30), size: 15),
          ]),
        ),
      );

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg,
            style: TextStyle(
                color: _onPrimary, fontWeight: FontWeight.w600)),
        backgroundColor: _primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
}

// ═══════════════════════════════════════════════════════════════════════════════
// POPUP — Uređivanje profila organizacije
// ═══════════════════════════════════════════════════════════════════════════════

class _ProfileEditDialog extends StatefulWidget {
  final bool isDark;
  final Color primary, accent, card, onPrimary;
  final VoidCallback onSaved;

  const _ProfileEditDialog({
    required this.isDark,
    required this.primary,
    required this.accent,
    required this.card,
    required this.onPrimary,
    required this.onSaved,
  });

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  late final TextEditingController _orgNameCtrl;
  late final TextEditingController _emailCtrl;

  String? _logoUrl;       // trenutni URL loga (s backenda)
  String? _newLogoPath;   // lokalna putanja novo odabrane slike
  bool _saving = false;
  String? _error;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final cs = CompanyAuthState.instance;
    _orgNameCtrl = TextEditingController(text: cs.orgName ?? '');
    _emailCtrl   = TextEditingController(text: cs.email   ?? '');
    _logoUrl     = cs.logoUrl;
  }

  @override
  void dispose() {
    _orgNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final xFile = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (xFile == null) return;
    setState(() {
      _newLogoPath = xFile.path;
      _error = null;
    });
  }

  void _removeLogo() => setState(() {
    _newLogoPath = null;
    _logoUrl = null;
  });

  Future<void> _save() async {
    final orgName = _orgNameCtrl.text.trim();
    final email   = _emailCtrl.text.trim();

    if (orgName.length < 2) {
      setState(() => _error = 'Naziv mora imati najmanje 2 znaka.');
      return;
    }
    if (!RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      setState(() => _error = 'Unesite ispravnu email adresu.');
      return;
    }

    setState(() { _saving = true; _error = null; });

    try {
      final token = CompanyAuthState.instance.accessToken!;

      // 1. Ako je odabrana nova slika → upload putem backend /upload endpointa
      String? finalLogoUrl = _logoUrl;
      if (_newLogoPath != null) {
        final file = File(_newLogoPath!);
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/upload?folder=meetcute/logos'),
        );
        request.headers['Authorization'] = 'Bearer $token';
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          await file.readAsBytes(),
          filename: _newLogoPath!.split('/').last,
          contentType: MediaType('image', 'jpeg'),
        ));
        final streamed = await request.send()
            .timeout(const Duration(seconds: 30));
        final uploadResp = await http.Response.fromStream(streamed);

        if (uploadResp.statusCode == 200) {
          final data = jsonDecode(
              utf8.decode(uploadResp.bodyBytes))['data']
          as Map<String, dynamic>;
          finalLogoUrl = data['url'] as String;
        } else {
          setState(() =>
          _error = 'Upload loga nije uspio. Pokušaj ponovo.');
          setState(() => _saving = false);
          return;
        }
      }

      // 2. Spremi sve na backend
      final bodyMap = <String, String>{
        'orgName': orgName,
        'email':   email,
      };
      if (finalLogoUrl != null && finalLogoUrl.isNotEmpty) {
        bodyMap['logoUrl'] = finalLogoUrl;
      }

      final resp = await http.put(
        Uri.parse('$_baseUrl/company/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(bodyMap),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      final decoded =
      jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;

      if (resp.statusCode == 200 && decoded['success'] == true) {
        // Ažuriraj lokalni CompanyAuthState trajno
        final companyData =
            decoded['data'] as Map<String, dynamic>? ?? {};
        await CompanyAuthState.instance.updateProfile(
          orgName: companyData['orgName'] as String? ?? orgName,
          email:   companyData['email']   as String? ?? email,
          logoUrl: companyData['logoUrl'] as String? ?? finalLogoUrl,
        );

        if (!mounted) return;
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Profil ažuriran!',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          backgroundColor: widget.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ));
      } else {
        setState(() => _error =
            decoded['message'] as String? ?? 'Greška pri spremanju.');
      }
    } catch (e) {
      setState(() => _error = 'Ne mogu se spojiti na server.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final p  = widget.primary;
    final a  = widget.accent;
    final c  = widget.card;

    // Koja slika loga se prikazuje
    Widget logoChild;
    if (_newLogoPath != null) {
      logoChild = Image.file(File(_newLogoPath!),
          fit: BoxFit.cover, width: 80, height: 80);
    } else if (_logoUrl != null && _logoUrl!.isNotEmpty) {
      logoChild = Image.network(_logoUrl!,
          fit: BoxFit.cover,
          width: 80,
          height: 80,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.business_rounded, color: p, size: 36));
    } else {
      logoChild = Icon(Icons.business_rounded, color: p, size: 36);
    }

    final hasLogo =
        _newLogoPath != null || (_logoUrl != null && _logoUrl!.isNotEmpty);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.88, end: 1.0),
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutBack,
        builder: (_, v, child) =>
            Transform.scale(scale: v, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: p.withOpacity(0.18)),
            boxShadow: [BoxShadow(
                color: p.withOpacity(0.22),
                blurRadius: 36,
                offset: const Offset(0, 14))],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
                22, 22, 22, mq.viewInsets.bottom + 22),
            child:
            Column(mainAxisSize: MainAxisSize.min, children: [
              // ── Naslov ────────────────────────────────────────────
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: p.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.business_center_rounded,
                      color: p, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text('Podaci organizacije',
                        style: TextStyle(
                            color: p,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3))),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                        color: p.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10)),
                    child:
                    Icon(Icons.close_rounded, color: p, size: 18),
                  ),
                ),
              ]),
              const SizedBox(height: 22),

              // ── Logo ───────────────────────────────────────────────
              Row(children: [
                Stack(clipBehavior: Clip.none, children: [
                  // Avatar — klik za promjenu
                  GestureDetector(
                    onTap: _pickLogo,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: p.withOpacity(0.10),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: p.withOpacity(0.25), width: 2),
                      ),
                      child: ClipOval(child: logoChild),
                    ),
                  ),
                  // Kamera ikona (tap za promjenu)
                  Positioned(
                    bottom: 0, right: 0,
                    child: GestureDetector(
                      onTap: _pickLogo,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: p,
                          shape: BoxShape.circle,
                          border: Border.all(color: c, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                  // X ikona — samo ako ima logo
                  if (hasLogo)
                    Positioned(
                      top: 0, right: 0,
                      child: GestureDetector(
                        onTap: _removeLogo,
                        child: Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: c, width: 2),
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 13),
                        ),
                      ),
                    ),
                ]),
                const SizedBox(width: 16),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Logo organizacije',
                          style: TextStyle(
                              color: p,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('Klikni na sliku za promjenu',
                          style: TextStyle(
                              color: p.withOpacity(0.50),
                              fontSize: 12)),
                    ])),
              ]),
              const SizedBox(height: 20),
              Divider(height: 1, color: p.withOpacity(0.10)),
              const SizedBox(height: 18),

              // ── Naziv ──────────────────────────────────────────────
              _fieldLabel('Naziv organizacije *', p),
              const SizedBox(height: 8),
              _inputField(
                ctrl: _orgNameCtrl,
                hint: 'npr. EventCo d.o.o.',
                icon: Icons.business_rounded,
                primary: p,
                card: c,
              ),
              const SizedBox(height: 14),

              // ── Email ──────────────────────────────────────────────
              _fieldLabel('Kontakt email *', p),
              const SizedBox(height: 8),
              _inputField(
                ctrl: _emailCtrl,
                hint: 'info@eventco.hr',
                icon: Icons.email_outlined,
                primary: p,
                card: c,
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.info_outline_rounded,
                    color: p.withOpacity(0.40), size: 13),
                const SizedBox(width: 5),
                Expanded(child: Text(
                    'Ovaj email bit će prikazan korisnicima na tvojim događajima.',
                    style: TextStyle(
                        color: p.withOpacity(0.45),
                        fontSize: 11.5))),
              ]),

              // ── Error ──────────────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.redAccent.withOpacity(0.30)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.redAccent, size: 14),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12.5))),
                  ]),
                ),
              ],
              const SizedBox(height: 22),

              // ── Gumb Spremi ────────────────────────────────────────
              GestureDetector(
                onTap: _saving ? null : _save,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  height: 50,
                  decoration: BoxDecoration(
                    color: _saving ? p.withOpacity(0.40) : p,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: _saving
                        ? []
                        : [BoxShadow(
                        color: p.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6))],
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.save_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('Spremi promjene',
                          style: TextStyle(
                              color: widget.onPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text, Color p) => Text(text,
      style: TextStyle(
          color: p, fontSize: 13.5, fontWeight: FontWeight.w700));

  Widget _inputField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    required Color primary,
    required Color card,
    TextInputType? keyboard,
  }) =>
      Container(
        height: 52,
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border:
          Border.all(color: primary.withOpacity(0.18), width: 1.2),
          boxShadow: [BoxShadow(
              color: primary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          const SizedBox(width: 14),
          Icon(icon, color: primary.withOpacity(0.45), size: 18),
          const SizedBox(width: 10),
          Expanded(child: TextField(
            controller: ctrl,
            keyboardType: keyboard,
            style: TextStyle(
                color: primary,
                fontSize: 14.5,
                fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: primary.withOpacity(0.30), fontSize: 14.5),
              border: InputBorder.none,
              isDense: true,
            ),
          )),
          const SizedBox(width: 12),
        ]),
      );
}

// ── Dark toggle ───────────────────────────────────────────────────────────────

class _DarkToggle extends StatelessWidget {
  final bool value;
  final Color primary, accent;
  final VoidCallback onTap;
  const _DarkToggle({
    required this.value,
    required this.primary,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        width: 52, height: 29,
        decoration: BoxDecoration(
          color: value ? primary : primary.withOpacity(0.18),
          borderRadius: BorderRadius.circular(15),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          alignment:
          value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 23, height: 23,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? accent : Colors.white,
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2))],
              ),
            ),
          ),
        ),
      ),
    );
  }
}