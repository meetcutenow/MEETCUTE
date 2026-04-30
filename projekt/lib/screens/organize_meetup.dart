import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/cloudinary_service.dart';
import 'home_screen.dart' show kPrimaryDark, kPrimaryLight;
import 'events_nearby.dart' show AgeGroup, GenderGroup, AgeGroupLabel, GenderGroupLabel;
import 'theme_state.dart';
import 'auth_state.dart';
import 'package:latlong2/latlong.dart';

const String _base = 'http://localhost:8080/api';

class BackendEventEdit {
  final String id;
  final String title;
  final String? description;
  final String city;
  final String? specificLocation;
  final String eventDate;
  final String? timeStart;
  final String? timeEnd;
  final String category;
  final String? ageGroup;
  final String? genderGroup;
  final int? maxAttendees;
  final String? cardColorHex;
  final double? latitude;
  final double? longitude;

  const BackendEventEdit({
    required this.id, required this.title, this.description,
    required this.city, this.specificLocation, required this.eventDate,
    this.timeStart, this.timeEnd, required this.category,
    this.ageGroup, this.genderGroup, this.maxAttendees,
    this.cardColorHex, this.latitude, this.longitude,
  });
}

class OrganizeMeetupScreen extends StatefulWidget {
  final BackendEventEdit? editEvent;
  const OrganizeMeetupScreen({super.key, this.editEvent});
  @override State<OrganizeMeetupScreen> createState() => _OrganizeMeetupScreenState();
}

