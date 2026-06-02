import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_state.dart';
import 'company_auth_state.dart';
import 'theme_state.dart';

const String _baseUrl = 'http://localhost:8080/api';

class ChangePasswordDialog {
  static void show(BuildContext context, {required bool isCompany}) {
    final isDark = ThemeState.instance.isDark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ChangePasswordDialogWidget(
        isCompany: isCompany,
        primary:   isDark ? kDarkPrimary : const Color(0xFF700D25),
        card:      isDark ? kDarkCard    : Colors.white,
        onPrimary: isDark ? kDarkBg      : Colors.white,
      ),
    );
  }
}

class _ChangePasswordDialogWidget extends StatefulWidget {
  final bool isCompany;
  final Color primary, card, onPrimary;

  const _ChangePasswordDialogWidget({
    required this.isCompany,
    required this.primary,
    required this.card,
    required this.onPrimary,
  });

  @override
  State<_ChangePasswordDialogWidget> createState() => _ChangePasswordDialogWidgetState();
}

class _ChangePasswordDialogWidgetState extends State<_ChangePasswordDialogWidget> {
  final _oldCtrl     = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureOld     = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _saving         = false;
  String? _error;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _hasMin8  => _newCtrl.text.length >= 8;
  bool get _hasUpper => _newCtrl.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNum   => _newCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _matches  => _newCtrl.text == _confirmCtrl.text && _confirmCtrl.text.isNotEmpty;

  Future<void> _save() async {
    final oldPass = _oldCtrl.text.trim();
    final newPass = _newCtrl.text;

    if (oldPass.isEmpty) { setState(() => _error = 'Unesite staru lozinku.'); return; }
    if (!_hasMin8 || !_hasUpper || !_hasNum) { setState(() => _error = 'Nova lozinka ne zadovoljava uvjete.'); return; }
    if (!_matches) { setState(() => _error = 'Lozinke se ne podudaraju.'); return; }

    setState(() { _saving = true; _error = null; });

    try {
      final token    = widget.isCompany ? CompanyAuthState.instance.accessToken! : AuthState.instance.accessToken!;
      final endpoint = widget.isCompany ? '$_baseUrl/company/auth/password' : '$_baseUrl/users/me/password';

      final resp = await http.put(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'oldPassword': oldPass, 'newPassword': newPass}),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      final decoded = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;

      if (resp.statusCode == 200 && decoded['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Lozinka uspješno promijenjena!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          backgroundColor: widget.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ));
      } else {
        setState(() => _error = decoded['message'] as String? ?? 'Greška pri promjeni lozinke.');
      }
    } catch (_) {
      setState(() => _error = 'Ne mogu se spojiti na server.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.primary;
    final c = widget.card;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.88, end: 1.0),
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutBack,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: p.withOpacity(0.18)),
            boxShadow: [BoxShadow(color: p.withOpacity(0.22), blurRadius: 36, offset: const Offset(0, 14))],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(22, 22, 22, MediaQuery.of(context).viewInsets.bottom + 22),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: p.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.lock_rounded, color: p, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text('Promjena lozinke', style: TextStyle(
                    color: p, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.3))),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: p.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.close_rounded, color: p, size: 18),
                  ),
                ),
              ]),
              const SizedBox(height: 22),
              _fieldLabel('Stara lozinka *', p),
              const SizedBox(height: 8),
              _passField(ctrl: _oldCtrl, obscure: _obscureOld, onToggle: () => setState(() => _obscureOld = !_obscureOld), p: p, c: c),
              const SizedBox(height: 14),
              _fieldLabel('Nova lozinka *', p),
              const SizedBox(height: 8),
              _passField(ctrl: _newCtrl, obscure: _obscureNew, onToggle: () => setState(() => _obscureNew = !_obscureNew), p: p, c: c, onChanged: (_) => setState(() {})),
              const SizedBox(height: 14),
              _fieldLabel('Ponovi novu lozinku *', p),
              const SizedBox(height: 8),
              _passField(ctrl: _confirmCtrl, obscure: _obscureConfirm, onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm), p: p, c: c, onChanged: (_) => setState(() {})),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.withOpacity(0.10)),
                ),
                child: Column(children: [
                  _rule('Najmanje 8 znakova', _hasMin8, p),
                  const SizedBox(height: 5),
                  _rule('Jedno veliko slovo (A–Z)', _hasUpper, p),
                  const SizedBox(height: 5),
                  _rule('Jedan broj (0–9)', _hasNum, p),
                  const SizedBox(height: 5),
                  _rule('Lozinke se podudaraju', _matches, p),
                ]),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.30)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 14),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5))),
                  ]),
                ),
              ],
              const SizedBox(height: 22),
              GestureDetector(
                onTap: _saving ? null : _save,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  height: 50,
                  decoration: BoxDecoration(
                    color: _saving ? p.withOpacity(0.40) : p,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: _saving ? [] : [BoxShadow(color: p.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('Promijeni lozinku', style: TextStyle(
                          color: widget.onPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
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
      style: TextStyle(color: p, fontSize: 13.5, fontWeight: FontWeight.w700));

  Widget _passField({
    required TextEditingController ctrl,
    required bool obscure,
    required VoidCallback onToggle,
    required Color p,
    required Color c,
    void Function(String)? onChanged,
  }) =>
      Container(
        height: 52,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.withOpacity(0.18), width: 1.2),
          boxShadow: [BoxShadow(color: p.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          const SizedBox(width: 14),
          Icon(Icons.lock_outline_rounded, color: p.withOpacity(0.45), size: 18),
          const SizedBox(width: 10),
          Expanded(child: TextField(
            controller: ctrl,
            obscureText: obscure,
            onChanged: onChanged,
            style: TextStyle(color: p, fontSize: 14.5, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: TextStyle(color: p.withOpacity(0.30), fontSize: 14.5),
              border: InputBorder.none,
              isDense: true,
            ),
          )),
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: p.withOpacity(0.40), size: 18),
            ),
          ),
        ]),
      );

  Widget _rule(String text, bool ok, Color p) => Row(children: [
    AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 16, height: 16,
      decoration: BoxDecoration(
        color: ok ? p : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: ok ? p : p.withOpacity(0.25), width: 1.4),
      ),
      child: ok ? const Icon(Icons.check_rounded, color: Colors.white, size: 9) : null,
    ),
    const SizedBox(width: 8),
    Text(text, style: TextStyle(
        color: ok ? p : p.withOpacity(0.45),
        fontSize: 11.5,
        fontWeight: ok ? FontWeight.w600 : FontWeight.w400)),
  ]);
}