import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'company_auth_state.dart';
import 'company_event_model.dart';
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

const _autoColors = [
  '#6DD5E8', '#FFD166', '#95D5B2', '#FFB3C6',
  '#B5D8FF', '#FFCCAA', '#C8B5FF', '#AAF0D1',
];

class _LatLng { final double lat, lng; const _LatLng(this.lat, this.lng); }

class CompanyOrganizeScreen extends StatefulWidget {
  // Ako je editEvent != null → edit mode, inače → create mode
  final CompanyEvent? editEvent;
  const CompanyOrganizeScreen({super.key, this.editEvent});
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

  String?     _selectedCity;
  String?     _selectedCategory;
  String?     _selectedCurrency = 'EUR';
  DateTime?   _pickedDate;
  String?     _selectedDate;
  AgeGroup    _selAge    = AgeGroup.all;
  GenderGroup _selGender = GenderGroup.all;
  bool        _hasTickets  = false;
  bool        _submitting  = false;
  bool        _isGeocoding = false;

  String? _coverImagePath;
  final ImagePicker _picker = ImagePicker();

  bool  _addrChecking = false;
  bool? _addrValid;
  String? _addrError;
  Timer? _addrDebounce;
  String? _timeError;

  late final AnimationController _entryCtrl;
  late final Animation<double>   _entryFade;
  late final AnimationController _btnCtrl;
  late final Animation<double>   _btnScale;

  bool get _isEditMode => widget.editEvent != null;

