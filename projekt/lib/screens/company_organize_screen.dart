import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'company_auth_state.dart';
import '../screens/events_nearby.dart' show AgeGroup, GenderGroup, AgeGroupLabel, GenderGroupLabel;

const Color _bordo      = Color(0xFF700D25);
const Color _bordoLight = Color(0xFFF2E8E9);
const String _base = 'http://localhost:8080/api';

const _cities = ['Zagreb', 'Split', 'Rijeka', 'Osijek', 'Zadar'];
const _categories = [
  ('Kava', '☕'), ('Sport', '🏃'), ('Druženja', '🎉'),
  ('Kultura', '🎭'), ('Priroda', '🌿'), ('Hrana', '🍕'),
  ('Glazba', '🎵'), ('Zabava', '🎪'), ('Edukacija', '📚'),
];
const _currencies = ['EUR', 'HRK', 'USD', 'GBP'];

class CompanyOrganizeScreen extends StatefulWidget {
  const CompanyOrganizeScreen({super.key});
  @override State<CompanyOrganizeScreen> createState() => _CompanyOrganizeScreenState();
}

class _CompanyOrganizeScreenState extends State<CompanyOrganizeScreen>
    with TickerProviderStateMixin {

  final _titleCtrl       = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _maxPeopleCtrl   = TextEditingController();
  final _timeCtrl        = TextEditingController();
  final _locationCtrl    = TextEditingController();
  final _ticketPriceCtrl = TextEditingController();

  String? _selectedCity;
  String? _selectedCategory;
  String? _selectedCurrency = 'EUR';
  DateTime? _pickedDate;
  String? _selectedDate;
  AgeGroup _selAge       = AgeGroup.all;
  GenderGroup _selGender = GenderGroup.all;
  bool _hasTickets = false;
  bool _submitting = false;

  late final AnimationController _entryCtrl;
  late final Animation<double>   _entryFade;
  late final AnimationController _btnCtrl;
  late final Animation<double>   _btnScale;

  bool get _valid =>
      _titleCtrl.text.trim().isNotEmpty &&
          _selectedCity != null &&
          _selectedCategory != null &&
          _pickedDate != null &&
          _timeCtrl.text.trim().isNotEmpty &&
          (!_hasTickets || (_ticketPriceCtrl.text.isNotEmpty &&
              double.tryParse(_ticketPriceCtrl.text.replaceAll(',', '.')) != null));

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _btnCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
    _btnScale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn));
    _entryCtrl.forward();
    for (final c in [_titleCtrl, _descCtrl, _maxPeopleCtrl, _timeCtrl, _locationCtrl, _ticketPriceCtrl]) {
      c.addListener(() { if (mounted) setState(() {}); });
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose(); _btnCtrl.dispose();
    _titleCtrl.dispose(); _descCtrl.dispose(); _maxPeopleCtrl.dispose();
    _timeCtrl.dispose(); _locationCtrl.dispose(); _ticketPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _bordo, onPrimary: Colors.white,
            surface: Colors.white, onSurface: _bordo,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _pickedDate = picked;
      final d = picked.day.toString().padLeft(2, '0');
      final m = picked.month.toString().padLeft(2, '0');
      _selectedDate = '$d.$m.${picked.year}.';
    });
  }

  (String?, String?) _parseTime(String text) {
    final t = text.trim();
    final range = RegExp(r'^(\d{2}:\d{2})\s*[–\-]\s*(\d{2}:\d{2})$');
    final m = range.firstMatch(t);
    if (m != null) return (m.group(1), m.group(2));
    if (t.length == 5) return (t, null);
    return (null, null);
  }

  Future<void> _submit() async {
    if (!_valid || _submitting) return;
    HapticFeedback.mediumImpact();
    await _btnCtrl.forward(); await _btnCtrl.reverse();
    setState(() => _submitting = true);

    final (timeStart, timeEnd) = _parseTime(_timeCtrl.text);
    final eventDate = '${_pickedDate!.year}-${_pickedDate!.month.toString().padLeft(2, '0')}-${_pickedDate!.day.toString().padLeft(2, '0')}';

    final body = {
      'title':           _titleCtrl.text.trim(),
      'description':     _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'city':            _selectedCity!,
      'specificLocation': _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      'eventDate':       eventDate,
      'timeStart':       timeStart,
      'timeEnd':         timeEnd,
      'category':        _selectedCategory!,
      'ageGroup':        _selAge.name,
      'genderGroup':     _selGender.name,
      'maxAttendees':    int.tryParse(_maxPeopleCtrl.text.trim()),
      'cardColorHex':    '#700D25',
      if (_hasTickets) 'ticketPrice': double.tryParse(_ticketPriceCtrl.text.replaceAll(',', '.')),
      if (_hasTickets) 'ticketCurrency': _selectedCurrency,
    };

    try {
      final resp = await http.post(
        Uri.parse('$_base/company/events'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${CompanyAuthState.instance.accessToken}',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      if (!mounted) return;

      if (resp.statusCode == 200 && decoded['success'] == true) {
        _showSuccess();
      } else {
        _showSnack(decoded['message'] ?? 'Greška pri kreiranju eventa.');
      }
    } catch (e) {
      if (mounted) _showSnack('Greška: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: _bordo.withOpacity(0.22), blurRadius: 40, offset: const Offset(0, 14))]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 68, height: 68,
                  decoration: BoxDecoration(color: _bordoLight, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: _bordo, size: 34)),
              const SizedBox(height: 18),
              const Text('Event kreiran! 🎉', style: TextStyle(color: _bordo,
                  fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.4)),
              const SizedBox(height: 10),
              Text('Vaš event je objavljen i vidljiv korisnicima MeetCute-a.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _bordo.withOpacity(0.55), fontSize: 14, height: 1.55)),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(true);
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(color: _bordo, borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: _bordo.withOpacity(0.30), blurRadius: 16, offset: const Offset(0, 6))]),
                  child: const Center(child: Text('Super!',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    margin: const EdgeInsets.all(16),
  ));

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _entryFade,
        child: Column(children: [
          // Header
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(top: mq.padding.top + 10, left: 6, right: 18, bottom: 18),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _bordo, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Organiziraj događaj', style: TextStyle(color: _bordo, fontSize: 22,
                    fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                Text('Kreirajte event za svoju zajednicu', style: TextStyle(
                    color: _bordo, fontSize: 13, fontWeight: FontWeight.w400)),
              ])),
            ]),
          ),

          Expanded(child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 4, 20, mq.padding.bottom + 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              _sectionLabel('Naziv događaja *'),
              const SizedBox(height: 8),
              _textField(_titleCtrl, 'npr. Startup konferencija 2026', Icons.edit_rounded),
              const SizedBox(height: 18),

              _sectionLabel('Grad *'),
              const SizedBox(height: 8),
              _cityDropdown(),
              const SizedBox(height: 18),

              _sectionLabel('Specifična lokacija'),
              const SizedBox(height: 8),
              _textField(_locationCtrl, 'npr. Dom sportova, Zagreb', Icons.place_rounded),
              const SizedBox(height: 18),

              _sectionLabel('Kategorija *'),
              const SizedBox(height: 10),
              _categoryChips(),
              const SizedBox(height: 18),

              _sectionLabel('Dobna skupina'),
              const SizedBox(height: 10),
              _ageChips(),
              const SizedBox(height: 18),

              _sectionLabel('Za koga je event?'),
              const SizedBox(height: 10),
              _genderChips(),
              const SizedBox(height: 18),

              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _sectionLabel('Datum *'),
                  const SizedBox(height: 8),
                  _datePicker(),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _sectionLabel('Vrijeme *'),
                  const SizedBox(height: 8),
                  _textField(_timeCtrl, '10:00 – 12:00', Icons.access_time_rounded,
                      keyboard: TextInputType.text),
                ])),
              ]),
              const SizedBox(height: 18),

              _sectionLabel('Maks. broj sudionika'),
              const SizedBox(height: 8),
              _textField(_maxPeopleCtrl, '100', Icons.people_rounded,
                  keyboard: TextInputType.number),
              const SizedBox(height: 24),

              // ── ULAZNICE ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _hasTickets ? _bordoLight : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _hasTickets ? _bordo.withOpacity(0.25) : Colors.grey.withOpacity(0.15)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: _hasTickets ? _bordo : Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.confirmation_number_rounded,
                          color: _hasTickets ? Colors.white : Colors.grey, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Naplaćivanje ulaznica',
                          style: TextStyle(color: _hasTickets ? _bordo : Colors.grey.shade700,
                              fontSize: 14.5, fontWeight: FontWeight.w700)),
                      Text('Postavi cijenu ulaznice za event',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ])),
                    Switch(
                      value: _hasTickets,
                      activeColor: _bordo,
                      onChanged: (v) => setState(() { _hasTickets = v; }),
                    ),
                  ]),

                  if (_hasTickets) ...[
                    const SizedBox(height: 16),
                    Divider(height: 1, color: _bordo.withOpacity(0.12)),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _sectionLabel('Cijena ulaznice *'),
                        const SizedBox(height: 8),
                        _textField(_ticketPriceCtrl, '15.00', Icons.euro_rounded,
                            keyboard: TextInputType.numberWithOptions(decimal: true)),
                      ])),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _sectionLabel('Valuta'),
                        const SizedBox(height: 8),
                        _currencyDropdown(),
                      ])),
                    ]),
                    const SizedBox(height: 12),
                    if (_ticketPriceCtrl.text.isNotEmpty && _maxPeopleCtrl.text.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _bordo.withOpacity(0.15)),
                        ),
                        child: Row(children: [
                          Icon(Icons.bar_chart_rounded, color: _bordo.withOpacity(0.60), size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            'Maksimalni prihod: ${(() {
                              final price = double.tryParse(_ticketPriceCtrl.text.replaceAll(',', '.')) ?? 0;
                              final max   = int.tryParse(_maxPeopleCtrl.text) ?? 0;
                              return '${(price * max).toStringAsFixed(2)} ${_selectedCurrency ?? 'EUR'}';
                            })()}',
                            style: TextStyle(color: _bordo, fontSize: 12.5, fontWeight: FontWeight.w600),
                          )),
                        ]),
                      ),
                    ],
                  ],
                ]),
              ),
              const SizedBox(height: 18),

              _sectionLabel('Opis'),
              const SizedBox(height: 8),
              _descField(),
              const SizedBox(height: 32),

              // Submit gumb
              ScaleTransition(
                scale: _btnScale,
                child: GestureDetector(
                  onTapDown: (_) { if (_valid && !_submitting) _btnCtrl.forward(); },
                  onTapUp: (_) { _btnCtrl.reverse(); _submit(); },
                  onTapCancel: () => _btnCtrl.reverse(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260), height: 54,
                    decoration: BoxDecoration(
                      color: (_valid && !_submitting) ? _bordo : _bordo.withOpacity(0.28),
                      borderRadius: BorderRadius.circular(27),
                      boxShadow: (_valid && !_submitting) ? [BoxShadow(
                          color: _bordo.withOpacity(0.32), blurRadius: 18, offset: const Offset(0, 7))] : [],
                    ),
                    child: Center(child: _submitting
                        ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.celebration_rounded,
                          color: _valid ? Colors.white : Colors.white.withOpacity(0.45), size: 20),
                      const SizedBox(width: 10),
                      Text('Objavi događaj', style: TextStyle(
                        color: _valid ? Colors.white : Colors.white.withOpacity(0.45),
                        fontSize: 16, fontWeight: FontWeight.w800,
                      )),
                    ])),
                  ),
                ),
              ),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(color: _bordo, fontSize: 13.5, fontWeight: FontWeight.w700));

  Widget _textField(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? keyboard}) {
    return Container(
      height: 52,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _bordo.withOpacity(0.15), width: 1.2),
          boxShadow: [BoxShadow(color: _bordo.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Row(children: [
        const SizedBox(width: 14),
        Icon(icon, color: _bordo.withOpacity(0.45), size: 18),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: ctrl, keyboardType: keyboard, onChanged: (_) => setState(() {}),
          style: const TextStyle(color: _bordo, fontSize: 14.5, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint, hintStyle: TextStyle(color: _bordo.withOpacity(0.30), fontSize: 14.5),
            border: InputBorder.none, isDense: true,
          ),
        )),
        const SizedBox(width: 12),
      ]),
    );
  }

  Widget _cityDropdown() {
    return Container(
      height: 52,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _bordo.withOpacity(0.15), width: 1.2),
          boxShadow: [BoxShadow(color: _bordo.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: _selectedCity,
        hint: Row(children: [
          Icon(Icons.location_on_rounded, color: _bordo.withOpacity(0.45), size: 18),
          const SizedBox(width: 10),
          Text('Odaberi grad', style: TextStyle(color: _bordo.withOpacity(0.30), fontSize: 14.5)),
        ]),
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: _bordo.withOpacity(0.45)),
        style: const TextStyle(color: _bordo, fontSize: 14.5, fontWeight: FontWeight.w500, fontFamily: 'SF Pro Display'),
        dropdownColor: Colors.white, borderRadius: BorderRadius.circular(14),
        onChanged: (v) => setState(() => _selectedCity = v),
        items: _cities.map((c) => DropdownMenuItem(value: c,
            child: Row(children: [
              Icon(Icons.location_on_rounded, color: _bordo.withOpacity(0.55), size: 16),
              const SizedBox(width: 8), Text(c),
            ]))).toList(),
      )),
    );
  }

  Widget _currencyDropdown() {
    return Container(
      height: 52,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _bordo.withOpacity(0.15), width: 1.2)),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: _selectedCurrency,
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: _bordo.withOpacity(0.45)),
        style: const TextStyle(color: _bordo, fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'SF Pro Display'),
        dropdownColor: Colors.white, borderRadius: BorderRadius.circular(14),
        onChanged: (v) => setState(() => _selectedCurrency = v),
        items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      )),
    );
  }

  Widget _datePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220), height: 52,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _selectedDate != null ? _bordo.withOpacity(0.40) : _bordo.withOpacity(0.15), width: 1.2),
            boxShadow: [BoxShadow(color: _bordo.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
        child: Row(children: [
          const SizedBox(width: 14),
          Icon(Icons.calendar_today_rounded,
              color: _selectedDate != null ? _bordo : _bordo.withOpacity(0.45), size: 18),
          const SizedBox(width: 10),
          Text(_selectedDate ?? 'Odaberi datum', style: TextStyle(
            color: _selectedDate != null ? _bordo : _bordo.withOpacity(0.30),
            fontSize: 14.5, fontWeight: FontWeight.w500,
          )),
        ]),
      ),
    );
  }

  Widget _categoryChips() {
    return Wrap(spacing: 8, runSpacing: 8, children: _categories.map((cat) {
      final selected = _selectedCategory == cat.$1;
      return GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedCategory = selected ? null : cat.$1); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? _bordo : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? _bordo : _bordo.withOpacity(0.18), width: 1.2),
            boxShadow: selected ? [BoxShadow(color: _bordo.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))] : [],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(cat.$2, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(cat.$1, style: TextStyle(
                color: selected ? Colors.white : _bordo,
                fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
    }).toList());
  }

  Widget _ageChips() {
    return Wrap(spacing: 8, runSpacing: 8, children: AgeGroup.values.map((g) {
      final sel = _selAge == g;
      return GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _selAge = g); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: sel ? _bordo : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? _bordo : _bordo.withOpacity(0.18), width: 1.2),
          ),
          child: Text(g.label, style: TextStyle(
              color: sel ? Colors.white : _bordo, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      );
    }).toList());
  }

  Widget _genderChips() {
    return Wrap(spacing: 8, runSpacing: 8, children: GenderGroup.values.map((g) {
      final sel = _selGender == g;
      return GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _selGender = g); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: sel ? _bordo : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? _bordo : _bordo.withOpacity(0.18), width: 1.2),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(g.emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(g.label, style: TextStyle(
                color: sel ? Colors.white : _bordo, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
    }).toList());
  }

  Widget _descField() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _bordo.withOpacity(0.15), width: 1.2),
          boxShadow: [BoxShadow(color: _bordo.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
      child: TextField(
        controller: _descCtrl, maxLines: 4, onChanged: (_) => setState(() {}),
        style: const TextStyle(color: _bordo, fontSize: 14.5, fontWeight: FontWeight.w400, height: 1.5),
        decoration: InputDecoration(
          hintText: 'Opišite vaš događaj, program, što posjetitelji mogu očekivati...',
          hintStyle: TextStyle(color: _bordo.withOpacity(0.30), fontSize: 14.5),
          border: InputBorder.none, contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }
}