import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'home_screen.dart' show kPrimaryDark, kPrimaryLight, kSurface;
import 'events_nearby.dart' show EventData, addUserEvent;
import 'theme_state.dart';
import 'package:latlong2/latlong.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ORGANIZE MEETUP SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class OrganizeMeetupScreen extends StatefulWidget {
  const OrganizeMeetupScreen({super.key});

  @override
  State<OrganizeMeetupScreen> createState() => _OrganizeMeetupScreenState();
}

class _OrganizeMeetupScreenState extends State<OrganizeMeetupScreen>
    with TickerProviderStateMixin {

  // ── form state ──────────────────────────────────────────────────────────────
  final _titleCtrl       = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _maxPeopleCtrl   = TextEditingController();
  final _timeCtrl        = TextEditingController();

  String? _selectedCity;
  String? _selectedCategory;
  String? _selectedDate;       // formatted display
  DateTime? _pickedDate;
  String? _imagePath;          // null = auto color

  // ── entry animations ────────────────────────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final Animation<double>   _entryFade;
  late final Animation<Offset>   _entrySlide;

  // ── field focus bounce controllers ──────────────────────────────────────────
  late final List<AnimationController> _fieldCtrls;

  // ── submit button ────────────────────────────────────────────────────────────
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

  // Card colors to assign automatically (same palette as events_nearby)
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

    _fieldCtrls = List.generate(6,
            (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 100)));

    _btnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
    _btnScale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn));

    _entryCtrl.forward();
  }

  void _onTheme() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeState.instance.removeListener(_onTheme);
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _maxPeopleCtrl.dispose();
    _timeCtrl.dispose();
    _entryCtrl.dispose();
    _btnCtrl.dispose();
    for (final c in _fieldCtrls) c.dispose();
    super.dispose();
  }

  // ── pick image ──────────────────────────────────────────────────────────────
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

  // ── pick date ───────────────────────────────────────────────────────────────
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
            primary: kPrimaryDark,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: kPrimaryDark,
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
      final year  = picked.year;
      _selectedDate = '$day.$month.$year.';
    });
  }

  // ── validate + submit ───────────────────────────────────────────────────────
  bool get _isValid =>
      _titleCtrl.text.trim().isNotEmpty &&
          _selectedCity != null &&
          _selectedCategory != null &&
          _pickedDate != null &&
          _timeCtrl.text.trim().isNotEmpty;

  void _submit() async {
    if (!_isValid) {
      _showValidationSnack();
      return;
    }
    HapticFeedback.mediumImpact();
    await _btnCtrl.forward();
    await _btnCtrl.reverse();

    // Build EventData
    final colorIndex = _categories.indexWhere((c) => c.$1 == _selectedCategory);
    final cardColor  = _autoColors[colorIndex.clamp(0, _autoColors.length - 1)];
    final day   = _pickedDate!.day.toString().padLeft(2, '0');
    final month = _pickedDate!.month.toString().padLeft(2, '0');

    // Map city name → coordinates (approximate centres)
    final cityCoords = {
      'Zagreb': const LatLng(45.8150, 15.9819),
      'Split':  const LatLng(43.5081, 16.4402),
      'Rijeka': const LatLng(45.3271, 14.4422),
      'Osijek': const LatLng(45.5550, 18.6955),
      'Zadar':  const LatLng(44.1194, 15.2314),
    };

    final maxP = int.tryParse(_maxPeopleCtrl.text.trim()) ?? 20;

    final event = EventData(
      title: _titleCtrl.text.trim(),
      location: _selectedCity!,
      dateDay: '$day.',
      dateMonth: '$month.',
      time: _timeCtrl.text.trim(),
      description: _descCtrl.text.trim().isNotEmpty
          ? _descCtrl.text.trim()
          : 'Osobni meetup organiziran putem MeetCute aplikacije.',
      attendees: 0,
      coordinates: cityCoords[_selectedCity] ?? const LatLng(45.8150, 15.9819),
      imagePath: '',          // no asset; we pass imagePath separately
      categories: [_selectedCategory!],
      cardColor: cardColor,
      isUserEvent: true,
      maxAttendees: maxP,
      userImagePath: _imagePath,
    );

    // Add to global event list (events_nearby will pick it up)
    addUserEvent(_selectedCity!, event);

    if (mounted) {
      _showSuccessDialog();
    }
  }

  void _showValidationSnack() {
    final isDark = ThemeState.instance.isDark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Popuni sva obavezna polja ✦',
            style: TextStyle(color: isDark ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600)),
        backgroundColor: kPrimaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.22), blurRadius: 40, offset: const Offset(0, 14))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [kPrimaryLight, kPrimaryDark.withOpacity(0.18)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: kPrimaryDark, size: 34),
              ),
              const SizedBox(height: 18),
              const Text('Meetup kreiran! 🎉',
                  style: TextStyle(color: kPrimaryDark, fontWeight: FontWeight.w900,
                      fontSize: 20, letterSpacing: -0.4)),
              const SizedBox(height: 10),
              Text('Tvoj meetup je dodan u Događanja u blizini. Sretno! ✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kPrimaryDark.withOpacity(0.55),
                      fontSize: 14, height: 1.55)),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop(); // close dialog
                  Navigator.of(context).pop(); // back to home
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: kPrimaryDark,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.30), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: const Center(
                    child: Text('Odlično!', style: TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

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

                    // ── PHOTO SECTION ────────────────────────────────────────
                    _buildPhotoSection(),
                    const SizedBox(height: 24),

                    // ── NAZIV ────────────────────────────────────────────────
                    _sectionLabel('Naziv meetupa *'),
                    const SizedBox(height: 8),
                    _fieldAnim(0, _buildTextField(
                      ctrl: _titleCtrl,
                      hint: 'Npr. Jutarnja kava i razgovor',
                      icon: Icons.edit_rounded,
                    )),
                    const SizedBox(height: 18),

                    // ── GRAD ─────────────────────────────────────────────────
                    _sectionLabel('Grad *'),
                    const SizedBox(height: 8),
                    _fieldAnim(1, _buildCityPicker()),
                    const SizedBox(height: 18),

                    // ── KATEGORIJA ───────────────────────────────────────────
                    _sectionLabel('Kategorija *'),
                    const SizedBox(height: 10),
                    _buildCategoryChips(),
                    const SizedBox(height: 18),

                    // ── DATUM & VRIJEME ───────────────────────────────────────
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _sectionLabel('Datum *'),
                        const SizedBox(height: 8),
                        _fieldAnim(2, _buildDatePicker()),
                      ])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _sectionLabel('Vrijeme *'),
                        const SizedBox(height: 8),
                        _fieldAnim(3, _buildTextField(
                          ctrl: _timeCtrl,
                          hint: '10:00 – 12:00',
                          icon: Icons.access_time_rounded,
                          keyboardType: TextInputType.text,
                        )),
                      ])),
                    ]),
                    const SizedBox(height: 18),

                    // ── MAX PEOPLE ────────────────────────────────────────────
                    _sectionLabel('Max. broj sudionika'),
                    const SizedBox(height: 8),
                    _fieldAnim(4, _buildTextField(
                      ctrl: _maxPeopleCtrl,
                      hint: '20',
                      icon: Icons.people_rounded,
                      keyboardType: TextInputType.number,
                    )),
                    const SizedBox(height: 18),

                    // ── OPIS ──────────────────────────────────────────────────
                    _sectionLabel('Opis'),
                    const SizedBox(height: 8),
                    _fieldAnim(5, _buildDescField()),
                    const SizedBox(height: 32),

                    // ── SUBMIT ────────────────────────────────────────────────
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

  // ── HEADER ─────────────────────────────────────────────────────────────────
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
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(color: primary, fontSize: 22,
                  fontWeight: FontWeight.w900, letterSpacing: -0.5),
              child: const Text('Organiziraj meetup'),
            ),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(color: primary.withOpacity(0.40), fontSize: 13, fontWeight: FontWeight.w500),
              child: const Text('Stvori vlastiti događaj'),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── PHOTO SECTION ───────────────────────────────────────────────────────────
  Widget _buildPhotoSection() {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? const Color(0xFFBF8997) : kPrimaryDark;

    return GestureDetector(
      onTap: _imagePath == null ? _pickImage : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 180,
        decoration: BoxDecoration(
          color: _imagePath != null
              ? Colors.transparent
              : kPrimaryLight.withOpacity(isDark ? 0.30 : 0.60),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _imagePath != null
                ? Colors.transparent
                : primary.withOpacity(0.18),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
        child: _imagePath != null
            ? Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(File(_imagePath!),
                width: double.infinity, height: 180, fit: BoxFit.cover),
          ),
          // Edit overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.32)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12, right: 12,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _photoBtn(icon: Icons.edit_rounded, onTap: _pickImage),
              const SizedBox(width: 8),
              _photoBtn(icon: Icons.delete_rounded, onTap: _removeImage, red: true),
            ]),
          ),
          Positioned(
            top: 12, left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.40),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Naslovna slika', style: TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
        ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: kPrimaryDark.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add_photo_alternate_rounded, color: primary, size: 26),
          ),
          const SizedBox(height: 10),
          Text('Dodaj sliku eventu', style: TextStyle(
              color: primary, fontWeight: FontWeight.w700, fontSize: 14.5)),
          const SizedBox(height: 4),
          Text('ili će biti dodijeljena automatska boja',
              style: TextStyle(color: primary.withOpacity(0.42), fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _photoBtn({required IconData icon, required VoidCallback onTap, bool red = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: red ? Colors.redAccent : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.20), blurRadius: 8)],
        ),
        child: Icon(icon, color: red ? Colors.white : kPrimaryDark, size: 17),
      ),
    );
  }

  // ── SECTION LABEL ───────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? const Color(0xFFBF8997) : kPrimaryDark;
    return Text(text, style: TextStyle(
        color: primary, fontSize: 13.5, fontWeight: FontWeight.w700));
  }

  // ── FIELD ANIMATION ─────────────────────────────────────────────────────────
  Widget _fieldAnim(int idx, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + idx * 60),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(opacity: v,
          child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: c)),
      child: child,
    );
  }

  // ── TEXT FIELD ──────────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? const Color(0xFFBF8997) : kPrimaryDark;
    final cardBg  = isDark ? const Color(0xFF393737) : Colors.white;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withOpacity(0.15), width: 1.2),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        const SizedBox(width: 14),
        Icon(icon, color: primary.withOpacity(0.45), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: primary, fontSize: 14.5, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: primary.withOpacity(0.30), fontSize: 14.5),
              border: InputBorder.none, isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
      ]),
    );
  }

  // ── DATE PICKER ─────────────────────────────────────────────────────────────
  Widget _buildDatePicker() {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? const Color(0xFFBF8997) : kPrimaryDark;
    final cardBg  = isDark ? const Color(0xFF393737) : Colors.white;
    return GestureDetector(
      onTap: _pickDate,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 52,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _selectedDate != null
                ? primary.withOpacity(0.40)
                : primary.withOpacity(0.15),
            width: 1.2,
          ),
          boxShadow: [BoxShadow(color: primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          const SizedBox(width: 14),
          Icon(Icons.calendar_today_rounded,
              color: _selectedDate != null ? primary : primary.withOpacity(0.45), size: 18),
          const SizedBox(width: 10),
          Text(
            _selectedDate ?? 'Odaberi datum',
            style: TextStyle(
              color: _selectedDate != null ? primary : primary.withOpacity(0.30),
              fontSize: 14.5, fontWeight: FontWeight.w500,
            ),
          ),
        ]),
      ),
    );
  }

  // ── CITY PICKER ─────────────────────────────────────────────────────────────
  Widget _buildCityPicker() {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? const Color(0xFFBF8997) : kPrimaryDark;
    final cardBg  = isDark ? const Color(0xFF393737) : Colors.white;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withOpacity(0.15), width: 1.2),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCity,
          hint: Row(children: [
            Icon(Icons.location_on_rounded, color: primary.withOpacity(0.45), size: 18),
            const SizedBox(width: 10),
            Text('Odaberi grad', style: TextStyle(color: primary.withOpacity(0.30), fontSize: 14.5)),
          ]),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: primary.withOpacity(0.45)),
          style: TextStyle(color: primary, fontSize: 14.5, fontWeight: FontWeight.w500,
              fontFamily: 'SF Pro Display'),
          dropdownColor: cardBg,
          borderRadius: BorderRadius.circular(14),
          onChanged: (v) => setState(() { _selectedCity = v; }),
          items: _cities.map((c) => DropdownMenuItem(
            value: c,
            child: Row(children: [
              Icon(Icons.location_on_rounded, color: primary.withOpacity(0.55), size: 16),
              const SizedBox(width: 8),
              Text(c),
            ]),
          )).toList(),
        ),
      ),
    );
  }

  // ── CATEGORY CHIPS ──────────────────────────────────────────────────────────
  Widget _buildCategoryChips() {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? const Color(0xFFBF8997) : kPrimaryDark;
    final cardBg  = isDark ? const Color(0xFF393737) : Colors.white;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        final selected = _selectedCategory == cat.$1;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedCategory = selected ? null : cat.$1);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? kPrimaryDark : cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? kPrimaryDark : primary.withOpacity(0.18),
                width: 1.2,
              ),
              boxShadow: selected
                  ? [BoxShadow(color: kPrimaryDark.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))]
                  : [],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(cat.$2, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(cat.$1, style: TextStyle(
                color: selected ? Colors.white : primary,
                fontSize: 13, fontWeight: FontWeight.w600,
              )),
            ]),
          ),
        );
      }).toList(),
    );
  }

  // ── DESCRIPTION ─────────────────────────────────────────────────────────────
  Widget _buildDescField() {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? const Color(0xFFBF8997) : kPrimaryDark;
    final cardBg  = isDark ? const Color(0xFF393737) : Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withOpacity(0.15), width: 1.2),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: TextField(
        controller: _descCtrl,
        maxLines: 4,
        onChanged: (_) => setState(() {}),
        style: TextStyle(color: primary, fontSize: 14.5, fontWeight: FontWeight.w400, height: 1.5),
        decoration: InputDecoration(
          hintText: 'Opiši što te čeka na meetupu...',
          hintStyle: TextStyle(color: primary.withOpacity(0.30), fontSize: 14.5),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  // ── SUBMIT BUTTON ───────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    final ready = _isValid;
    return ScaleTransition(
      scale: _btnScale,
      child: GestureDetector(
        onTapDown: (_) { if (ready) _btnCtrl.forward(); },
        onTapUp: (_)   { _btnCtrl.reverse(); _submit(); },
        onTapCancel: () => _btnCtrl.reverse(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          height: 54,
          decoration: BoxDecoration(
            color: ready ? kPrimaryDark : kPrimaryDark.withOpacity(0.28),
            borderRadius: BorderRadius.circular(27),
            boxShadow: ready
                ? [BoxShadow(color: kPrimaryDark.withOpacity(0.32), blurRadius: 18, offset: const Offset(0, 7))]
                : [],
          ),
          child: Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.celebration_rounded,
                  color: ready ? Colors.white : Colors.white.withOpacity(0.45), size: 20),
              const SizedBox(width: 10),
              Text('Objavi meetup',
                  style: TextStyle(
                    color: ready ? Colors.white : Colors.white.withOpacity(0.45),
                    fontSize: 16, fontWeight: FontWeight.w800,
                  )),
            ]),
          ),
        ),
      ),
    );
  }
}