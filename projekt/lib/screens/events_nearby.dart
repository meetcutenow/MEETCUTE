import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'home_screen.dart' show kPrimaryDark, kPrimaryLight, kSurface;
import 'notifications_screen.dart' show NotificationState, seedStaticNotifications;
import 'theme_state.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════════
const Color _bordo      = Color(0xFF700D25);
const Color _bordoLight = Color(0xFFF2E8E9);
const Color _bordoDark  = Color(0xFF4A0818);

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class _City {
  final String name;
  const _City(this.name);
}

class _Category {
  final String label;
  final IconData? icon;
  final String? emoji;
  const _Category({required this.label, this.icon, this.emoji});
}

class EventData {
  final String title;
  final String location;
  final String dateDay;
  final String dateMonth;
  final String time;           // e.g. '10:00 – 12:00'
  final String description;
  final int    attendees;
  final LatLng coordinates;
  final String imagePath;
  final List<String> categories;
  final Color cardColor;

  const EventData({
    required this.title,
    required this.location,
    required this.dateDay,
    required this.dateMonth,
    this.time        = '10:00 – 12:00',
    this.description = '',
    this.attendees   = 0,
    this.coordinates = const LatLng(45.8150, 15.9819),
    this.imagePath   = '',
    required this.categories,
    this.cardColor = const Color(0xFF6DD5E8),
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// ATTENDANCE STATE  (global, survives navigation)
// ═══════════════════════════════════════════════════════════════════════════════
final _attendanceState = <String, bool>{};   // key = event title
int _effectiveAttendees(EventData e) {
  final joined = _attendanceState[e.title];
  if (joined == null) return e.attendees;
  return joined ? e.attendees + 1 : e.attendees;
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATIC DATA
// ═══════════════════════════════════════════════════════════════════════════════

const _cities = [
  _City('Zagreb'),
  _City('Split'),
  _City('Rijeka'),
  _City('Osijek'),
  _City('Zadar'),
];

const _categories = [
  _Category(label: 'Kava',     icon: Icons.coffee_outlined),
  _Category(label: 'Sport',    emoji: '🏃'),
  _Category(label: 'Druženja', emoji: '🎉'),
  _Category(label: 'Kultura',  emoji: '🎭'),
  _Category(label: 'Priroda',  emoji: '🌿'),
  _Category(label: 'Hrana',    emoji: '🍕'),
];

final _eventsByCity = <int, List<EventData>>{
  // ── Zagreb ──────────────────────────────────────────────────────────────────
  0: [
    const EventData(
      title: 'Running dating',
      location: 'Jezero Jarun',
      dateDay: '14.', dateMonth: '04.',
      time: '10:00 – 12:00',
      attendees: 20,
      coordinates: LatLng(45.7785, 15.9148),
      description:
      'Idealna prilika za sve ljubitelje trčanja da spoje ugodno s korisnim i na '
          'svježem zraku u prirodi upoznaju novu ekipu — a potencijalno se i rode poneke iskre.',
      categories: ['Sport'],
      cardColor: Color(0xFF6DD5E8),
    ),
    const EventData(
      title: 'Jutarnja kava',
      location: 'Stari Grad, Zagreb',
      dateDay: '15.', dateMonth: '04.',
      time: '08:30 – 10:00',
      attendees: 14,
      coordinates: LatLng(45.8131, 15.9741),
      description:
      'Opuštena jutarnja kava u srcu Starog Grada. Upoznaj ljude koji, baš kao i ti, '
          'dan ne mogu zamisliti bez dobrog espresa i zanimljivog razgovora.',
      categories: ['Kava'],
      cardColor: Color(0xFFFFD166),
    ),
    const EventData(
      title: 'Piknik u parku',
      location: 'Park Maksimir',
      dateDay: '16.', dateMonth: '04.',
      time: '12:00 – 15:00',
      attendees: 35,
      coordinates: LatLng(45.8237, 16.0189),
      description:
      'Donesite piknik dekicu i grickalice — mi donosimo dobro raspoloženje! '
          'Opušteno druženje u zelenilu jednog od najljepših parkova u gradu.',
      categories: ['Druženja', 'Priroda'],
      cardColor: Color(0xFF95D5B2),
    ),
    const EventData(
      title: 'Večer komedije',
      location: 'HNK Zagreb',
      dateDay: '17.', dateMonth: '04.',
      time: '20:00 – 22:30',
      attendees: 48,
      coordinates: LatLng(45.8089, 15.9702),
      description:
      'Večer smijeha i kulture u HNK-u. Odlična prigoda za sve koji vole kazalište '
          'i ne boje se glasno smijati uz odabranu ekipu stranaca koji postaju prijatelji.',
      categories: ['Kultura'],
      cardColor: Color(0xFFFFB3C6),
    ),
    const EventData(
      title: 'Street food festival',
      location: 'Trg bana Jelačića',
      dateDay: '18.', dateMonth: '04.',
      time: '11:00 – 20:00',
      attendees: 120,
      coordinates: LatLng(45.8132, 15.9773),
      description:
      'Okusi sve što Zagreb ima za ponuditi — od domaćih specijaliteta do egzotičnih '
          'zalogaja. Savršeno za sve foodie-je koji traže nova lica uz novu hranu.',
      categories: ['Hrana', 'Druženja'],
      cardColor: Color(0xFFFFD166),
    ),
  ],
  // ── Split ────────────────────────────────────────────────────────────────────
  1: [
    const EventData(
      title: 'Plaža & kava',
      location: 'Bačvice, Split',
      dateDay: '14.', dateMonth: '04.',
      time: '09:00 – 11:00',
      attendees: 18,
      coordinates: LatLng(43.5016, 16.4413),
      description:
      'Jutarnja kava uz šum mora na ikoničnim Bačvicama. Idealno za sve koji vole '
          'spoj mirnog jutra i novih poznanstava uz plavu podlogu Jadrana.',
      categories: ['Kava', 'Priroda'],
      cardColor: Color(0xFF6DD5E8),
    ),
    const EventData(
      title: 'Dioklecijanova noć',
      location: 'Dioklecijanova palača',
      dateDay: '20.', dateMonth: '04.',
      time: '21:00 – 23:30',
      attendees: 62,
      coordinates: LatLng(43.5081, 16.4402),
      description:
      'Večernja šetnja i razgovor unutar zidina 1700 godina stare palače. '
          'Povijest, arhitektura i nova poznanstva — savršena kombinacija.',
      categories: ['Kultura'],
      cardColor: Color(0xFFFFB3C6),
    ),
  ],
  // ── Rijeka — nema evenata ────────────────────────────────────────────────────
  2: [],
  // ── Osijek ───────────────────────────────────────────────────────────────────
  3: [
    const EventData(
      title: 'Tvrđa fest',
      location: 'Tvrđa, Osijek',
      dateDay: '22.', dateMonth: '04.',
      time: '17:00 – 22:00',
      attendees: 75,
      coordinates: LatLng(45.5606, 18.6956),
      description:
      'Festival hrane, glazbe i kulture u srcu povijesne Tvrđe. '
          'Savršena prigoda za upoznavanje lokalnih faca i tko zna — možda i više.',
      categories: ['Kultura', 'Hrana'],
      cardColor: Color(0xFFFFD166),
    ),
  ],
  // ── Zadar ─────────────────────────────────────────────────────────────────────
  4: [
    const EventData(
      title: 'Sunčani sat',
      location: 'Morske orgulje, Zadar',
      dateDay: '15.', dateMonth: '04.',
      time: '18:30 – 20:00',
      attendees: 30,
      coordinates: LatLng(44.1152, 15.2214),
      description:
      'Gledanje zalaska sunca uz zvukove morskih orgulja. Romantična i mirna atmosfera '
          'idealna za nove upoznaje dok nebo mijenja boje iznad Jadrana.',
      categories: ['Priroda', 'Druženja'],
      cardColor: Color(0xFF95D5B2),
    ),
    const EventData(
      title: 'Vinska večer',
      location: 'Stari grad, Zadar',
      dateDay: '19.', dateMonth: '04.',
      time: '19:00 – 22:00',
      attendees: 25,
      coordinates: LatLng(44.1164, 15.2272),
      description:
      'Degustacija dalmatinskih vina u konobi u srcu starog Zadra. '
          'Odlični vino, dobra ekipa i priče koje traju do ponoći.',
      categories: ['Hrana'],
      cardColor: Color(0xFFFFB3C6),
    ),
  ],
};

// ═══════════════════════════════════════════════════════════════════════════════
// EVENTS NEARBY SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class EventsNearbyScreen extends StatefulWidget {
  const EventsNearbyScreen({super.key});
  @override
  State<EventsNearbyScreen> createState() => _EventsNearbyScreenState();
}

class _EventsNearbyScreenState extends State<EventsNearbyScreen>
    with TickerProviderStateMixin {

  int     _cityIndex      = 0;
  String? _selectedCat;
  final   TextEditingController _searchCtrl = TextEditingController();
  String  _searchQuery    = '';
  int     _currentPage    = 0;
  bool    _showCityPicker = false;

  late final AnimationController _entryCtrl;
  late final AnimationController _cityPickerCtrl;
  late final AnimationController _cardCtrl;
  late final List<AnimationController> _catCtrls;

  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;
  late final Animation<double> _cityPickerAnim;

  late Animation<Offset>  _cardSlide;
  late Animation<double>  _cardFade;
  late Animation<double>  _cardScale;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _cityPickerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _cityPickerAnim = CurvedAnimation(parent: _cityPickerCtrl, curve: Curves.easeOutCubic);

    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _buildCardAnims(1);
    _cardCtrl.value = 1.0;

    _catCtrls = List.generate(_categories.length,
            (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 200)));

    _entryCtrl.forward();
    ThemeState.instance.addListener(_onTheme);
  }

  void _onTheme() { if (mounted) setState(() {}); }

  void _buildCardAnims(int dir) {
    _cardSlide = Tween<Offset>(begin: Offset(dir * 0.22, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _cardFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _cardScale = Tween<double>(begin: 0.94, end: 1.0)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    ThemeState.instance.removeListener(_onTheme);
    _entryCtrl.dispose();
    _cityPickerCtrl.dispose();
    _cardCtrl.dispose();
    for (final c in _catCtrls) c.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── data ────────────────────────────────────────────────────────────────────
  List<EventData> get _cityEvents => _eventsByCity[_cityIndex] ?? [];

  List<EventData> get _filtered {
    return _cityEvents.where((e) {
      final matchesCat = _selectedCat == null || e.categories.contains(_selectedCat);
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          e.location.toLowerCase().contains(q);
      return matchesCat && matchesSearch;
    }).toList();
  }

  // ── navigation ──────────────────────────────────────────────────────────────
  void _animateCardSwap(int dir) {
    _buildCardAnims(dir);
    _cardCtrl.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  void _nextCard() {
    final events = _filtered;
    if (_currentPage >= events.length - 1) return;
    setState(() => _currentPage++);
    _animateCardSwap(1);
  }

  void _prevCard() {
    if (_currentPage <= 0) return;
    setState(() => _currentPage--);
    _animateCardSwap(-1);
  }

  void _toggleCityPicker() {
    HapticFeedback.selectionClick();
    setState(() => _showCityPicker = !_showCityPicker);
    _showCityPicker ? _cityPickerCtrl.forward() : _cityPickerCtrl.reverse();
  }

  void _selectCity(int idx) {
    if (idx == _cityIndex) { _toggleCityPicker(); return; }
    HapticFeedback.selectionClick();
    setState(() {
      _cityIndex = idx; _showCityPicker = false;
      _currentPage = 0; _selectedCat = null;
    });
    _cityPickerCtrl.reverse();
    _buildCardAnims(1);
    _cardCtrl.forward(from: 0);
  }

  void _openEventDetail(EventData event) {
    HapticFeedback.mediumImpact();
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => EventDetailScreen(event: event),
      transitionsBuilder: (_, a, __, child) {
        final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeIn),
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                .animate(curved),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 380),
    )).then((_) => setState(() {})); // refresh attendance counts on return
  }

  // ═════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isDark = ThemeState.instance.isDark;
    final bg = isDark ? kDarkBg : Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      color: bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FadeTransition(
          opacity: _entryFade,
          child: SlideTransition(
            position: _entrySlide,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(mq),
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 14),
                          _buildLocationBar(),
                          const SizedBox(height: 12),
                          _buildCategoryChips(),
                          const SizedBox(height: 10),
                          Expanded(child: _buildCardArea()),
                          _buildSearchBar(mq),
                        ],
                      ),
                      if (_showCityPicker) _buildCityPickerOverlay(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(MediaQueryData mq) {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? kDarkPrimary : _bordo;
    final cardBg  = isDark ? kDarkCard : Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      color: cardBg,
      padding: EdgeInsets.only(top: mq.padding.top + 10, left: 6, right: 18, bottom: 6),
      child: Row(children: [
        IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primary, size: 20),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 2),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(color: primary, fontSize: 21,
                fontWeight: FontWeight.w800, letterSpacing: -0.5),
            child: const Text('Pronađi događanja za sebe'),
          ),
        ),
      ]),
    );
  }

  // ── LOCATION BAR ────────────────────────────────────────────────────────────
  Widget _buildLocationBar() {
    final isDark   = ThemeState.instance.isDark;
    final primary  = isDark ? kDarkPrimary : _bordo;
    final inactiveBg     = isDark ? kDarkCard : const Color(0xFFF4EDED);
    final inactiveBorder = isDark ? kPrimaryLight.withOpacity(0.15) : const Color(0xFFE8D5D8);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GestureDetector(
        onTap: _toggleCityPicker,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: _showCityPicker ? primary : inactiveBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _showCityPicker ? primary : inactiveBorder, width: 1.5),
            boxShadow: _showCityPicker
                ? [BoxShadow(color: primary.withOpacity(0.20), blurRadius: 14, offset: const Offset(0, 4))]
                : [],
          ),
          child: Row(children: [
            Icon(Icons.location_on_rounded,
                color: _showCityPicker ? (isDark ? kDarkBg : Colors.white) : primary, size: 18),
            const SizedBox(width: 9),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Tvoja lokacija',
                      style: TextStyle(
                        color: _showCityPicker
                            ? (isDark ? kDarkBg : Colors.white).withOpacity(0.65)
                            : primary.withOpacity(0.50),
                        fontSize: 10.5, fontWeight: FontWeight.w500,
                      )),
                  const SizedBox(height: 1),
                  Text(_cities[_cityIndex].name,
                      style: TextStyle(
                        color: _showCityPicker ? (isDark ? kDarkBg : Colors.white) : primary,
                        fontSize: 16, fontWeight: FontWeight.w800,
                      )),
                ]),
            const Spacer(),
            AnimatedRotation(
              turns: _showCityPicker ? 0.5 : 0,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: Icon(Icons.keyboard_arrow_down_rounded,
                  color: _showCityPicker
                      ? (isDark ? kDarkBg : Colors.white).withOpacity(0.80)
                      : primary.withOpacity(0.55), size: 22),
            ),
          ]),
        ),
      ),
    );
  }

  // ── CITY PICKER OVERLAY ─────────────────────────────────────────────────────
  Widget _buildCityPickerOverlay() {
    final isDark  = ThemeState.instance.isDark;
    final cardBg  = isDark ? kDarkCard : Colors.white;
    final border  = isDark ? kPrimaryLight.withOpacity(0.15) : const Color(0xFFE8D5D8);
    final primary = isDark ? kDarkPrimary : _bordo;
    return Positioned(
      top: 14 + 62 + 4, left: 18, right: 18,
      child: FadeTransition(
        opacity: _cityPickerAnim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -0.04), end: Offset.zero)
              .animate(_cityPickerAnim),
          child: Material(
            color: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 340),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border, width: 1.5),
                boxShadow: [
                  BoxShadow(color: primary.withOpacity(0.13), blurRadius: 22, offset: const Offset(0, 8)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_cities.length, (i) => _CityTile(
                    name: _cities[i].name,
                    isSelected: i == _cityIndex,
                    onTap: () => _selectCity(i),
                    showDivider: i < _cities.length - 1,
                  )),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── CATEGORY CHIPS ──────────────────────────────────────────────────────────
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final sel = _selectedCat == cat.label;
          final isDark  = ThemeState.instance.isDark;
          final primary = isDark ? kDarkPrimary : _bordo;
          final chipBg  = isDark ? kDarkCard : Colors.white;
          final chipBdr = isDark ? kDarkCardEl : const Color(0xFFDDC8CB);
          final fgColor = isDark ? kDarkBg : Colors.white;
          return GestureDetector(
            onTapDown: (_) => _catCtrls[i].forward(),
            onTapUp: (_) {
              _catCtrls[i].reverse();
              HapticFeedback.selectionClick();
              setState(() { _selectedCat = sel ? null : cat.label; _currentPage = 0; });
              if (!sel) { _buildCardAnims(1); _cardCtrl.forward(from: 0); }
            },
            onTapCancel: () => _catCtrls[i].reverse(),
            child: AnimatedBuilder(
              animation: _catCtrls[i],
              builder: (_, __) => Transform.scale(
                scale: 1.0 - _catCtrls[i].value * 0.07,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? primary : chipBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: sel ? primary : chipBdr, width: 1.2),
                    boxShadow: sel
                        ? [BoxShadow(color: primary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))]
                        : [],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (cat.icon != null) ...[
                      Icon(cat.icon, size: 13, color: sel ? fgColor : primary),
                      const SizedBox(width: 4),
                    ] else if (cat.emoji != null) ...[
                      Text(cat.emoji!, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                    ],
                    Text(cat.label,
                        style: TextStyle(
                          color: sel ? fgColor : primary,
                          fontSize: 12.5, fontWeight: FontWeight.w600,
                        )),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── CARD AREA ───────────────────────────────────────────────────────────────
  Widget _buildCardArea() {
    final events = _filtered;
    final cityEmpty = _cityEvents.isEmpty;
    final isDark   = ThemeState.instance.isDark;
    final primary  = isDark ? kDarkPrimary : _bordo;
    final emptyBg  = isDark ? kDarkCardEl  : _bordoLight;

    if (cityEmpty || events.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 340),
            width: 72, height: 72,
            decoration: BoxDecoration(color: emptyBg, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: primary.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 6))]),
            child: Icon(cityEmpty ? Icons.location_off_rounded : Icons.search_off_rounded,
                color: primary.withOpacity(0.55), size: 32),
          ),
          const SizedBox(height: 16),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(color: primary.withOpacity(0.65), fontSize: 15,
                fontWeight: FontWeight.w600, height: 1.4),
            child: Text(
              cityEmpty
                  ? 'Nema događanja u\nodabranom gradu!'
                  : 'Nema rezultata',
              textAlign: TextAlign.center,
            ),
          ),
          if (cityEmpty) ...[
            const SizedBox(height: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(color: primary.withOpacity(0.38), fontSize: 13),
              child: const Text('Provjeri drugi grad 👆'),
            ),
          ],
        ]),
      );
    }

    final page = _currentPage.clamp(0, events.length - 1);

    return LayoutBuilder(builder: (ctx, box) {
      final cardW = box.maxWidth - 40;
      final cardH = (box.maxHeight * 0.88).clamp(0.0, 440.0);

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -200) _nextCard();
          if (v > 200)  _prevCard();
        },
        child: Center(
          child: SizedBox(
            width: cardW,
            height: box.maxHeight,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // 3rd stack
                if (events.length > page + 2)
                  Positioned(
                    top: 16, left: 12, right: 12, height: cardH,
                    child: Container(
                      decoration: BoxDecoration(
                        color: events[(page + 2).clamp(0, events.length - 1)]
                            .cardColor.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                  ),
                // 2nd stack
                if (events.length > page + 1)
                  Positioned(
                    top: 8, left: 6, right: 6, height: cardH,
                    child: Container(
                      decoration: BoxDecoration(
                        color: events[(page + 1).clamp(0, events.length - 1)]
                            .cardColor.withOpacity(0.70),
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                  ),
                // Front card — tappable
                Positioned(
                  top: 0, left: 0, right: 0, height: cardH,
                  child: AnimatedBuilder(
                    animation: _cardCtrl,
                    builder: (_, child) => FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: ScaleTransition(scale: _cardScale, child: child),
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () => _openEventDetail(events[page]),
                      child: _EventCard(
                        key: ValueKey('$page-$_cityIndex-${events[page].title}'),
                        event: events[page],
                      ),
                    ),
                  ),
                ),
                // Page dots
                if (events.length > 1)
                  Positioned(
                    bottom: 6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(events.length.clamp(0, 6), (i) =>
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == page ? 16 : 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: i == page ? _bordo : _bordo.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ── SEARCH BAR ──────────────────────────────────────────────────────────────
  Widget _buildSearchBar(MediaQueryData mq) {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? kDarkPrimary : _bordo;
    final bg      = isDark ? kDarkCard : const Color(0xFFF0E8EA);
    final border  = isDark ? kPrimaryLight.withOpacity(0.15) : const Color(0xFFDDC8CB);
    return Padding(
      padding: EdgeInsets.fromLTRB(54, 6, 54, mq.padding.bottom + 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 340),
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 1),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() { _searchQuery = v; _currentPage = 0; }),
          style: TextStyle(color: primary, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Pretraži događanja',
            hintStyle: TextStyle(color: primary.withOpacity(0.35), fontSize: 13),
            suffixIcon: Icon(Icons.search_rounded, color: primary.withOpacity(0.45), size: 18),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            isDense: true,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EVENT CARD (list thumbnail)
// ═══════════════════════════════════════════════════════════════════════════════

class _EventCard extends StatefulWidget {
  final EventData event;
  const _EventCard({super.key, required this.event});
  @override State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> with SingleTickerProviderStateMixin {
  late final AnimationController _shimCtrl;

  @override void initState() {
    super.initState();
    _shimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat();
  }
  @override void dispose() { _shimCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = widget.event.cardColor;
    return Container(
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: c.withOpacity(0.38), blurRadius: 20, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(children: [
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            child: Stack(fit: StackFit.expand, children: [
              if (widget.event.imagePath.isNotEmpty)
                Image.asset(widget.event.imagePath, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: c))
              else
                Container(color: c),

              // shimmer
              AnimatedBuilder(
                animation: _shimCtrl,
                builder: (_, __) {
                  final t = _shimCtrl.value;
                  return Positioned(
                    left: -80 + t * (MediaQuery.of(context).size.width + 160),
                    top: 0, bottom: 0,
                    child: Container(
                      width: 80,
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [
                        Colors.white.withOpacity(0),
                        Colors.white.withOpacity(0.09),
                        Colors.white.withOpacity(0),
                      ])),
                    ),
                  );
                },
              ),
              _cloud(top: 18, left: 14, w: 52, h: 24),
              _cloud(top: 8,  right: 46, w: 38, h: 18),
              _cloud(top: 44, right: 10, w: 28, h: 14),
              _cloud(bottom: 72, left: 22, w: 32, h: 16),

              // tap hint
              Positioned(
                bottom: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.touch_app_rounded, color: Colors.white, size: 13),
                    SizedBox(width: 4),
                    Text('detalji', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          decoration: BoxDecoration(
            color: _bordo,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: _bordo.withOpacity(0.28), blurRadius: 12, offset: const Offset(0, 5))],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, children: [
                  Text(widget.event.title,
                      style: const TextStyle(color: Colors.white, fontSize: 19,
                          fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.location_on_rounded, color: Colors.white.withOpacity(0.55), size: 11),
                    const SizedBox(width: 2),
                    Text(widget.event.location,
                        style: TextStyle(color: Colors.white.withOpacity(0.62), fontSize: 12)),
                  ]),
                ])),
            const SizedBox(width: 8),
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 6, offset: const Offset(0, 2))]),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(widget.event.dateDay,
                    style: const TextStyle(color: _bordo, fontSize: 17, fontWeight: FontWeight.w900, height: 1.0)),
                Text(widget.event.dateMonth,
                    style: const TextStyle(color: _bordo, fontSize: 17, fontWeight: FontWeight.w900, height: 1.0)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _cloud({double? top, double? bottom, double? left, double? right,
    required double w, required double h}) {
    return Positioned(top: top, bottom: bottom, left: left, right: right,
        child: Container(width: w, height: h,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.52),
              borderRadius: BorderRadius.circular(h / 2),
            )));
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CITY TILE
// ═══════════════════════════════════════════════════════════════════════════════

class _CityTile extends StatefulWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showDivider;
  const _CityTile({required this.name, required this.isSelected, required this.onTap, required this.showDivider});
  @override State<_CityTile> createState() => _CityTileState();
}

class _CityTileState extends State<_CityTile> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark   = ThemeState.instance.isDark;
    final primary  = isDark ? kDarkPrimary : _bordo;
    final tileBg   = isDark ? kDarkCard    : Colors.white;
    final hoverBg  = isDark ? kDarkCardEl  : const Color(0xFFF4EDED);
    final divColor = isDark ? kDarkCardEl  : const Color(0xFFE8D5D8);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTapDown: (_) => _c.forward(),
        onTapUp: (_) { _c.reverse(); widget.onTap(); },
        onTapCancel: () => _c.reverse(),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: widget.isSelected
                ? primary.withOpacity(0.08)
                : Color.lerp(tileBg, hoverBg, _c.value),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(color: primary, fontSize: 14.5,
                    fontWeight: widget.isSelected ? FontWeight.w800 : FontWeight.w500),
                child: Text(widget.name),
              ),
              const Spacer(),
              if (widget.isSelected)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 20, height: 20,
                  decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                  child: Icon(Icons.check_rounded,
                      color: isDark ? kDarkBg : Colors.white, size: 13),
                ),
            ]),
          ),
        ),
      ),
      if (widget.showDivider)
        Divider(height: 1, thickness: 0.5, color: divColor, indent: 18, endIndent: 18),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EVENT DETAIL SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class EventDetailScreen extends StatefulWidget {
  final EventData event;
  const EventDetailScreen({super.key, required this.event});
  @override State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen>
    with TickerProviderStateMixin {

  bool get _joined => _attendanceState[widget.event.title] ?? false;

  // ── animations ──────────────────────────────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final AnimationController _heroCtrl;
  late final AnimationController _btnCtrl;
  late final AnimationController _countCtrl;
  late final AnimationController _mapCtrl;

  late final Animation<double> _entryFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _heroScale;
  late final Animation<double> _btnScale;
  late final Animation<double> _countAnim;

  bool _mapExpanded = false;
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    ThemeState.instance.addListener(_onTheme);

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _heroCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _heroScale = Tween<double>(begin: 1.06, end: 1.0)
        .animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOutCubic));

    _btnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 160));
    _btnScale = Tween<double>(begin: 1.0, end: 0.92)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn));

    _countCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _countAnim = CurvedAnimation(parent: _countCtrl, curve: Curves.easeOutBack);

    _mapCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 340));

    _entryCtrl.forward();
    _heroCtrl.forward();
  }

  void _onTheme() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeState.instance.removeListener(_onTheme);
    _entryCtrl.dispose();
    _heroCtrl.dispose();
    _btnCtrl.dispose();
    _countCtrl.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }

  void _toggleJoin() async {
    HapticFeedback.mediumImpact();
    await _btnCtrl.forward();
    await _btnCtrl.reverse();
    final wasJoined = _joined;
    setState(() {
      _attendanceState[widget.event.title] = !wasJoined;
    });
    _countCtrl.forward(from: 0);
    // Fire notification
    NotificationState.instance.onAttendanceChanged(
      widget.event.title,
      widget.event.location,
      widget.event.cardColor,
      !wasJoined,
    );
  }

  void _toggleMap() {
    HapticFeedback.selectionClick();
    setState(() => _mapExpanded = !_mapExpanded);
    _mapExpanded ? _mapCtrl.forward() : _mapCtrl.reverse();
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final event = widget.event;
    final c = event.cardColor;
    final attendees = _effectiveAttendees(event);
    final isDark  = ThemeState.instance.isDark;
    final bgColor = isDark ? kDarkBg : Colors.white;
    final primary = isDark ? kDarkPrimary : _bordoDark;
    final textMuted = isDark ? kDarkTextSub : Colors.black.withOpacity(0.55);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      color: bgColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // ── scrollable content ─────────────────────────────────────────────
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── HERO IMAGE ────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: ScaleTransition(
                    scale: _heroScale,
                    child: Container(
                      height: mq.size.height * 0.42,
                      color: c,
                      child: Stack(fit: StackFit.expand, children: [
                        if (event.imagePath.isNotEmpty)
                          Image.asset(event.imagePath, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: c))
                        else
                          Container(color: c),

                        // subtle gradient at bottom for readability
                        Positioned(
                          bottom: 0, left: 0, right: 0, height: 100,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.18)],
                              ),
                            ),
                          ),
                        ),

                        // decorative clouds
                        _cloudWidget(top: 28, left: 18, w: 70, h: 32),
                        _cloudWidget(top: 14, right: 60, w: 50, h: 24),
                        _cloudWidget(top: 60, right: 16, w: 36, h: 18),
                        _cloudWidget(bottom: 100, left: 30, w: 44, h: 22),
                      ]),
                    ),
                  ),
                ),

                // ── DETAIL CONTENT ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _entryFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 22, 20, mq.padding.bottom + 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // ── TITLE ROW ────────────────────────────────────
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 300),
                                        style: TextStyle(
                                          color: isDark ? kDarkText : Colors.black87, fontSize: 30,
                                          fontWeight: FontWeight.w900, letterSpacing: -0.8, height: 1.1,
                                        ),
                                        child: Text(event.title),
                                      ),
                                      const SizedBox(height: 6),
                                      AnimatedBuilder(
                                        animation: _countAnim,
                                        builder: (_, __) {
                                          return Row(children: [
                                            Transform.scale(
                                              scale: 1.0 + _countAnim.value * 0.12,
                                              child: Text(
                                                '$attendees',
                                                style: TextStyle(
                                                  color: primary, fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            Text(' ljudi se pridružilo',
                                                style: TextStyle(
                                                  color: textMuted,
                                                  fontSize: 14, fontWeight: FontWeight.w500,
                                                )),
                                          ]);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Date badge
                                Container(
                                  width: 68, height: 68,
                                  decoration: BoxDecoration(
                                    color: _bordo,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(color: _bordo.withOpacity(0.30), blurRadius: 14, offset: const Offset(0, 5)),
                                    ],
                                  ),
                                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Text(event.dateDay,
                                        style: const TextStyle(color: Colors.white, fontSize: 20,
                                            fontWeight: FontWeight.w900, height: 1.0)),
                                    Text(event.dateMonth,
                                        style: const TextStyle(color: Colors.white, fontSize: 20,
                                            fontWeight: FontWeight.w900, height: 1.0)),
                                  ]),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // ── TIME + MAP CONTAINER ─────────────────────────
                            GestureDetector(
                              onTap: _toggleMap,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 340),
                                curve: Curves.easeOutCubic,
                                decoration: BoxDecoration(
                                  color: isDark ? kDarkCard : _bordoLight,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: primary.withOpacity(0.12), width: 1),
                                  boxShadow: [
                                    BoxShadow(color: primary.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Collapsed row: time + location + mini map
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          // time & location
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(children: [
                                                  Icon(Icons.access_time_rounded,
                                                      color: primary.withOpacity(0.70), size: 15),
                                                  const SizedBox(width: 6),
                                                  AnimatedDefaultTextStyle(
                                                    duration: const Duration(milliseconds: 300),
                                                    style: TextStyle(
                                                      color: isDark ? kDarkText : _bordoDark, fontSize: 17,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                    child: Text(event.time),
                                                  ),
                                                ]),
                                                const SizedBox(height: 6),
                                                Row(children: [
                                                  Icon(Icons.location_on_rounded,
                                                      color: primary.withOpacity(0.70), size: 15),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: AnimatedDefaultTextStyle(
                                                      duration: const Duration(milliseconds: 300),
                                                      style: TextStyle(
                                                        color: isDark ? kDarkText : _bordoDark, fontSize: 17,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                      child: Text(event.location),
                                                    ),
                                                  ),
                                                ]),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Mini map thumbnail
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: SizedBox(
                                              width: 90, height: 70,
                                              child: Stack(children: [
                                                FlutterMap(
                                                  mapController: _mapController,
                                                  options: MapOptions(
                                                    initialCenter: event.coordinates,
                                                    initialZoom: 14.5,
                                                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                                                  ),
                                                  children: [
                                                    TileLayer(
                                                      urlTemplate:
                                                      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                                                      subdomains: const ['a', 'b', 'c', 'd'],
                                                      userAgentPackageName: 'com.meetcute.app',
                                                    ),
                                                    MarkerLayer(markers: [
                                                      Marker(
                                                        point: event.coordinates,
                                                        width: 22, height: 22,
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            color: _bordo,
                                                            shape: BoxShape.circle,
                                                            border: Border.all(color: Colors.white, width: 2),
                                                            boxShadow: [
                                                              BoxShadow(color: _bordo.withOpacity(0.5), blurRadius: 6),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ]),
                                                  ],
                                                ),
                                                // expand hint overlay
                                                Positioned.fill(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [Colors.transparent,
                                                          Colors.black.withOpacity(0.12)],
                                                        begin: Alignment.topCenter,
                                                        end: Alignment.bottomCenter,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  bottom: 4, right: 4,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(3),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.85),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Icon(
                                                      _mapExpanded
                                                          ? Icons.zoom_in_map_rounded
                                                          : Icons.zoom_out_map_rounded,
                                                      size: 12, color: _bordo,
                                                    ),
                                                  ),
                                                ),
                                              ]),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Expanded map
                                    AnimatedBuilder(
                                      animation: _mapCtrl,
                                      builder: (_, __) {
                                        final h = _mapCtrl.value * 220.0;
                                        if (h < 1) return const SizedBox.shrink();
                                        return ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                              bottom: Radius.circular(20)),
                                          child: SizedBox(
                                            height: h,
                                            child: FlutterMap(
                                              options: MapOptions(
                                                initialCenter: event.coordinates,
                                                initialZoom: 15.0,
                                                interactionOptions: const InteractionOptions(
                                                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                                                ),
                                              ),
                                              children: [
                                                TileLayer(
                                                  urlTemplate:
                                                  'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                                                  subdomains: const ['a', 'b', 'c', 'd'],
                                                  userAgentPackageName: 'com.meetcute.app',
                                                ),
                                                MarkerLayer(markers: [
                                                  Marker(
                                                    point: event.coordinates,
                                                    width: 36, height: 36,
                                                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                                                      Container(
                                                        width: 26, height: 26,
                                                        decoration: BoxDecoration(
                                                          color: _bordo, shape: BoxShape.circle,
                                                          border: Border.all(color: Colors.white, width: 3),
                                                          boxShadow: [BoxShadow(
                                                              color: _bordo.withOpacity(0.5), blurRadius: 8)],
                                                        ),
                                                      ),
                                                      Container(width: 3, height: 7,
                                                        decoration: BoxDecoration(
                                                          color: _bordo,
                                                          borderRadius: BorderRadius.circular(2),
                                                        ),
                                                      ),
                                                    ]),
                                                  ),
                                                ]),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ── DESCRIPTION ──────────────────────────────────
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                color: isDark ? kDarkText : Colors.black87, fontSize: 17,
                                fontWeight: FontWeight.w800, letterSpacing: -0.2,
                              ),
                              child: const Text('Opis'),
                            ),
                            const SizedBox(height: 10),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                color: isDark ? kDarkText.withOpacity(0.65) : Colors.black.withOpacity(0.65),
                                fontSize: 15, height: 1.65,
                              ),
                              child: Text(
                                event.description.isNotEmpty
                                    ? event.description
                                    : 'Više informacija o eventu uskoro.',
                                textAlign: TextAlign.justify,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── BACK BUTTON (floating over hero) ──────────────────────────────
            Positioned(
              top: mq.padding.top + 14,
              left: 14,
              child: FadeTransition(
                opacity: _entryFade,
                child: _BackButton(onTap: () => Navigator.pop(context)),
              ),
            ),

            // ── JOIN BUTTON (pinned at bottom) ───────────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _buildJoinBar(mq),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinBar(MediaQueryData mq) {
    final isDark  = ThemeState.instance.isDark;
    final cardBg  = isDark ? kDarkCard : Colors.white;
    final primary = isDark ? kDarkPrimary : _bordo;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      decoration: BoxDecoration(
        color: cardBg,
        boxShadow: [
          BoxShadow(color: primary.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 14, 24, mq.padding.bottom + 14),
      child: AnimatedBuilder(
        animation: _btnScale,
        builder: (_, child) => Transform.scale(scale: _btnScale.value, child: child),
        child: GestureDetector(
          onTap: _toggleJoin,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            height: 54,
            decoration: BoxDecoration(
              color: _joined
                  ? (isDark ? const Color(0xFF3A3A42) : const Color(0xFF2C2C2C))
                  : primary,
              borderRadius: BorderRadius.circular(27),
              boxShadow: [
                BoxShadow(
                  color: (_joined ? Colors.black : primary).withOpacity(0.28),
                  blurRadius: 16, offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    _joined ? Icons.close_rounded : Icons.check_rounded,
                    key: ValueKey(_joined),
                    color: isDark ? kDarkBg : Colors.white, size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _joined ? 'Otkaži prijavu' : 'Ja sam za!',
                    key: ValueKey(_joined),
                    style: TextStyle(
                      color: isDark ? kDarkBg : Colors.white, fontSize: 16,
                      fontWeight: FontWeight.w800, letterSpacing: 0.1,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cloudWidget({double? top, double? bottom, double? left, double? right,
    required double w, required double h}) {
    return Positioned(top: top, bottom: bottom, left: left, right: right,
        child: Container(width: w, height: h,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.50),
              borderRadius: BorderRadius.circular(h / 2),
            )));
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BACK BUTTON (glassmorphism)
// ═══════════════════════════════════════════════════════════════════════════════

class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});
  @override State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 90));
    _s = Tween<double>(begin: 1.0, end: 0.86)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeIn));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(scale: _s,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.28),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16),
          ),
        ),
      ),
    );
  }
}