class _OrganizeMeetupScreenState extends State<OrganizeMeetupScreen>
    with TickerProviderStateMixin {

  final _titleCtrl       = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _maxPeopleCtrl   = TextEditingController();
  final _timeCtrl        = TextEditingController();
  final _specificLocCtrl = TextEditingController();

  String? _selectedCity;
  String? _selectedCategory;
  String? _selectedDate;
  DateTime? _pickedDate;
  String? _imagePath;
  AgeGroup    _selectedAge    = AgeGroup.all;
  GenderGroup _selectedGender = GenderGroup.all;

  bool   _addrChecking = false;
  bool?  _addrValid;
  String? _addrError;
  String? _timeError;
  bool   _isGeocoding = false;

  late final AnimationController _entryCtrl;
  late final Animation<double>   _entryFade;
  late final Animation<Offset>   _entrySlide;
  late final List<AnimationController> _fieldCtrls;
  late final AnimationController _btnCtrl;
  late final Animation<double>   _btnScale;

  final _picker = ImagePicker();

  bool get _isEditMode => widget.editEvent != null;

  static const _cities = ['Zagreb', 'Split', 'Rijeka', 'Osijek', 'Zadar'];
  static const _categories = [
    ('Kava',     '☕'), ('Sport',    '🏃'), ('Druženja', '🎉'),
    ('Kultura',  '🎭'), ('Priroda',  '🌿'), ('Hrana',    '🍕'),
  ];
  static const _autoColors = [
    Color(0xFF6DD5E8), Color(0xFFFFD166), Color(0xFF95D5B2), Color(0xFFFFB3C6),
  ];

  // ── Shared theme helpers ───────────────────────────────────────────────────
  Color get _primary => ThemeState.instance.isDark ? const Color(0xFFBF8997) : kPrimaryDark;
  Color get _cardBg  => ThemeState.instance.isDark ? const Color(0xFF393737) : Colors.white;

  String get _authHeader => 'Bearer ${AuthState.instance.accessToken}';

  @override
  void initState() {
    super.initState();
    ThemeState.instance.addListener(_onTheme);
    _entryCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _fieldCtrls = List.generate(8,
            (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 100)));
    _btnCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
    _btnScale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn));
    _entryCtrl.forward();

    _specificLocCtrl.addListener(_onAddrChanged);
    _timeCtrl.addListener(_onTimeChanged);

    if (_isEditMode) _populateFields(widget.editEvent!);
  }

  void _populateFields(BackendEventEdit e) {
    _titleCtrl.text       = e.title;
    _descCtrl.text        = e.description ?? '';
    _maxPeopleCtrl.text   = e.maxAttendees?.toString() ?? '';
    _specificLocCtrl.text = e.specificLocation ?? '';
    _selectedCity         = _cities.contains(e.city) ? e.city : null;
    _selectedCategory     = _categories.any((c) => c.$1 == e.category) ? e.category : null;

    if (e.timeStart != null) {
      final ts = e.timeStart!.substring(0, 5);
      final te = e.timeEnd != null ? e.timeEnd!.substring(0, 5) : null;
      _timeCtrl.text = te != null ? '$ts – $te' : ts;
    }

    try {
      final parts = e.eventDate.split('-');
      if (parts.length == 3) {
        _pickedDate   = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        _selectedDate = '${parts[2]}.${parts[1]}.${parts[0]}.';
      }
    } catch (_) {}

    if (e.ageGroup != null) {
      _selectedAge = AgeGroup.values.firstWhere(
              (g) => g.name == e.ageGroup || g.label == e.ageGroup, orElse: () => AgeGroup.all);
    }
    if (e.genderGroup != null) {
      _selectedGender = GenderGroup.values.firstWhere(
              (g) => g.name == e.genderGroup || g.label == e.genderGroup, orElse: () => GenderGroup.all);
    }
  }

  void _onAddrChanged() {
    final text = _specificLocCtrl.text.trim();
    if (text.isEmpty) {
      setState(() { _addrValid = null; _addrError = null; _addrChecking = false; });
      return;
    }
    setState(() { _addrChecking = true; _addrValid = null; _addrError = null; });
    Future.delayed(const Duration(milliseconds: 800), () async {
      if (!mounted || _specificLocCtrl.text.trim() != text) return;
      final city     = _selectedCity ?? '';
      final geocoded = await _geocode('$text${city.isNotEmpty ? ', $city' : ''}, Croatia');
      if (!mounted || _specificLocCtrl.text.trim() != text) return;
      setState(() {
        _addrChecking = false;
        _addrValid    = geocoded != null;
        _addrError    = geocoded == null ? 'Adresa nije pronađena. Provjeri pravopis.' : null;
      });
    });
  }

  void _onTimeChanged() {
    final text = _timeCtrl.text.trim();
    if (text.isEmpty) { setState(() => _timeError = null); return; }
    final valid = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').hasMatch(text) ||
        RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)\s*[–\-]\s*([01]?\d|2[0-3]):([0-5]\d)$').hasMatch(text);
    setState(() => _timeError = valid ? null : 'Format: 10:00 – 12:00');
  }

  void _onTheme() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeState.instance.removeListener(_onTheme);
    _titleCtrl.dispose(); _descCtrl.dispose(); _maxPeopleCtrl.dispose();
    _timeCtrl.dispose(); _specificLocCtrl.dispose();
    _entryCtrl.dispose(); _btnCtrl.dispose();
    for (final c in _fieldCtrls) c.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    final xFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xFile == null) return;
    setState(() => _imagePath = xFile.path);
  }

  void _removeImage() {
    HapticFeedback.mediumImpact();
    setState(() => _imagePath = null);
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate ?? now.add(const Duration(days: 1)),
      firstDate: now, lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(
          primary: kPrimaryDark, onPrimary: Colors.white,
          surface: Colors.white, onSurface: kPrimaryDark,
        )),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _pickedDate   = picked;
      _selectedDate = '${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}.';
    });
  }

  bool get _isValid =>
      _titleCtrl.text.trim().isNotEmpty &&
          _selectedCity != null && _selectedCategory != null && _pickedDate != null &&
          _timeCtrl.text.trim().isNotEmpty && _timeError == null && !_addrChecking &&
          (_specificLocCtrl.text.trim().isEmpty || _addrValid == true || _isEditMode);

  Future<LatLng?> _geocode(String address) async {
    try {
      final resp = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1'),
        headers: {'User-Agent': 'MeetCuteApp/1.0'},
      ).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat'].toString());
          final lon = double.tryParse(data[0]['lon'].toString());
          if (lat != null && lon != null) return LatLng(lat, lon);
        }
      }
    } catch (_) {}
    return null;
  }

  (String?, String?) _parseTime(String text) {
    final t = text.trim();
    final m = RegExp(r'^(\d{2}:\d{2})\s*[–\-]\s*(\d{2}:\d{2})$').firstMatch(t);
    if (m != null) return (m.group(1), m.group(2));
    if (t.length == 5) return (t, null);
    return (null, null);
  }

  void _submit() async {
    if (!_isValid) { _showValidationSnack(); return; }
    HapticFeedback.mediumImpact();
    await _btnCtrl.forward(); await _btnCtrl.reverse();

    final token = AuthState.instance.accessToken;
    if (token == null) { _showSnack('Nisi prijavljen/a.'); return; }

    final specificLoc  = _specificLocCtrl.text.trim();
    final (ts, te)     = _parseTime(_timeCtrl.text);
    final eventDateStr = '${_pickedDate!.year}-${_pickedDate!.month.toString().padLeft(2, '0')}-${_pickedDate!.day.toString().padLeft(2, '0')}';

    if (_isEditMode) await _updateEvent(token, eventDateStr, specificLoc, ts, te);
    else             await _createEvent(token, eventDateStr, specificLoc, ts, te);
  }

  Future<void> _createEvent(String token, String eventDateStr, String specificLoc,
      String? timeStart, String? timeEnd) async {
    setState(() => _isGeocoding = true);

    String? coverPhotoUrl;
    if (_imagePath != null) {
      try {
        coverPhotoUrl = (await CloudinaryService.uploadImage(
          filePath: _imagePath!, token: token, folder: 'meetcute/events',
        )).url;
      } catch (e) { debugPrint('Upload slike nije uspio: $e'); }
    }

    LatLng? coords;
    if (specificLoc.isNotEmpty) coords = await _geocode('$specificLoc, $_selectedCity, Croatia');
    if (!mounted) return;
    setState(() => _isGeocoding = false);

    final colorIndex = _categories.indexWhere((c) => c.$1 == _selectedCategory);
    final cardColor  = _autoColors[colorIndex.clamp(0, _autoColors.length - 1)];
    final desc       = _descCtrl.text.trim();

    final body = {
      'title':            _titleCtrl.text.trim(),
      'description':      desc.isEmpty ? 'Osobni događaj organiziran putem MeetCute aplikacije.' : desc,
      'city':             _selectedCity!,
      'specificLocation': specificLoc.isEmpty ? null : specificLoc,
      'eventDate':        eventDateStr,
      'timeStart':        timeStart, 'timeEnd': timeEnd,
      'category':         _selectedCategory!,
      'ageGroup':         _selectedAge.name,
      'genderGroup':      _selectedGender.name,
      'maxAttendees':     int.tryParse(_maxPeopleCtrl.text.trim()) ?? 20,
      'cardColorHex':     '#${cardColor.value.toRadixString(16).substring(2).toUpperCase()}',
      'latitude':         coords?.latitude, 'longitude': coords?.longitude,
      if (coverPhotoUrl != null) 'coverPhotoUrl': coverPhotoUrl,
    };

    try {
      final resp = await http.post(Uri.parse('$_base/events'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      final decoded = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      if (!mounted) return;
      if (resp.statusCode == 200 && decoded['success'] == true) _showSuccessDialog(isEdit: false);
      else _showSnack(decoded['message'] ?? 'Greška pri kreiranju eventa.');
    } catch (e) {
      if (mounted) _showSnack('Greška: $e');
    }
  }

  Future<void> _updateEvent(String token, String eventDateStr, String specificLoc,
      String? timeStart, String? timeEnd) async {
    final body = <String, dynamic>{
      'title':            _titleCtrl.text.trim(),
      'description':      _descCtrl.text.trim(),
      'city':             _selectedCity!,
      'specificLocation': specificLoc.isEmpty ? null : specificLoc,
      'eventDate':        eventDateStr,
      'timeStart':        timeStart, 'timeEnd': timeEnd,
      'category':         _selectedCategory!,
      'ageGroup':         _selectedAge.name,
      'genderGroup':      _selectedGender.name,
      'maxAttendees':     int.tryParse(_maxPeopleCtrl.text.trim()),
    };

    if (_imagePath != null && !_imagePath!.startsWith('http')) {
      try {
        body['coverPhotoUrl'] = (await CloudinaryService.uploadImage(
          filePath: _imagePath!, token: token, folder: 'meetcute/events',
        )).url;
      } catch (e) { debugPrint('Upload slike nije uspio: $e'); }
    }

    try {
      final resp = await http.put(Uri.parse('$_base/events/${widget.editEvent!.id}'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      final decoded = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      if (!mounted) return;
      if (resp.statusCode == 200 && decoded['success'] == true) _showSuccessDialog(isEdit: true);
      else _showSnack(decoded['message'] ?? 'Greška pri ažuriranju eventa.');
    } catch (e) {
      if (mounted) _showSnack('Ne mogu se spojiti na server.');
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    margin: const EdgeInsets.all(16), duration: const Duration(seconds: 3),
  ));

  void _showValidationSnack() {
    final isDark = ThemeState.instance.isDark;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Popuni sva obavezna polja ✦',
          style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: kPrimaryDark, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16), duration: const Duration(seconds: 2),
    ));
  }

  void _showSuccessDialog({required bool isEdit}) {
    showDialog(
      context: context, barrierDismissible: false,
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
              boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.22), blurRadius: 40, offset: const Offset(0, 14))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 68, height: 68,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [kPrimaryLight, kPrimaryDark.withOpacity(0.18)]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: kPrimaryDark, size: 34)),
              const SizedBox(height: 18),
              Text(isEdit ? 'Događanje ažurirano! ' : 'Događanje kreirano! ',
                  style: const TextStyle(color: kPrimaryDark, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.4)),
              const SizedBox(height: 10),
              Text(isEdit ? 'Promjene su uspješno spremljene.' : 'Tvoj događaj je dodan. Sretno! ',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kPrimaryDark.withOpacity(0.55), fontSize: 14, height: 1.55)),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () { Navigator.of(context).pop(); Navigator.of(context).pop(true); },
                child: Container(height: 50,
                  decoration: BoxDecoration(color: kPrimaryDark, borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.30), blurRadius: 16, offset: const Offset(0, 6))]),
                  child: Center(child: Text(isEdit ? 'Super!' : 'Odlično!',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq     = MediaQuery.of(context);
    final isDark  = ThemeState.instance.isDark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      color: isDark ? const Color(0xFF000000) : Colors.white,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FadeTransition(
          opacity: _entryFade,
          child: SlideTransition(
            position: _entrySlide,
            child: Column(children: [
              _buildHeader(mq),
              Expanded(child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, 10, 20, mq.padding.bottom + 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (!_isEditMode) ...[
                    Center(child: _buildPhotoSection()),
                    const SizedBox(height: 24),
                  ],
                  _sectionLabel('Naziv događaja *'),
                  const SizedBox(height: 8),
                  _fieldAnim(0, _buildTextField(ctrl: _titleCtrl, hint: 'Npr. Jutarnja kava i razgovor', icon: Icons.edit_rounded)),
                  const SizedBox(height: 18),
                  _sectionLabel('Grad *'),
                  const SizedBox(height: 8),
                  _fieldAnim(1, _buildCityPicker()),
                  const SizedBox(height: 18),
                  _sectionLabel('Specifična lokacija sastanka'),
                  const SizedBox(height: 8),
                  _fieldAnim(2, _buildTextField(ctrl: _specificLocCtrl, hint: 'Npr. Caffe Bar Booksa, Martićeva 14d', icon: Icons.place_rounded)),
                  if (_specificLocCtrl.text.trim().isNotEmpty && !_isEditMode) ...[
                    const SizedBox(height: 6),
                    _addrStatusRow(),
                  ],
                  const SizedBox(height: 18),
                  _sectionLabel('Kategorija *'),
                  const SizedBox(height: 10),
                  _buildCategoryChips(),
                  const SizedBox(height: 18),
                  _sectionLabel('Dobna skupina'),
                  const SizedBox(height: 10),
                  _buildAgeGroupChips(),
                  const SizedBox(height: 18),
                  _sectionLabel('Za koga je event?'),
                  const SizedBox(height: 10),
                  _buildGenderGroupChips(),
                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _sectionLabel('Datum *'),
                      const SizedBox(height: 8),
                      _fieldAnim(3, _buildDatePicker()),
                    ])),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _sectionLabel('Vrijeme *'),
                      const SizedBox(height: 8),
                      _fieldAnim(4, _buildTextField(ctrl: _timeCtrl, hint: '10:00 – 12:00', icon: Icons.access_time_rounded, keyboardType: TextInputType.text)),
                      if (_timeError != null) ...[
                        const SizedBox(height: 5),
                        Row(children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 13),
                          const SizedBox(width: 5),
                          Text(_timeError!, style: const TextStyle(color: Colors.redAccent, fontSize: 11.5)),
                        ]),
                      ],
                    ])),
                  ]),
                  const SizedBox(height: 18),
                  _sectionLabel('Max. broj sudionika'),
                  const SizedBox(height: 8),
                  _fieldAnim(5, _buildTextField(ctrl: _maxPeopleCtrl, hint: '20', icon: Icons.people_rounded, keyboardType: TextInputType.number)),
                  const SizedBox(height: 18),
                  _sectionLabel('Opis'),
                  const SizedBox(height: 8),
                  _fieldAnim(6, _buildDescField()),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                ]),
              )),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(MediaQueryData mq) => AnimatedContainer(
    duration: const Duration(milliseconds: 380),
    color: _cardBg,
    padding: EdgeInsets.only(top: mq.padding.top + 10, left: 6, right: 18, bottom: 18),
    child: Row(children: [
      IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: _primary, size: 20),
        onPressed: () => Navigator.pop(context),
        padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
      ),
      const SizedBox(width: 2),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(color: _primary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          child: Text(_isEditMode ? 'Uredi događaj' : 'Organiziraj događaj'),
        ),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(color: _primary.withOpacity(0.40), fontSize: 13, fontWeight: FontWeight.w500),
          child: Text(_isEditMode ? 'Ažuriraj detalje' : 'Stvori vlastiti događaj'),
        ),
      ])),
    ]),
  );

  Widget _buildPhotoSection() {
    final screenW = MediaQuery.of(context).size.width - 40;
    const photoH  = 200.0;
    final photoW  = (screenW * 0.75).clamp(200.0, 320.0);
    final primary = _primary;

    return GestureDetector(
      onTap: _imagePath == null ? _pickImage : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: photoW, height: photoH,
        decoration: BoxDecoration(
          color: _imagePath != null ? Colors.transparent : kPrimaryLight.withOpacity(ThemeState.instance.isDark ? 0.30 : 0.60),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _imagePath != null ? Colors.transparent : primary.withOpacity(0.18), width: 1.5),
        ),
        child: _imagePath != null
            ? Stack(children: [
          ClipRRect(borderRadius: BorderRadius.circular(20),
              child: Image.file(File(_imagePath!), width: photoW, height: photoH, fit: BoxFit.cover)),
          Positioned.fill(child: Container(decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.32)]),
          ))),
          Positioned(bottom: 12, right: 12, child: Row(mainAxisSize: MainAxisSize.min, children: [
            _photoBtn(icon: Icons.edit_rounded, onTap: _pickImage),
            const SizedBox(width: 8),
            _photoBtn(icon: Icons.delete_rounded, onTap: _removeImage, red: true),
          ])),
        ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 56, height: 56,
              decoration: BoxDecoration(color: kPrimaryDark.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(Icons.add_photo_alternate_rounded, color: primary, size: 28)),
          const SizedBox(height: 12),
          Text('Dodaj sliku eventu', style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Text('ili će biti dodijeljena automatska boja', style: TextStyle(color: primary.withOpacity(0.42), fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _photoBtn({required IconData icon, required VoidCallback onTap, bool red = false}) =>
      GestureDetector(onTap: onTap,
          child: Container(width: 36, height: 36,
              decoration: BoxDecoration(color: red ? Colors.redAccent : Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.20), blurRadius: 8)]),
              child: Icon(icon, color: red ? Colors.white : kPrimaryDark, size: 17)));

  Widget _addrStatusRow() {
    final primary = _primary;
    if (_addrChecking) return Row(children: [
      SizedBox(width: 13, height: 13,
          child: CircularProgressIndicator(strokeWidth: 1.8, color: primary.withOpacity(0.50))),
      const SizedBox(width: 7),
      Text('Provjera adrese...', style: TextStyle(color: primary.withOpacity(0.50), fontSize: 11.5)),
    ]);
    if (_addrValid == true) return Row(children: [
      Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 14),
      const SizedBox(width: 5),
      Text('Adresa pronađena', style: TextStyle(color: Colors.green.shade600, fontSize: 11.5, fontWeight: FontWeight.w600)),
    ]);
    if (_addrValid == false) return Row(children: [
      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 14),
      const SizedBox(width: 5),
      Expanded(child: Text(_addrError ?? 'Adresa nije pronađena.',
          style: const TextStyle(color: Colors.redAccent, fontSize: 11.5))),
    ]);
    return const SizedBox.shrink();
  }

  Widget _sectionLabel(String text) => Text(text,
      style: TextStyle(color: _primary, fontSize: 13.5, fontWeight: FontWeight.w700));

  Widget _fieldAnim(int idx, Widget child) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: Duration(milliseconds: 400 + idx * 60),
    curve: Curves.easeOutCubic,
    builder: (_, v, c) => Opacity(opacity: v,
        child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: c)),
    child: child,
  );

  Widget _buildTextField({
    required TextEditingController ctrl, required String hint, required IconData icon,
    TextInputType? keyboardType,
  }) {
    final primary = _primary;
    return Container(
      height: 52,
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary.withOpacity(0.15), width: 1.2),
          boxShadow: [BoxShadow(color: primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Row(children: [
        const SizedBox(width: 14),
        Icon(icon, color: primary.withOpacity(0.45), size: 18),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: ctrl, keyboardType: keyboardType, onChanged: (_) => setState(() {}),
          style: TextStyle(color: primary, fontSize: 14.5, fontWeight: FontWeight.w500),
          decoration: InputDecoration(hintText: hint,
              hintStyle: TextStyle(color: primary.withOpacity(0.30), fontSize: 14.5),
              border: InputBorder.none, isDense: true),
        )),
        const SizedBox(width: 12),
      ]),
    );
  }

  Widget _buildDatePicker() {
    final primary = _primary;
    return GestureDetector(onTap: _pickDate,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220), height: 52,
        decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primary.withOpacity(_selectedDate != null ? 0.40 : 0.15), width: 1.2),
            boxShadow: [BoxShadow(color: primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
        child: Row(children: [
          const SizedBox(width: 14),
          Icon(Icons.calendar_today_rounded, color: primary.withOpacity(_selectedDate != null ? 1.0 : 0.45), size: 18),
          const SizedBox(width: 10),
          Text(_selectedDate ?? 'Odaberi datum', style: TextStyle(
            color: primary.withOpacity(_selectedDate != null ? 1.0 : 0.30),
            fontSize: 14.5, fontWeight: FontWeight.w500,
          )),
        ]),
      ),
    );
  }

  Widget _buildCityPicker() {
    final primary = _primary;
    return Container(
      height: 52,
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary.withOpacity(0.15), width: 1.2),
          boxShadow: [BoxShadow(color: primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: _selectedCity,
        hint: Row(children: [
          Icon(Icons.location_on_rounded, color: primary.withOpacity(0.45), size: 18),
          const SizedBox(width: 10),
          Text('Odaberi grad', style: TextStyle(color: primary.withOpacity(0.30), fontSize: 14.5)),
        ]),
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: primary.withOpacity(0.45)),
        style: TextStyle(color: primary, fontSize: 14.5, fontWeight: FontWeight.w500, fontFamily: 'SF Pro Display'),
        dropdownColor: _cardBg, borderRadius: BorderRadius.circular(14),
        onChanged: (v) => setState(() => _selectedCity = v),
        items: _cities.map((c) => DropdownMenuItem(value: c,
          child: Row(children: [
            Icon(Icons.location_on_rounded, color: primary.withOpacity(0.55), size: 16),
            const SizedBox(width: 8), Text(c),
          ]),
        )).toList(),
      )),
    );
  }

  Widget _buildChip<T>({
    required T value, required T selected, required String label, required String emoji,
    required void Function(T) onTap,
  }) {
    final sel     = value == selected;
    final primary = _primary;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(value); },
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? kPrimaryDark : _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? kPrimaryDark : primary.withOpacity(0.18), width: 1.2),
          boxShadow: sel ? [BoxShadow(color: kPrimaryDark.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))] : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: sel ? Colors.white : primary, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildCategoryChips() => Wrap(spacing: 8, runSpacing: 8,
    children: _categories.map((cat) {
      final sel     = _selectedCategory == cat.$1;
      final primary = _primary;
      return GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedCategory = sel ? null : cat.$1); },
        child: AnimatedContainer(duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: sel ? kPrimaryDark : _cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? kPrimaryDark : primary.withOpacity(0.18), width: 1.2),
            boxShadow: sel ? [BoxShadow(color: kPrimaryDark.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))] : [],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(cat.$2, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(cat.$1, style: TextStyle(color: sel ? Colors.white : primary, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
    }).toList(),
  );

  Widget _buildAgeGroupChips() => Wrap(spacing: 8, runSpacing: 8,
    children: AgeGroup.values.map((g) => _buildChip<AgeGroup>(
      value: g, selected: _selectedAge, label: g.label, emoji: '🎂',
      onTap: (v) => setState(() => _selectedAge = v),
    )).toList(),
  );

  Widget _buildGenderGroupChips() => Wrap(spacing: 8, runSpacing: 8,
    children: GenderGroup.values.map((g) => _buildChip<GenderGroup>(
      value: g, selected: _selectedGender, label: g.label, emoji: g.emoji,
      onTap: (v) => setState(() => _selectedGender = v),
    )).toList(),
  );

  Widget _buildDescField() {
    final primary = _primary;
    return Container(
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary.withOpacity(0.15), width: 1.2),
          boxShadow: [BoxShadow(color: primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
      child: TextField(
        controller: _descCtrl, maxLines: 4, onChanged: (_) => setState(() {}),
        style: TextStyle(color: primary, fontSize: 14.5, fontWeight: FontWeight.w400, height: 1.5),
        decoration: InputDecoration(
          hintText: 'Opiši svoj događaj...',
          hintStyle: TextStyle(color: primary.withOpacity(0.30), fontSize: 14.5),
          border: InputBorder.none, contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final ready = _isValid && !_isGeocoding;
    return ScaleTransition(scale: _btnScale,
      child: GestureDetector(
        onTapDown: (_) { if (ready) _btnCtrl.forward(); },
        onTapUp: (_)   { _btnCtrl.reverse(); _submit(); },
        onTapCancel: () => _btnCtrl.reverse(),
        child: AnimatedContainer(duration: const Duration(milliseconds: 260), height: 54,
          decoration: BoxDecoration(
            color: ready ? kPrimaryDark : kPrimaryDark.withOpacity(0.28),
            borderRadius: BorderRadius.circular(27),
            boxShadow: ready ? [BoxShadow(color: kPrimaryDark.withOpacity(0.32), blurRadius: 18, offset: const Offset(0, 7))] : [],
          ),
          child: Center(child: _isGeocoding
              ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(_isEditMode ? Icons.save_rounded : Icons.celebration_rounded,
                color: ready ? Colors.white : Colors.white.withOpacity(0.45), size: 20),
            const SizedBox(width: 10),
            Text(_isEditMode ? 'Spremi promjene' : 'Objavi događaj',
                style: TextStyle(
                  color: ready ? Colors.white : Colors.white.withOpacity(0.45),
                  fontSize: 16, fontWeight: FontWeight.w800,
                )),
          ])),
        ),
      ),
    );
  }
}