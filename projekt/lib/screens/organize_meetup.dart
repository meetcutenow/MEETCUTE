import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'home_screen.dart' show kPrimaryDark, kPrimaryLight, kSurface;
import 'events_nearby.dart' show EventData, addUserEvent, AgeGroup, GenderGroup, AgeGroupLabel, GenderGroupLabel;
import 'theme_state.dart';
import 'package:latlong2/latlong.dart';

class OrganizeMeetupScreen extends StatefulWidget {
  const OrganizeMeetupScreen({super.key});
  @override
  State<OrganizeMeetupScreen> createState() => _OrganizeMeetupScreenState();
}

class _OrganizeMeetupScreenState extends State<OrganizeMeetupScreen>
    with TickerProviderStateMixin {

  final _titleCtrl        = TextEditingController();
  final _descCtrl         = TextEditingController();
  final _maxPeopleCtrl    = TextEditingController();
  final _timeCtrl         = TextEditingController();
  final _specificLocCtrl  = TextEditingController();

  String? _selectedCity;
  String? _selectedCategory;
  String? _selectedDate;
  DateTime? _pickedDate;
  String? _imagePath;
  AgeGroup _selectedAge       = AgeGroup.all;
  GenderGroup _selectedGender = GenderGroup.all;

  // Validacija adrese
  bool _addrChecking  = false;  // debounce u toku
  bool? _addrValid;             // null=nije provjereno, true=ok, false=nije nađeno
  String? _addrError;
  // ignore: cancel_subscriptions
  Future<void>? _addrDebounce;

  // Validacija vremena
  String? _timeError;

  late final AnimationController _entryCtrl;
  late final Animation<double>   _entryFade;
  late final Animation<Offset>   _entrySlide;
  late final List<AnimationController> _fieldCtrls;
  late final AnimationController _btnCtrl;
  late final Animation<double>   _btnScale;

  final _picker = ImagePicker();

  static const _cities = ['Zagreb', 'Split', 'Rijeka', 'Osijek', 'Zadar'];
  static const _categories = [
    ('Kava',     '☕'),
    ('Sport',    '🏃'),
    ('Druženja', '🎉'),
    ('Kultura',  '🎭'),
    ('Priroda',  '🌿'),
    ('Hrana',    '🍕'),
  ];

  static const _autoColors = [
    Color(0xFF6DD5E8),
    Color(0xFFFFD166),
    Color(0xFF95D5B2),
    Color(0xFFFFB3C6),
  ];

  @override
  void initState() {
    super.initState();
    ThemeState.instance.addListener(_onTheme);
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _fieldCtrls = List.generate(8,
            (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 100)));
    _btnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
    _btnScale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn));
    _entryCtrl.forward();

    // Debounce validacija adrese
    _specificLocCtrl.addListener(_onAddrChanged);
    // Validacija vremena
    _timeCtrl.addListener(_onTimeChanged);
  }

  void _onAddrChanged() {
    final text = _specificLocCtrl.text.trim();
    if (text.isEmpty) {
      setState(() { _addrValid = null; _addrError = null; _addrChecking = false; });
      return;
    }
    setState(() { _addrChecking = true; _addrValid = null; _addrError = null; });

    // Debounce 800ms
    Future.delayed(const Duration(milliseconds: 800), () async {
      if (!mounted) return;
      if (_specificLocCtrl.text.trim() != text) return; // već promijenjen
      final city = _selectedCity ?? '';
      final geocoded = await _geocode('$text${city.isNotEmpty ? ', $city' : ''}, Croatia');
      if (!mounted) return;
      if (_specificLocCtrl.text.trim() != text) return;
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
    // Prihvaćeni formati: "10:00 – 12:00" ili "10:00 - 12:00" ili "10:00"
    final single = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$');
    final range  = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)\s*[–\-]\s*([01]?\d|2[0-3]):([0-5]\d)$');
    final valid  = single.hasMatch(text) || range.hasMatch(text);
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
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: kPrimaryDark, onPrimary: Colors.white,
            surface: Colors.white, onSurface: kPrimaryDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _pickedDate = picked;
      final day   = picked.day.toString().padLeft(2, '0');
      final month = picked.month.toString().padLeft(2, '0');
      _selectedDate = '$day.$month.${picked.year}.';
    });
  }

  bool get _isValid =>
      _titleCtrl.text.trim().isNotEmpty &&
          _selectedCity != null &&
          _selectedCategory != null &&
          _pickedDate != null &&
          _timeCtrl.text.trim().isNotEmpty &&
          _timeError == null &&
          !_addrChecking &&
          (_specificLocCtrl.text.trim().isEmpty || _addrValid == true);

  bool _isGeocoding = false;

  // Geocode adresu putem Nominatim
  Future<LatLng?> _geocode(String address) async {
    try {
      final query = Uri.encodeComponent(address);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
      );
      final resp = await http.get(url, headers: {'User-Agent': 'MeetCuteApp/1.0'})
          .timeout(const Duration(seconds: 6));
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

  void _submit() async {
    if (!_isValid) { _showValidationSnack(); return; }
    HapticFeedback.mediumImpact();
    await _btnCtrl.forward();
    await _btnCtrl.reverse();

    final colorIndex = _categories.indexWhere((c) => c.$1 == _selectedCategory);
    final cardColor  = _autoColors[colorIndex.clamp(0, _autoColors.length - 1)];
    final day   = _pickedDate!.day.toString().padLeft(2, '0');
    final month = _pickedDate!.month.toString().padLeft(2, '0');

    final cityCoords = {
      'Zagreb': const LatLng(45.8150, 15.9819),
      'Split':  const LatLng(43.5081, 16.4402),
      'Rijeka': const LatLng(45.3271, 14.4422),
      'Osijek': const LatLng(45.5550, 18.6955),
      'Zadar':  const LatLng(44.1194, 15.2314),
    };

    final maxP = int.tryParse(_maxPeopleCtrl.text.trim()) ?? 20;
    final specificLoc = _specificLocCtrl.text.trim();

    // Dohvati koordinate za specifičnu lokaciju (geocoding)
    LatLng coords = cityCoords[_selectedCity] ?? const LatLng(45.8150, 15.9819);
    if (specificLoc.isNotEmpty) {
      setState(() => _isGeocoding = true);
      final geocoded = await _geocode('$specificLoc, $_selectedCity, Croatia');
      if (mounted) setState(() => _isGeocoding = false);
      if (geocoded != null) coords = geocoded;
    }

    final event = EventData(
      title: _titleCtrl.text.trim(),
      location: _selectedCity!,
      specificLocation: specificLoc,
      dateDay: '$day.',
      dateMonth: '$month.',
      time: _timeCtrl.text.trim(),
      description: _descCtrl.text.trim().isNotEmpty
          ? _descCtrl.text.trim()
          : 'Osobni događaj organiziran putem MeetCute aplikacije.',
      attendees: 0,
      coordinates: coords,
      imagePath: '',
      categories: [_selectedCategory!],
      cardColor: cardColor,
      isUserEvent: true,
      maxAttendees: maxP,
      userImagePath: _imagePath,
      ageGroup: _selectedAge,
      genderGroup: _selectedGender,
    );

    addUserEvent(_selectedCity!, event);
    if (mounted) _showSuccessDialog();
  }

  void _showValidationSnack() {
    final isDark = ThemeState.instance.isDark;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Popuni sva obavezna polja ✦',
          style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: kPrimaryDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showSuccessDialog() {
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
              const Text('Događaj kreiran! 🎉',
                  style: TextStyle(color: kPrimaryDark, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.4)),
              const SizedBox(height: 10),
              Text('Tvoj događaj je dodan u Događanja u blizini. Sretno! ✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kPrimaryDark.withOpacity(0.55), fontSize: 14, height: 1.55)),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () { Navigator.of(context).pop(); Navigator.of(context).pop(); },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: kPrimaryDark, borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.30), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: const Center(child: Text('Odlično!',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
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
    final mq    = MediaQuery.of(context);
    final isDark = ThemeState.instance.isDark;
    final bg     = isDark ? const Color(0xFF000000) : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      color: bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FadeTransition(
          opacity: _entryFade,
          child: SlideTransition(
            position: _entrySlide,
            child: Column(children: [
              _buildHeader(mq),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20, 10, 20, mq.padding.bottom + 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    // PHOTO SECTION — centered
                    Center(child: _buildPhotoSection()),
                    const SizedBox(height: 24),

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
                    // Status adrese
                    if (_specificLocCtrl.text.trim().isNotEmpty) ...[
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
                        // Time error
                        if (_timeError != null) ...[
                          const SizedBox(height: 5),
                          Row(children: [
                            Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 13),
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
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(MediaQueryData mq) {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? const Color(0xFFBF8997) : kPrimaryDark;
    final cardBg  = isDark ? const Color(0xFF393737) : Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      color: cardBg,
      padding: EdgeInsets.only(top: mq.padding.top + 10, left: 6, right: 18, bottom: 18),
      child: Row(children: [
        IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primary, size: 20),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 2),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(color: primary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            child: const Text('Organiziraj događaj'),
          ),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(color: primary.withOpacity(0.40), fontSize: 13, fontWeight: FontWeight.w500),
            child: const Text('Stvori vlastiti događaj'),
          ),
        ])),
      ]),
    );
  }

  Widget _buildPhotoSection() {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? const Color(0xFFBF8997) : kPrimaryDark;
    final screenW = MediaQuery.of(context).size.width - 40;
    final photoH  = 200.0;
    final photoW  = (screenW * 0.75).clamp(200.0, 320.0);

    return GestureDetector(
      onTap: _imagePath == null ? _pickImage : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: photoW, height: photoH,
        decoration: BoxDecoration(
          color: _imagePath != null ? Colors.transparent : kPrimaryLight.withOpacity(isDark ? 0.30 : 0.60),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _imagePath != null ? Colors.transparent : primary.withOpacity(0.18), width: 1.5,
          ),
        ),
        child: _imagePath != null
            ? Stack(children: [
          ClipRRect(borderRadius: BorderRadius.circular(20),
              child: Image.file(File(_imagePath!), width: photoW, height: photoH, fit: BoxFit.cover)),
          Positioned.fill(child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.32)]),
            ),
          )),
          Positioned(bottom: 12, right: 12, child: Row(mainAxisSize: MainAxisSize.min, children: [
            _photoBtn(icon: Icons.edit_rounded, onTap: _pickImage),
            const SizedBox(width: 8),
            _photoBtn(icon: Icons.delete_rounded, onTap: _removeImage, red: true),
          ])),
          Positioned(top: 12, left: 14, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.40), borderRadius: BorderRadius.circular(20)),
            child: const Text('Naslovna slika', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          )),
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

  Widget _photoBtn({required IconData icon, required VoidCallback onTap, bool red = false}) {
    return GestureDetector(onTap: onTap,
        child: Container(width: 36, height: 36,
            decoration: BoxDecoration(color: red ? Colors.redAccent : Colors.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.20), blurRadius: 8)]),
            child: Icon(icon, color: red ? Colors.white : kPrimaryDark, size: 17)));
  }

  Widget _addrStatusRow() {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? const Color(0xFFBF8997) : kPrimaryDark;
    if (_addrChecking) {
      return Row(children: [
        SizedBox(width: 13, height: 13,
            child: CircularProgressIndicator(strokeWidth: 1.8, color: primary.withOpacity(0.50))),
        const SizedBox(width: 7),
        Text('Provjera adrese...', style: TextStyle(color: primary.withOpacity(0.50), fontSize: 11.5)),
      ]);
    }
    if (_addrValid == true) {
      return Row(children: [
        Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 14),
        const SizedBox(width: 5),
        Text('Adresa pronađena', style: TextStyle(color: Colors.green.shade600, fontSize: 11.5, fontWeight: FontWeight.w600)),
      ]);
    }
    if (_addrValid == false) {
      return Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 14),
        const SizedBox(width: 5),
        Expanded(child: Text(_addrError ?? 'Adresa nije pronađena.',
            style: const TextStyle(color: Colors.redAccent, fontSize: 11.5))),
      ]);
    }
    return const SizedBox.shrink();
  }

  Widget _sectionLabel(String text) {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? const Color(0xFFBF8997) : kPrimaryDark;
    return Text(text, style: TextStyle(color: primary, fontSize: 13.5, fontWeight: FontWeight.w700));
  }

  Widget _fieldAnim(int idx, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + idx * 60),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: c)),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController ctrl, required String hint, required IconData icon,
    TextInputType? keyboardType,
  }) {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? const Color(0xFFBF8997) : kPrimaryDark;
    final cardBg  = isDark ? const Color(0xFF393737) : Colors.white;
    return Container(
      height: 52,
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary.withOpacity(0.15), width: 1.2),
          boxShadow: [BoxShadow(color: primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Row(children: [
        const SizedBox(width: 14),
        Icon(icon, color: primary.withOpacity(0.45), size: 18),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: ctrl, keyboardType: keyboardType, onChanged: (_) => setState(() {}),
          style: TextStyle(color: primary, fontSize: 14.5, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint, hintStyle: TextStyle(color: primary.withOpacity(0.30), fontSize: 14.5),
            border: InputBorder.none, isDense: true,
          ),
        )),
        const SizedBox(width: 12),
      ]),
    );
  }

  Widget _buildDatePicker() {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? const Color(0xFFBF8997) : kPrimaryDark;
    final cardBg  = isDark ? const Color(0xFF393737) : Colors.white;
    return GestureDetector(onTap: _pickDate,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220), height: 52,
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _selectedDate != null ? primary.withOpacity(0.40) : primary.withOpacity(0.15), width: 1.2),
            boxShadow: [BoxShadow(color: primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
        child: Row(children: [
          const SizedBox(width: 14),
          Icon(Icons.calendar_today_rounded, color: _selectedDate != null ? primary : primary.withOpacity(0.45), size: 18),
          const SizedBox(width: 10),
          Text(_selectedDate ?? 'Odaberi datum', style: TextStyle(
            color: _selectedDate != null ? primary : primary.withOpacity(0.30),
            fontSize: 14.5, fontWeight: FontWeight.w500,
          )),
        ]),
      ),
    );
  }

  Widget _buildCityPicker() {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? const Color(0xFFBF8997) : kPrimaryDark;
    final cardBg  = isDark ? const Color(0xFF393737) : Colors.white;
    return Container(
      height: 52,
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14),
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
        dropdownColor: cardBg, borderRadius: BorderRadius.circular(14),
        onChanged: (v) => setState(() { _selectedCity = v; }),
        items: _cities.map((c) => DropdownMenuItem(value: c,
          child: Row(children: [
            Icon(Icons.location_on_rounded, color: primary.withOpacity(0.55), size: 16),
            const SizedBox(width: 8), Text(c),
          ]),
        )).toList(),
      )),
    );
  }

  Widget _buildCategoryChips() {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? const Color(0xFFBF8997) : kPrimaryDark;
    final cardBg  = isDark ? const Color(0xFF393737) : Colors.white;
    return Wrap(spacing: 8, runSpacing: 8,
      children: _categories.map((cat) {
        final selected = _selectedCategory == cat.$1;
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedCategory = selected ? null : cat.$1); },
          child: AnimatedContainer(duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? kPrimaryDark : cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? kPrimaryDark : primary.withOpacity(0.18), width: 1.2),
              boxShadow: selected ? [BoxShadow(color: kPrimaryDark.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))] : [],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(cat.$2, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(cat.$1, style: TextStyle(color: selected ? Colors.white : primary, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAgeGroupChips() {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? const Color(0xFFBF8997) : kPrimaryDark;
    final cardBg  = isDark ? const Color(0xFF393737) : Colors.white;
    return Wrap(spacing: 8, runSpacing: 8,
      children: AgeGroup.values.map((g) {
        final sel = _selectedAge == g;
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedAge = g); },
          child: AnimatedContainer(duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: sel ? kPrimaryDark : cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? kPrimaryDark : primary.withOpacity(0.18), width: 1.2),
              boxShadow: sel ? [BoxShadow(color: kPrimaryDark.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))] : [],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('🎂', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Text(g.label, style: TextStyle(color: sel ? Colors.white : primary, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGenderGroupChips() {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? const Color(0xFFBF8997) : kPrimaryDark;
    final cardBg  = isDark ? const Color(0xFF393737) : Colors.white;
    return Wrap(spacing: 8, runSpacing: 8,
      children: GenderGroup.values.map((g) {
        final sel = _selectedGender == g;
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedGender = g); },
          child: AnimatedContainer(duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: sel ? kPrimaryDark : cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? kPrimaryDark : primary.withOpacity(0.18), width: 1.2),
              boxShadow: sel ? [BoxShadow(color: kPrimaryDark.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))] : [],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(g.emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Text(g.label, style: TextStyle(color: sel ? Colors.white : primary, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDescField() {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? const Color(0xFFBF8997) : kPrimaryDark;
    final cardBg  = isDark ? const Color(0xFF393737) : Colors.white;
    return Container(
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14),
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
            Icon(Icons.celebration_rounded, color: ready ? Colors.white : Colors.white.withOpacity(0.45), size: 20),
            const SizedBox(width: 10),
            Text('Objavi događaj', style: TextStyle(
              color: ready ? Colors.white : Colors.white.withOpacity(0.45),
              fontSize: 16, fontWeight: FontWeight.w800,
            )),
          ])),
        ),
      ),
    );
  }
}