  String _randomCardColor() {
    final r = math.Random();
    return _autoColors[r.nextInt(_autoColors.length)];
  }

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _btnCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
    _btnScale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn));
    _entryCtrl.forward();
    _locationCtrl.addListener(_onAddrChanged);
    _timeCtrl.addListener(_onTimeChanged);
    for (final c in [_titleCtrl, _descCtrl, _maxPeopleCtrl, _ticketPriceCtrl]) {
      c.addListener(() { if (mounted) setState(() {}); });
    }

    // Ako je edit mode — popuni polja postojećim podacima
    if (_isEditMode) _populateFromEvent(widget.editEvent!);
  }

  void _populateFromEvent(CompanyEvent ev) {
    _titleCtrl.text = ev.title;
    _descCtrl.text  = ev.description ?? '';
    _locationCtrl.text = ev.specificLocation ?? '';
    _maxPeopleCtrl.text = ev.maxAttendees?.toString() ?? '';

    // Grad
    if (_cities.contains(ev.city)) _selectedCity = ev.city;

    // Kategorija
    final catNames = _categories.map((c) => c.$1).toList();
    if (catNames.contains(ev.category)) _selectedCategory = ev.category;

    // Dobna skupina
    try {
      _selAge = AgeGroup.values.firstWhere((g) => g.name == ev.ageGroup,
          orElse: () => AgeGroup.all);
    } catch (_) {}

    // Spol
    try {
      _selGender = GenderGroup.values.firstWhere((g) => g.name == ev.genderGroup,
          orElse: () => GenderGroup.all);
    } catch (_) {}

    // Datum
    if (ev.eventDate != null) {
      try {
        final parts = ev.eventDate!.split('-');
        _pickedDate = DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        _selectedDate = '${parts[2]}.${parts[1]}.${parts[0]}.';
      } catch (_) {}
    }

    // Vrijeme
    if (ev.timeStart != null) {
      final start = ev.timeStart!.length >= 5 ? ev.timeStart!.substring(0, 5) : ev.timeStart!;
      if (ev.timeEnd != null) {
        final end = ev.timeEnd!.length >= 5 ? ev.timeEnd!.substring(0, 5) : ev.timeEnd!;
        _timeCtrl.text = '$start – $end';
      } else {
        _timeCtrl.text = start;
      }
    }

    // Ulaznice
    if (ev.ticketPrice != null) {
      _hasTickets = true;
      _ticketPriceCtrl.text = ev.ticketPrice!.toStringAsFixed(2);
      _selectedCurrency = ev.ticketCurrency ?? 'EUR';
    }
  }

  @override
  void dispose() {
    _addrDebounce?.cancel();
    _entryCtrl.dispose(); _btnCtrl.dispose();
    _titleCtrl.dispose(); _descCtrl.dispose(); _maxPeopleCtrl.dispose();
    _timeCtrl.dispose(); _locationCtrl.dispose(); _ticketPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCoverPhoto() async {
    HapticFeedback.lightImpact();
    final xFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xFile == null) return;
    setState(() => _coverImagePath = xFile.path);
  }

  void _removeCoverPhoto() => setState(() => _coverImagePath = null);

  void _onAddrChanged() {
    if (!mounted) return;
    final text = _locationCtrl.text.trim();
    _addrDebounce?.cancel();
    if (text.isEmpty) {
      setState(() { _addrValid = null; _addrError = null; _addrChecking = false; });
      return;
    }
    setState(() { _addrChecking = true; _addrValid = null; _addrError = null; });
    _addrDebounce = Timer(const Duration(milliseconds: 800), () async {
      if (!mounted) return;
      final current = _locationCtrl.text.trim();
      if (current != text) return;
      final city = _selectedCity ?? '';
      final result = await _geocode('$text${city.isNotEmpty ? ', $city' : ''}, Croatia');
      if (!mounted || _locationCtrl.text.trim() != text) return;
      setState(() {
        _addrChecking = false;
        _addrValid    = result != null;
        _addrError    = result == null ? 'Adresa nije pronađena. Provjeri pravopis.' : null;
      });
    });
  }

  void _onTimeChanged() {
    if (!mounted) return;
    final text = _timeCtrl.text.trim();
    if (text.isEmpty) { setState(() => _timeError = null); return; }
    final single = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$');
    final range  = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)\s*[–\-]\s*([01]?\d|2[0-3]):([0-5]\d)$');
    setState(() => _timeError = (single.hasMatch(text) || range.hasMatch(text))
        ? null : 'Format: 10:00 ili 10:00 – 12:00');
  }

  Future<_LatLng?> _geocode(String address) async {
    try {
      final q   = Uri.encodeComponent(address);
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=1');
      final res = await http.get(url, headers: {'User-Agent': 'MeetCuteApp/1.0'})
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat'].toString());
          final lon = double.tryParse(data[0]['lon'].toString());
          if (lat != null && lon != null) return _LatLng(lat, lon);
        }
      }
    } catch (_) {}
    return null;
  }

  (String?, String?) _parseTime(String text) {
    final t = text.trim();
    final range = RegExp(r'^(\d{2}:\d{2})\s*[–\-]\s*(\d{2}:\d{2})$');
    final m = range.firstMatch(t);
    if (m != null) return (m.group(1), m.group(2));
    if (t.length == 5) return (t, null);
    return (null, null);
  }

  bool get _isValid =>
      _titleCtrl.text.trim().isNotEmpty &&
          _selectedCity != null &&
          _selectedCategory != null &&
          _pickedDate != null &&
          _timeCtrl.text.trim().isNotEmpty &&
          _timeError == null &&
          !_addrChecking &&
          (_locationCtrl.text.trim().isEmpty || _addrValid == true) &&
          (!_hasTickets || (_ticketPriceCtrl.text.isNotEmpty &&
              double.tryParse(_ticketPriceCtrl.text.replaceAll(',', '.')) != null));

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
      _pickedDate   = picked;
      final d  = picked.day.toString().padLeft(2, '0');
      final mo = picked.month.toString().padLeft(2, '0');
      _selectedDate = '$d.$mo.${picked.year}.';
    });
  }

  // ── SUBMIT: create ili update ovisno o modu ───────────────────────────────
  Future<void> _submit() async {
    if (!_isValid || _submitting) { _showValidationSnack(); return; }
    HapticFeedback.mediumImpact();
    await _btnCtrl.forward(); await _btnCtrl.reverse();
    setState(() { _submitting = true; _isGeocoding = true; });

    _LatLng? coords;
    final loc = _locationCtrl.text.trim();
    if (loc.isNotEmpty) coords = await _geocode('$loc, $_selectedCity, Croatia');
    if (!mounted) return;
    setState(() => _isGeocoding = false);

    final (timeStart, timeEnd) = _parseTime(_timeCtrl.text);
    final eventDate = '${_pickedDate!.year}-'
        '${_pickedDate!.month.toString().padLeft(2, '0')}-'
        '${_pickedDate!.day.toString().padLeft(2, '0')}';

    final body = <String, dynamic>{
      'title':            _titleCtrl.text.trim(),
      'description':      _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'city':             _selectedCity!,
      'specificLocation': loc.isEmpty ? null : loc,
      'eventDate':        eventDate,
      'timeStart':        timeStart,
      'timeEnd':          timeEnd,
      'category':         _selectedCategory!,
      'ageGroup':         _selAge.name,
      'genderGroup':      _selGender.name,
      'maxAttendees':     int.tryParse(_maxPeopleCtrl.text.trim()),
      'latitude':         coords?.lat,
      'longitude':        coords?.lng,
    };

    // Create mode dobiva random boju; edit mode zadržava postojeću
    if (!_isEditMode) body['cardColorHex'] = _randomCardColor();

    if (_hasTickets) {
      body['ticketPrice']    = double.tryParse(_ticketPriceCtrl.text.replaceAll(',', '.'));
      body['ticketCurrency'] = _selectedCurrency;
    }

    try {
      final http.Response resp;

      if (_isEditMode) {
        // PUT /api/company/events/{id}
        resp = await http.put(
          Uri.parse('$_base/company/events/${widget.editEvent!.id}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${CompanyAuthState.instance.accessToken}',
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 15));
      } else {
        // POST /api/company/events
        resp = await http.post(
          Uri.parse('$_base/company/events'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${CompanyAuthState.instance.accessToken}',
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 15));
      }

      final decoded = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      if (!mounted) return;

      if (resp.statusCode == 200 && decoded['success'] == true) {
        _showSuccess();
      } else {
        _showSnack(decoded['message'] ?? 'Greška pri spremanju događaja.');
      }
    } catch (e) {
      if (mounted) _showSnack('Greška: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSuccess() => showDialog(
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
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(
                color: _bordo.withOpacity(0.22), blurRadius: 40, offset: const Offset(0, 14))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 68, height: 68,
                decoration: BoxDecoration(color: _bordoLight, shape: BoxShape.circle),
                child: Icon(
                  _isEditMode ? Icons.check_circle_outline_rounded : Icons.check_rounded,
                  color: _bordo, size: 34,
                )),
            const SizedBox(height: 18),
            Text(
              _isEditMode ? 'Događaj ažuriran!' : 'Događaj kreiran! 🎉',
              style: const TextStyle(color: _bordo,
                  fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.4),
            ),
            const SizedBox(height: 10),
            Text(
              _isEditMode
                  ? 'Svi prijavljeni korisnici su obaviješteni o izmjenama.'
                  : 'Vaš događaj je objavljen i vidljiv korisnicima MeetCute-a.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _bordo.withOpacity(0.55), fontSize: 14, height: 1.55),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();  // zatvori dialog
                Navigator.of(context).pop(true); // vrati true → refresh liste
              },
              child: Container(height: 50,
                  decoration: BoxDecoration(color: _bordo, borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: _bordo.withOpacity(0.30),
                          blurRadius: 16, offset: const Offset(0, 6))]),
                  child: const Center(child: Text('U redu', style: TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)))),
            ),
          ]),
        ),
      ),
    ),
  );

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showValidationSnack() {
    String msg = 'Popuni sva obavezna polja';
    if (_addrChecking)           msg = 'Pričekaj provjeru adrese...';
    else if (_addrValid == false) msg = 'Adresa nije ispravna — ispravi je';
    else if (_timeError != null)  msg = 'Format vremena: 10:00 ili 10:00 – 12:00';
    _showSnack(msg);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _entryFade,
        child: Column(children: [
          // ── Header ────────────────────────────────────────────────────────
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
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  _isEditMode ? 'Uredi događaj' : 'Organiziraj događaj',
                  style: const TextStyle(color: _bordo, fontSize: 22,
                      fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                Text(
                  _isEditMode
                      ? 'Izmijeni detalje — sudionici će biti obaviješteni'
                      : 'Kreirajte događaj za svoju zajednicu',
                  style: const TextStyle(color: _bordo, fontSize: 13, fontWeight: FontWeight.w400),
                ),
              ])),
              // Edit mode badge
              if (_isEditMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _bordoLight, borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _bordo.withOpacity(0.25)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.edit_rounded, color: _bordo, size: 13),
                    SizedBox(width: 5),
                    Text('Uređivanje', style: TextStyle(
                        color: _bordo, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
            ]),
          ),

          Expanded(child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 4, 20, mq.padding.bottom + 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              _label('Naslovna slika (opcionalno)'),
              const SizedBox(height: 8),
              _buildCoverPhoto(),
              const SizedBox(height: 18),

              _label('Naziv događaja *'),
              const SizedBox(height: 8),
              _field(_titleCtrl, 'npr. Sportsko okupljanje', Icons.edit_rounded),
              const SizedBox(height: 18),

              _label('Grad *'),
              const SizedBox(height: 8),
              _cityDrop(),
              const SizedBox(height: 18),

              _label('Specifična lokacija'),
              const SizedBox(height: 8),
              _field(_locationCtrl, 'npr. Dom sportova, Zagreb', Icons.place_rounded),
              if (_locationCtrl.text.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                _addrStatusWidget(),
              ],
              const SizedBox(height: 18),

              _label('Kategorija *'),
              const SizedBox(height: 10),
              _catChips(),
              const SizedBox(height: 18),

              _label('Dobna skupina'),
              const SizedBox(height: 10),
              _ageChips(),
              const SizedBox(height: 18),

              _label('Za koga je događaj?'),
              const SizedBox(height: 10),
              _genderChips(),
              const SizedBox(height: 18),

              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Datum *'),
                  const SizedBox(height: 8),
                  _datePicker(),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Vrijeme *'),
                  const SizedBox(height: 8),
                  _field(_timeCtrl, '10:00 – 12:00', Icons.access_time_rounded,
                      keyboard: TextInputType.text),
                  if (_timeError != null) ...[
                    const SizedBox(height: 5),
                    Row(children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 13),
                      const SizedBox(width: 4),
                      Expanded(child: Text(_timeError!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 11.5))),
                    ]),
                  ],
                ])),
              ]),
              const SizedBox(height: 18),

              _label('Maks. broj sudionika'),
              const SizedBox(height: 8),
              _field(_maxPeopleCtrl, '100', Icons.people_rounded, keyboard: TextInputType.number),
              const SizedBox(height: 24),

              _ticketBox(),
              const SizedBox(height: 18),

              _label('Opis'),
              const SizedBox(height: 8),
              _descField(),
              const SizedBox(height: 32),

              // ── Submit gumb ──────────────────────────────────────────────
              ScaleTransition(
                scale: _btnScale,
                child: GestureDetector(
                  onTapDown: (_) { if (_isValid && !_submitting) _btnCtrl.forward(); },
                  onTapUp: (_) { _btnCtrl.reverse(); _submit(); },
                  onTapCancel: () => _btnCtrl.reverse(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260), height: 54,
                    decoration: BoxDecoration(
                      color: (_isValid && !_submitting) ? _bordo : _bordo.withOpacity(0.28),
                      borderRadius: BorderRadius.circular(27),
                      boxShadow: (_isValid && !_submitting) ? [BoxShadow(
                          color: _bordo.withOpacity(0.32), blurRadius: 18,
                          offset: const Offset(0, 7))] : [],
                    ),
                    child: Center(child: (_submitting || _isGeocoding)
                        ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        _isEditMode ? Icons.save_rounded : Icons.celebration_rounded,
                        color: _isValid ? Colors.white : Colors.white.withOpacity(0.45),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isEditMode ? 'Spremi izmjene' : 'Objavi događaj',
                        style: TextStyle(
                          color: _isValid ? Colors.white : Colors.white.withOpacity(0.45),
                          fontSize: 16, fontWeight: FontWeight.w800,
                        ),
                      ),
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

  // ── Helpers (isti kao original) ───────────────────────────────────────────

  Widget _buildCoverPhoto() {
    return GestureDetector(
      onTap: _coverImagePath == null ? _pickCoverPhoto : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        height: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _coverImagePath != null ? _bordo.withOpacity(0.40) : _bordo.withOpacity(0.15),
            width: _coverImagePath != null ? 1.5 : 1.2,
          ),
          boxShadow: [BoxShadow(color: _bordo.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: _coverImagePath != null
            ? Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.file(File(_coverImagePath!),
                width: double.infinity, height: 130, fit: BoxFit.cover),
          ),
          Positioned(bottom: 10, left: 10,
              child: GestureDetector(
                onTap: _pickCoverPhoto,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.edit_rounded, color: Colors.white, size: 13),
                    SizedBox(width: 5),
                    Text('Promijeni', style: TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              )),
          Positioned(top: 10, right: 10,
              child: GestureDetector(
                onTap: _removeCoverPhoto,
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.50), shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                ),
              )),
        ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 48, height: 48,
              decoration: BoxDecoration(color: _bordoLight, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.add_photo_alternate_rounded, color: _bordo, size: 24)),
          const SizedBox(height: 10),
          const Text('Dodaj naslovnu sliku', style: TextStyle(
              color: _bordo, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text('PNG, JPG · opcionalno', style: TextStyle(
              color: _bordo.withOpacity(0.45), fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _addrStatusWidget() {
    if (_addrChecking) return Row(children: [
      SizedBox(width: 13, height: 13,
          child: CircularProgressIndicator(strokeWidth: 1.8, color: _bordo.withOpacity(0.50))),
      const SizedBox(width: 7),
      Text('Provjera adrese...', style: TextStyle(color: _bordo.withOpacity(0.50), fontSize: 11.5)),
    ]);
    if (_addrValid == true) return Row(children: [
      Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 14),
      const SizedBox(width: 5),
      Text('Adresa pronađena', style: TextStyle(
          color: Colors.green.shade600, fontSize: 11.5, fontWeight: FontWeight.w600)),
    ]);
    if (_addrValid == false) return Row(children: [
      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 14),
      const SizedBox(width: 5),
      Expanded(child: Text(_addrError ?? 'Adresa nije pronađena.',
          style: const TextStyle(color: Colors.redAccent, fontSize: 11.5))),
    ]);
    return const SizedBox.shrink();
  }

  Widget _ticketBox() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _hasTickets ? _bordoLight : const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _hasTickets ? _bordo.withOpacity(0.25) : Colors.grey.withOpacity(0.15)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 40, height: 40,
            decoration: BoxDecoration(
                color: _hasTickets ? _bordo : Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.confirmation_number_rounded,
                color: _hasTickets ? Colors.white : Colors.grey, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Naplaćivanje ulaznica', style: TextStyle(
              color: _hasTickets ? _bordo : Colors.grey.shade700,
              fontSize: 14.5, fontWeight: FontWeight.w700)),
          Text('Postavi cijenu ulaznice za događaj',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ])),
        Switch(value: _hasTickets, activeColor: _bordo,
            onChanged: (v) => setState(() => _hasTickets = v)),
      ]),
      if (_hasTickets) ...[
        const SizedBox(height: 16),
        Divider(height: 1, color: _bordo.withOpacity(0.12)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Cijena ulaznice *'),
            const SizedBox(height: 8),
            _field(_ticketPriceCtrl, '15.00', Icons.euro_rounded,
                keyboard: const TextInputType.numberWithOptions(decimal: true)),
          ])),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Valuta'),
            const SizedBox(height: 8),
            _currencyDrop(),
          ])),
        ]),
        if (_ticketPriceCtrl.text.isNotEmpty && _maxPeopleCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _bordo.withOpacity(0.15))),
            child: Row(children: [
              Icon(Icons.bar_chart_rounded, color: _bordo.withOpacity(0.60), size: 16),
              const SizedBox(width: 8),
              Text(() {
                final price = double.tryParse(_ticketPriceCtrl.text.replaceAll(',', '.')) ?? 0;
                final max   = int.tryParse(_maxPeopleCtrl.text) ?? 0;
                return 'Max. prihod: ${(price * max).toStringAsFixed(2)} ${_selectedCurrency ?? 'EUR'}';
              }(), style: TextStyle(color: _bordo, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ],
    ]),
  );

  Widget _label(String t) => Text(t, style: const TextStyle(
      color: _bordo, fontSize: 13.5, fontWeight: FontWeight.w700));

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? keyboard}) =>
      Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _bordo.withOpacity(0.15), width: 1.2),
          boxShadow: [BoxShadow(color: _bordo.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
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

  Widget _cityDrop() => Container(
    height: 52,
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _bordo.withOpacity(0.15), width: 1.2),
      boxShadow: [BoxShadow(color: _bordo.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
    ),
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
      style: const TextStyle(color: _bordo, fontSize: 14.5, fontWeight: FontWeight.w500),
      dropdownColor: Colors.white, borderRadius: BorderRadius.circular(14),
      onChanged: (v) {
        setState(() => _selectedCity = v);
        if (_locationCtrl.text.trim().isNotEmpty) _onAddrChanged();
      },
      items: _cities.map((c) => DropdownMenuItem(value: c,
          child: Row(children: [
            Icon(Icons.location_on_rounded, color: _bordo.withOpacity(0.55), size: 16),
            const SizedBox(width: 8), Text(c),
          ]))).toList(),
    )),
  );

  Widget _currencyDrop() => Container(
    height: 52,
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _bordo.withOpacity(0.15), width: 1.2),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
      value: _selectedCurrency, isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: _bordo.withOpacity(0.45)),
      style: const TextStyle(color: _bordo, fontSize: 14, fontWeight: FontWeight.w500),
      dropdownColor: Colors.white, borderRadius: BorderRadius.circular(14),
      onChanged: (v) => setState(() => _selectedCurrency = v),
      items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
    )),
  );

  Widget _datePicker() => GestureDetector(
    onTap: _pickDate,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220), height: 52,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _selectedDate != null ? _bordo.withOpacity(0.40) : _bordo.withOpacity(0.15),
            width: 1.2),
        boxShadow: [BoxShadow(color: _bordo.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
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

  Widget _catChips() => Wrap(spacing: 8, runSpacing: 8, children: _categories.map((cat) {
    final sel = _selectedCategory == cat.$1;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedCategory = sel ? null : cat.$1); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? _bordo : Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? _bordo : _bordo.withOpacity(0.18), width: 1.2),
          boxShadow: sel ? [BoxShadow(color: _bordo.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))] : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(cat.$2, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(cat.$1, style: TextStyle(color: sel ? Colors.white : _bordo,
              fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }).toList());

  Widget _ageChips() => Wrap(spacing: 8, runSpacing: 8, children: AgeGroup.values.map((g) {
    final sel = _selAge == g;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _selAge = g); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? _bordo : Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? _bordo : _bordo.withOpacity(0.18), width: 1.2),
        ),
        child: Text(g.label, style: TextStyle(
            color: sel ? Colors.white : _bordo, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }).toList());

  Widget _genderChips() => Wrap(spacing: 8, runSpacing: 8, children: GenderGroup.values.map((g) {
    final sel = _selGender == g;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _selGender = g); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? _bordo : Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? _bordo : _bordo.withOpacity(0.18), width: 1.2),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(g.emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(g.label, style: TextStyle(color: sel ? Colors.white : _bordo,
              fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }).toList());

  Widget _descField() => Container(
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _bordo.withOpacity(0.15), width: 1.2),
      boxShadow: [BoxShadow(color: _bordo.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: TextField(
      controller: _descCtrl, maxLines: 4, onChanged: (_) => setState(() {}),
      style: const TextStyle(color: _bordo, fontSize: 14.5, height: 1.5),
      decoration: InputDecoration(
        hintText: 'Opišite vaš događaj, program, što posjetitelji mogu očekivati...',
        hintStyle: TextStyle(color: _bordo.withOpacity(0.30), fontSize: 14.5),
        border: InputBorder.none, contentPadding: const EdgeInsets.all(14),
      ),
    ),
  );
}