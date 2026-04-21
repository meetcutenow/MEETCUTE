import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'home_screen.dart' show kPrimaryDark, kPrimaryLight, kSurface;
import 'notifications_screen.dart' show NotificationState, seedStaticNotifications;
import 'theme_state.dart';
import 'auth_state.dart';
import 'organize_meetup.dart' show OrganizeMeetupScreen, BackendEventEdit;

const Color _bordo      = Color(0xFF700D25);
const Color _bordoLight = Color(0xFFF2E8E9);
const Color _bordoDark  = Color(0xFF4A0818);

enum AgeGroup { all, g18_25, g26_35, g36_45, g45plus }
enum GenderGroup { all, female, male }

extension AgeGroupLabel on AgeGroup {
  String get label {
    switch (this) {
      case AgeGroup.all:     return 'Sve';
      case AgeGroup.g18_25:  return '18–25';
      case AgeGroup.g26_35:  return '26–35';
      case AgeGroup.g36_45:  return '36–45';
      case AgeGroup.g45plus: return '45+';
    }
  }
}

extension GenderGroupLabel on GenderGroup {
  String get label {
    switch (this) {
      case GenderGroup.all:    return 'Svi';
      case GenderGroup.female: return 'Žensko';
      case GenderGroup.male:   return 'Muško';
    }
  }
  String get emoji {
    switch (this) {
      case GenderGroup.all:    return '🌍';
      case GenderGroup.female: return '♀️';
      case GenderGroup.male:   return '♂️';
    }
  }
}

class EventData {
  final String id;
  final String? creatorId;
  final String title;
  final String location;
  final String specificLocation;
  final String dateDay;
  final String dateMonth;
  final String time;
  final String description;
  final int attendees;
  final LatLng coordinates;
  final String imagePath;
  final List<String> categories;
  final Color cardColor;
  final bool isUserEvent;
  final bool isCompanyEvent;
  final String? companyName;
  final String? companyLogoUrl;
  final String? companyEmail;
  final int maxAttendees;
  final String? userImagePath;
  final AgeGroup ageGroup;
  final GenderGroup genderGroup;
  final double? ticketPrice;
  final String? ticketCurrency;

  const EventData({
    this.id = '',
    this.creatorId,
    required this.title,
    required this.location,
    this.specificLocation = '',
    required this.dateDay,
    required this.dateMonth,
    this.time = '10:00 – 12:00',
    this.description = '',
    this.attendees = 0,
    this.coordinates = const LatLng(45.8150, 15.9819),
    this.imagePath = '',
    required this.categories,
    this.cardColor = const Color(0xFF6DD5E8),
    this.isUserEvent = false,
    this.isCompanyEvent = false,
    this.companyName,
    this.companyLogoUrl,
    this.companyEmail,
    this.maxAttendees = 0,
    this.userImagePath,
    this.ageGroup = AgeGroup.all,
    this.genderGroup = GenderGroup.all,
    this.ticketPrice,
    this.ticketCurrency,
  });
}

final Map<String, List<EventData>> _userEventsByCity = {};

void addUserEvent(String cityName, EventData event) {
  _userEventsByCity.putIfAbsent(cityName, () => []);
  _userEventsByCity[cityName]!.insert(0, event);
}

final attendanceState = <String, bool>{};

int _effectiveAttendees(EventData e) {
  final joined = attendanceState[e.title];
  if (joined == null) return e.attendees;
  return joined ? e.attendees + 1 : e.attendees;
}
class _City  { final String name; const _City(this.name); }
class _Cat   { final String label; final IconData? icon; final String? emoji;
const _Cat({required this.label, this.icon, this.emoji}); }

const _cities = [ _City('Zagreb'), _City('Split'), _City('Rijeka'), _City('Osijek'), _City('Zadar') ];

const _categories = [
  _Cat(label: 'Kava',     icon: Icons.coffee_outlined),
  _Cat(label: 'Sport',    emoji: '🏃'),
  _Cat(label: 'Druženja', emoji: '🎉'),
  _Cat(label: 'Kultura',  emoji: '🎭'),
  _Cat(label: 'Priroda',  emoji: '🌿'),
  _Cat(label: 'Hrana',    emoji: '🍕'),
];

final _eventsByCity = <int, List<EventData>>{
  0: [
    const EventData(
      id: '', title: 'Running dating', location: 'Jezero Jarun',
      specificLocation: 'Jarun, Aleja Matije Ljubeka, Zagreb',
      dateDay: '14.', dateMonth: '04.', time: '10:00 – 12:00', attendees: 20,
      coordinates: LatLng(45.7785, 15.9148),
      description: 'Idealna prilika za sve ljubitelje trčanja da spoje ugodno s korisnim '
          'i na svježem zraku u prirodi upoznaju novu ekipu.',
      categories: ['Sport'], cardColor: Color(0xFF6DD5E8),
      ageGroup: AgeGroup.g18_25, genderGroup: GenderGroup.all,
    ),
    const EventData(
      id: '', title: 'Jutarnja kava', location: 'Stari Grad, Zagreb',
      specificLocation: 'Caffe Bar Booksa, Martićeva 14d, Zagreb',
      dateDay: '15.', dateMonth: '04.', time: '08:30 – 10:00', attendees: 14,
      coordinates: LatLng(45.8131, 15.9741),
      description: 'Opuštena jutarnja kava u srcu Starog Grada.',
      categories: ['Kava'], cardColor: Color(0xFFFFD166),
      ageGroup: AgeGroup.g26_35, genderGroup: GenderGroup.all,
    ),
    const EventData(
      id: '', title: 'Piknik u parku', location: 'Park Maksimir',
      specificLocation: 'Ulaz 1, Maksimirski perivoj, Zagreb',
      dateDay: '16.', dateMonth: '04.', time: '12:00 – 15:00', attendees: 35,
      coordinates: LatLng(45.8237, 16.0189),
      description: 'Donesite piknik dekicu i grickalice — mi donosimo dobro raspoloženje!',
      categories: ['Druženja', 'Priroda'], cardColor: Color(0xFF95D5B2),
      ageGroup: AgeGroup.all, genderGroup: GenderGroup.female,
    ),
    const EventData(
      id: '', title: 'Večer komedije', location: 'HNK Zagreb',
      specificLocation: 'HNK Zagreb, Trg Republike Hrvatske 15',
      dateDay: '17.', dateMonth: '04.', time: '20:00 – 22:30', attendees: 48,
      coordinates: LatLng(45.8089, 15.9702),
      description: 'Večer smijeha i kulture u HNK-u.',
      categories: ['Kultura'], cardColor: Color(0xFFFFB3C6),
      ageGroup: AgeGroup.g36_45, genderGroup: GenderGroup.all,
    ),
    const EventData(
      id: '', title: 'Street food festival', location: 'Trg bana Jelačića',
      specificLocation: 'Trg bana Josipa Jelačića 1, Zagreb',
      dateDay: '18.', dateMonth: '04.', time: '11:00 – 20:00', attendees: 120,
      coordinates: LatLng(45.8132, 15.9773),
      description: 'Okusi sve što Zagreb ima za ponuditi.',
      categories: ['Hrana', 'Druženja'], cardColor: Color(0xFFFFD166),
      ageGroup: AgeGroup.all, genderGroup: GenderGroup.all,
    ),
  ],
  1: [
    const EventData(
      id: '', title: 'Plaža & kava', location: 'Bačvice, Split',
      specificLocation: 'Plaža Bačvice, Put Firula, Split',
      dateDay: '14.', dateMonth: '04.', time: '09:00 – 11:00', attendees: 18,
      coordinates: LatLng(43.5016, 16.4413),
      description: 'Jutarnja kava uz šum mora na ikoničnim Bačvicama.',
      categories: ['Kava', 'Priroda'], cardColor: Color(0xFF6DD5E8),
      ageGroup: AgeGroup.g18_25, genderGroup: GenderGroup.all,
    ),
    const EventData(
      id: '', title: 'Dioklecijanova noć', location: 'Dioklecijanova palača',
      specificLocation: 'Peristil, Dioklecijanova palača, Split',
      dateDay: '20.', dateMonth: '04.', time: '21:00 – 23:30', attendees: 62,
      coordinates: LatLng(43.5081, 16.4402),
      description: 'Večernja šetnja unutar zidina 1700 godina stare palače.',
      categories: ['Kultura'], cardColor: Color(0xFFFFB3C6),
      ageGroup: AgeGroup.g26_35, genderGroup: GenderGroup.all,
    ),
  ],
  2: [],
  3: [
    const EventData(
      id: '', title: 'Tvrđa fest', location: 'Tvrđa, Osijek',
      specificLocation: 'Trg Svetog Trojstva 6, Tvrđa, Osijek',
      dateDay: '22.', dateMonth: '04.', time: '17:00 – 22:00', attendees: 75,
      coordinates: LatLng(45.5606, 18.6956),
      description: 'Festival hrane, glazbe i kulture u srcu povijesne Tvrđe.',
      categories: ['Kultura', 'Hrana'], cardColor: Color(0xFFFFD166),
      ageGroup: AgeGroup.all, genderGroup: GenderGroup.all,
    ),
  ],
  4: [
    const EventData(
      id: '', title: 'Sunčani sat', location: 'Morske orgulje, Zadar',
      specificLocation: 'Morske orgulje, Obala kralja Petra Krešimira IV, Zadar',
      dateDay: '15.', dateMonth: '04.', time: '18:30 – 20:00', attendees: 30,
      coordinates: LatLng(44.1152, 15.2214),
      description: 'Gledanje zalaska sunca uz zvukove morskih orgulja.',
      categories: ['Priroda', 'Druženja'], cardColor: Color(0xFF95D5B2),
      ageGroup: AgeGroup.g18_25, genderGroup: GenderGroup.female,
    ),
    const EventData(
      id: '', title: 'Vinska večer', location: 'Stari grad, Zadar',
      specificLocation: 'Konoba Stomorica, Stomorica 12, Zadar',
      dateDay: '19.', dateMonth: '04.', time: '19:00 – 22:00', attendees: 25,
      coordinates: LatLng(44.1164, 15.2272),
      description: 'Degustacija dalmatinskih vina u konobi u srcu starog Zadra.',
      categories: ['Hrana'], cardColor: Color(0xFFFFB3C6),
      ageGroup: AgeGroup.g36_45, genderGroup: GenderGroup.all,
    ),
  ],
};

class _FChip {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FChip(this.label, this.selected, this.onTap);
}

class EventsNearbyScreen extends StatefulWidget {
  const EventsNearbyScreen({super.key});
  @override State<EventsNearbyScreen> createState() => _EventsNearbyState();
}

class _EventsNearbyState extends State<EventsNearbyScreen> with TickerProviderStateMixin {

  int _cityIdx        = 0;
  String? _selCat;
  AgeGroup _selAge    = AgeGroup.all;
  GenderGroup _selGen = GenderGroup.all;
  String _search      = '';
  int _page           = 0;
  bool _showCity      = false;
  bool _showFilters   = false;
  bool _backendLoading = false;

  final _searchCtrl = TextEditingController();

  late final AnimationController _entryCtrl;
  late final AnimationController _cityCtrl;
  late final AnimationController _cardCtrl;
  late final AnimationController _filterCtrl;
  late final List<AnimationController> _catCtrls;

  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;
  late final Animation<double> _cityAnim;
  late final Animation<double> _filterAnim;
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

    _cityCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _cityAnim = CurvedAnimation(parent: _cityCtrl, curve: Curves.easeOutCubic);

    _filterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _filterAnim = CurvedAnimation(parent: _filterCtrl, curve: Curves.easeOutCubic);

    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _buildCardAnims(1);
    _cardCtrl.value = 1.0;

    _catCtrls = List.generate(_categories.length,
            (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 200)));

    _entryCtrl.forward();
    ThemeState.instance.addListener(_onTheme);

    _loadFromBackend();
  }

  Future<void> _loadFromBackend() async {
    setState(() => _backendLoading = true);
    try {
      final headers = <String, String>{};
      if (AuthState.instance.isLoggedIn) {
        headers['Authorization'] = 'Bearer ${AuthState.instance.accessToken}';
      }
      final resp = await http.get(
        Uri.parse('http://localhost:8080/api/events'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final list = jsonDecode(utf8.decode(resp.bodyBytes))['data'] as List;

        // Očisti stare backend evente
        for (final c in _cities) {
          _userEventsByCity[c.name]?.removeWhere((e) => e.id.isNotEmpty);
        }

        for (final e in list) {
          final isUserEvent    = e['isUserEvent']    == true;
          final isCompanyEvent = e['isCompanyEvent'] == true;

          // ── KLJUČNI FIX: prikaži i user i company evente ──────────────────
          if (!isUserEvent && !isCompanyEvent) continue;

          final city = e['city'] as String? ?? '';
          if (!_cities.any((c) => c.name == city)) continue;

          final defaultHex = isCompanyEvent ? '700D25' : '6DD5E8';
          final cardHexRaw = (e['cardColorHex'] as String? ?? '#$defaultHex').replaceAll('#', '');
          Color cardColor;
          try {
            cardColor = Color(int.parse('FF$cardHexRaw', radix: 16));
          } catch (_) {
            cardColor = isCompanyEvent ? const Color(0xFF700D25) : const Color(0xFF6DD5E8);
          }

          final dateStr = e['eventDate'] as String? ?? '';
          String dateDay = '', dateMonth = '';
          if (dateStr.length == 10) {
            dateDay   = '${dateStr.substring(8, 10)}.';
            dateMonth = '${dateStr.substring(5, 7)}.';
          }

          final timeStart = e['timeStart'] as String? ?? '';
          final timeEnd   = e['timeEnd']   as String? ?? '';
          final timeStr   = timeStart.isNotEmpty && timeEnd.isNotEmpty
              ? '${timeStart.substring(0, 5)} – ${timeEnd.substring(0, 5)}'
              : timeStart.isNotEmpty ? timeStart.substring(0, 5) : '00:00';

          AgeGroup ageGroup = AgeGroup.all;
          final ag = e['ageGroup'] as String? ?? 'all';
          for (final v in AgeGroup.values) {
            if (v.name == ag) { ageGroup = v; break; }
          }
          GenderGroup genderGroup = GenderGroup.all;
          final gg = e['genderGroup'] as String? ?? 'all';
          for (final v in GenderGroup.values) {
            if (v.name == gg) { genderGroup = v; break; }
          }

          final event = EventData(
            id:               e['id'] as String? ?? '',
            creatorId:        e['creatorId'] as String?,
            title:            e['title'] as String? ?? '',
            location:         city,
            specificLocation: e['specificLocation'] as String? ?? '',
            dateDay:          dateDay,
            dateMonth:        dateMonth,
            time:             timeStr,
            description:      e['description'] as String? ?? '',
            attendees:        (e['attendeeCount'] as int?) ?? 0,
            coordinates:      LatLng(
              (e['latitude']  as num?)?.toDouble() ?? 45.8150,
              (e['longitude'] as num?)?.toDouble() ?? 15.9819,
            ),
            categories:       [e['category'] as String? ?? ''],
            cardColor:        cardColor,
            isUserEvent:      isUserEvent,
            isCompanyEvent:   isCompanyEvent,
            companyName:      e['companyName'] as String?,
            companyLogoUrl:   e['companyLogoUrl'] as String?,
            companyEmail:     e['companyEmail'] as String?,
            maxAttendees:     (e['maxAttendees'] as int?) ?? 0,
            ageGroup:         ageGroup,
            genderGroup:      genderGroup,
            ticketPrice:      (e['ticketPrice'] as num?)?.toDouble(),
            ticketCurrency:   e['ticketCurrency'] as String?,
          );

          _userEventsByCity.putIfAbsent(city, () => []);
          _userEventsByCity[city]!.add(event);

          if (e['isAttending'] == true) {
            attendanceState[event.title] = true;
          }
        }

        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Backend load error: $e');
    }
    if (mounted) setState(() => _backendLoading = false);
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
    _entryCtrl.dispose(); _cityCtrl.dispose(); _filterCtrl.dispose(); _cardCtrl.dispose();
    for (final c in _catCtrls) c.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<EventData> get _cityEvents {
    final name = _cities[_cityIdx].name;
    final stat = _eventsByCity[_cityIdx] ?? [];
    final user = _userEventsByCity[name] ?? [];
    return [...user, ...stat];
  }

  List<EventData> get _filtered {
    return _cityEvents.where((e) {
      final matchCat = _selCat == null || e.categories.contains(_selCat);
      final matchAge = _selAge == AgeGroup.all || e.ageGroup == _selAge || e.ageGroup == AgeGroup.all;
      final matchGen = _selGen == GenderGroup.all || e.genderGroup == _selGen || e.genderGroup == GenderGroup.all;
      final q = _search.toLowerCase();
      final matchSearch = q.isEmpty || e.title.toLowerCase().contains(q) || e.location.toLowerCase().contains(q);
      return matchCat && matchAge && matchGen && matchSearch;
    }).toList();
  }

  bool get _hasFilters => _selAge != AgeGroup.all || _selGen != GenderGroup.all;

  void _swap(int dir) {
    _buildCardAnims(dir);
    _cardCtrl.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  void _next() {
    final ev = _filtered;
    if (_page >= ev.length - 1) return;
    setState(() => _page++);
    _swap(1);
  }

  void _prev() {
    if (_page <= 0) return;
    setState(() => _page--);
    _swap(-1);
  }

  void _toggleCity() {
    HapticFeedback.selectionClick();
    setState(() => _showCity = !_showCity);
    _showCity ? _cityCtrl.forward() : _cityCtrl.reverse();
  }

  void _toggleFilters() {
    HapticFeedback.selectionClick();
    setState(() => _showFilters = !_showFilters);
    _showFilters ? _filterCtrl.forward() : _filterCtrl.reverse();
  }

  void _selectCity(int i) {
    if (i == _cityIdx) { _toggleCity(); return; }
    HapticFeedback.selectionClick();
    setState(() { _cityIdx = i; _showCity = false; _page = 0; _selCat = null; });
    _cityCtrl.reverse();
    _buildCardAnims(1); _cardCtrl.forward(from: 0);
  }

  void _openDetail(EventData e) {
    HapticFeedback.mediumImpact();
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => EventDetailScreen(event: e),
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeIn),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 380),
    )).then((result) {
      if (result == 'deleted' || result == 'updated') {
        _loadFromBackend();
      } else {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq    = MediaQuery.of(context);
    final isDark = ThemeState.instance.isDark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      color: isDark ? kDarkBg : Colors.white,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FadeTransition(
          opacity: _entryFade,
          child: SlideTransition(
            position: _entrySlide,
            child: Column(children: [
              _header(mq),
              Expanded(
                child: Stack(children: [
                  Column(children: [
                    const SizedBox(height: 14),
                    _locationBar(),
                    const SizedBox(height: 10),
                    _catChips(),
                    const SizedBox(height: 6),
                    _filterPanel(),
                    Expanded(child: _backendLoading
                        ? Center(child: CircularProgressIndicator(color: _bordo.withOpacity(0.5), strokeWidth: 2))
                        : _cardArea()),
                    _searchBar(mq),
                  ]),
                  if (_showCity) _cityOverlay(),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _header(MediaQueryData mq) {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? kDarkPrimary : _bordo;
    final cardBg  = isDark ? kDarkCard : Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 380), color: cardBg,
      padding: EdgeInsets.only(top: mq.padding.top + 10, left: 6, right: 12, bottom: 6),
      child: Row(children: [
        IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primary, size: 20),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 2),
        Expanded(child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(color: primary, fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          child: const Text('Pronađi događanja'),
        )),
        GestureDetector(
          onTap: _toggleFilters,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 38, height: 38,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: _hasFilters ? primary : primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _hasFilters ? primary : primary.withOpacity(0.12)),
            ),
            child: Stack(alignment: Alignment.center, children: [
              Icon(Icons.tune_rounded,
                  color: _hasFilters ? Colors.white : primary, size: 18),
              if (_hasFilters)
                Positioned(top: 6, right: 6,
                    child: Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    )),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _locationBar() {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? kDarkPrimary : _bordo;
    final inBg    = isDark ? kDarkCard : const Color(0xFFF4EDED);
    final inBdr   = isDark ? kPrimaryLight.withOpacity(0.15) : const Color(0xFFE8D5D8);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GestureDetector(
        onTap: _toggleCity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: _showCity ? primary : inBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _showCity ? primary : inBdr, width: 1.5),
            boxShadow: _showCity ? [BoxShadow(color: primary.withOpacity(0.20), blurRadius: 14, offset: const Offset(0,4))] : [],
          ),
          child: Row(children: [
            Icon(Icons.location_on_rounded,
                color: _showCity ? (isDark ? kDarkBg : Colors.white) : primary, size: 18),
            const SizedBox(width: 9),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('Tvoja lokacija', style: TextStyle(
                  color: (_showCity ? (isDark ? kDarkBg : Colors.white) : primary).withOpacity(0.55),
                  fontSize: 10.5, fontWeight: FontWeight.w500)),
              const SizedBox(height: 1),
              Text(_cities[_cityIdx].name, style: TextStyle(
                  color: _showCity ? (isDark ? kDarkBg : Colors.white) : primary,
                  fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
            const Spacer(),
            AnimatedRotation(
                turns: _showCity ? 0.5 : 0, duration: const Duration(milliseconds: 240), curve: Curves.easeOutCubic,
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    color: (_showCity ? (isDark ? kDarkBg : Colors.white) : primary).withOpacity(0.70), size: 22)),
          ]),
        ),
      ),
    );
  }

  Widget _cityOverlay() {
    final isDark  = ThemeState.instance.isDark;
    final cardBg  = isDark ? kDarkCard : Colors.white;
    final border  = isDark ? kPrimaryLight.withOpacity(0.15) : const Color(0xFFE8D5D8);
    final primary = isDark ? kDarkPrimary : _bordo;
    return Positioned(
      top: 14 + 62 + 4, left: 18, right: 18,
      child: FadeTransition(
        opacity: _cityAnim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -0.04), end: Offset.zero).animate(_cityAnim),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: cardBg, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border, width: 1.5),
                boxShadow: [BoxShadow(color: primary.withOpacity(0.13), blurRadius: 22, offset: const Offset(0, 8))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(mainAxisSize: MainAxisSize.min,
                    children: List.generate(_cities.length, (i) => _CityTile(
                      name: _cities[i].name, isSelected: i == _cityIdx,
                      onTap: () => _selectCity(i), showDivider: i < _cities.length - 1,
                    ))),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _catChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final sel = _selCat == cat.label;
          final isDark  = ThemeState.instance.isDark;
          final primary = isDark ? kDarkPrimary : _bordo;
          final chipBg  = isDark ? kDarkCard : Colors.white;
          final chipBdr = isDark ? kDarkCardEl : const Color(0xFFDDC8CB);
          final fg      = isDark ? kDarkBg : Colors.white;
          return GestureDetector(
            onTapDown: (_) => _catCtrls[i].forward(),
            onTapUp: (_) {
              _catCtrls[i].reverse();
              HapticFeedback.selectionClick();
              setState(() { _selCat = sel ? null : cat.label; _page = 0; });
              if (!sel) { _buildCardAnims(1); _cardCtrl.forward(from: 0); }
            },
            onTapCancel: () => _catCtrls[i].reverse(),
            child: AnimatedBuilder(
              animation: _catCtrls[i],
              builder: (_, __) => Transform.scale(
                scale: 1.0 - _catCtrls[i].value * 0.07,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? primary : chipBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: sel ? primary : chipBdr, width: 1.2),
                    boxShadow: sel ? [BoxShadow(color: primary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0,3))] : [],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (cat.icon != null) ...[Icon(cat.icon, size: 13, color: sel ? fg : primary), const SizedBox(width: 4)]
                    else if (cat.emoji != null) ...[Text(cat.emoji!, style: const TextStyle(fontSize: 12)), const SizedBox(width: 4)],
                    Text(cat.label, style: TextStyle(color: sel ? fg : primary, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _filterPanel() {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? kDarkPrimary : _bordo;
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      clipBehavior: Clip.hardEdge,
      child: _showFilters
          ? Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _fChipRow('Dob:', AgeGroup.values.map((g) =>
              _FChip(g.label, g == _selAge, () => setState(() { _selAge = g; _page = 0; HapticFeedback.selectionClick(); }))).toList()),
          const SizedBox(height: 5),
          _fChipRow('Spol:', GenderGroup.values.map((g) =>
              _FChip('${g.emoji} ${g.label}', g == _selGen, () => setState(() { _selGen = g; _page = 0; HapticFeedback.selectionClick(); }))).toList()),
          const SizedBox(height: 4),
        ]),
      )
          : const SizedBox(width: double.infinity),
    );
  }

  Widget _fChipRow(String label, List<_FChip> chips) {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? kDarkPrimary : _bordo;
    return Row(children: [
      Text(label, style: TextStyle(color: primary.withOpacity(0.55), fontSize: 11.5, fontWeight: FontWeight.w600)),
      const SizedBox(width: 8),
      Expanded(child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips.map((c) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: c.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: c.selected ? primary : (isDark ? kDarkCard : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.selected ? primary : primary.withOpacity(0.20), width: 1.2),
              ),
              child: Text(c.label, style: TextStyle(
                  color: c.selected ? Colors.white : primary, fontSize: 11.5, fontWeight: FontWeight.w600)),
            ),
          ),
        )).toList()),
      )),
    ]);
  }

  Widget _cardArea() {
    final ev     = _filtered;
    final isDark = ThemeState.instance.isDark;
    final primary = isDark ? kDarkPrimary : _bordo;
    final emptyBg = isDark ? kDarkCardEl : _bordoLight;

    if (ev.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 72, height: 72,
            decoration: BoxDecoration(color: emptyBg, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: primary.withOpacity(0.12), blurRadius: 20, offset: const Offset(0,6))]),
            child: Icon(_cityEvents.isEmpty ? Icons.location_off_rounded : Icons.search_off_rounded,
                color: primary.withOpacity(0.55), size: 32)),
        const SizedBox(height: 16),
        Text(_cityEvents.isEmpty ? 'Nema događanja\nu odabranom gradu!' : 'Nema rezultata',
            textAlign: TextAlign.center,
            style: TextStyle(color: primary.withOpacity(0.65), fontSize: 15, fontWeight: FontWeight.w600, height: 1.4)),
        if (_hasFilters) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() { _selAge = AgeGroup.all; _selGen = GenderGroup.all; _page = 0; }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(14)),
              child: const Text('Ukloni filtre', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ]));
    }

    final page = _page.clamp(0, ev.length - 1);
    return LayoutBuilder(builder: (_, box) {
      final cardW = box.maxWidth - 40;
      final cardH = (box.maxHeight * 0.88).clamp(0.0, 440.0);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -200) _next();
          if (v > 200)  _prev();
        },
        child: Center(child: SizedBox(width: cardW, height: box.maxHeight,
          child: Stack(alignment: Alignment.topCenter, children: [
            if (ev.length > page + 2)
              Positioned(top: 16, left: 12, right: 12, height: cardH,
                  child: Container(decoration: BoxDecoration(
                      color: ev[(page+2).clamp(0,ev.length-1)].cardColor.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(26)))),
            if (ev.length > page + 1)
              Positioned(top: 8, left: 6, right: 6, height: cardH,
                  child: Container(decoration: BoxDecoration(
                      color: ev[(page+1).clamp(0,ev.length-1)].cardColor.withOpacity(0.70),
                      borderRadius: BorderRadius.circular(26)))),
            Positioned(top: 0, left: 0, right: 0, height: cardH,
                child: AnimatedBuilder(
                  animation: _cardCtrl,
                  builder: (_, child) => FadeTransition(opacity: _cardFade,
                      child: SlideTransition(position: _cardSlide,
                          child: ScaleTransition(scale: _cardScale, child: child))),
                  child: GestureDetector(
                      onTap: () => _openDetail(ev[page]),
                      child: _EventCard(key: ValueKey('$page-$_cityIdx'), event: ev[page])),
                )),
            if (ev.length > 1)
              Positioned(bottom: 6, child: Row(mainAxisSize: MainAxisSize.min,
                  children: List.generate(ev.length.clamp(0, 6), (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == page ? 16 : 5, height: 5,
                      decoration: BoxDecoration(
                          color: i == page ? _bordo : _bordo.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(3)))))),
          ]),
        )),
      );
    });
  }

  Widget _searchBar(MediaQueryData mq) {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? kDarkPrimary : _bordo;
    final bg      = isDark ? kDarkCard : const Color(0xFFF0E8EA);
    final border  = isDark ? kPrimaryLight.withOpacity(0.15) : const Color(0xFFDDC8CB);
    return Padding(
      padding: EdgeInsets.fromLTRB(54, 6, 54, mq.padding.bottom + 10),
      child: Container(
        height: 40,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 1)),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() { _search = v; _page = 0; }),
          style: TextStyle(color: primary, fontSize: 13),
          decoration: InputDecoration(
              hintText: 'Pretraži događanja',
              hintStyle: TextStyle(color: primary.withOpacity(0.35), fontSize: 13),
              suffixIcon: Icon(Icons.search_rounded, color: primary.withOpacity(0.45), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11), isDense: true),
        ),
      ),
    );
  }
}

class _EventCard extends StatefulWidget {
  final EventData event;
  const _EventCard({super.key, required this.event});
  @override State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> with SingleTickerProviderStateMixin {
  late final AnimationController _shim;
  @override void initState() { super.initState(); _shim = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(); }
  @override void dispose() { _shim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final e      = widget.event;
    final c      = e.cardColor;
    final isUser    = e.isUserEvent;
    final isCompany = e.isCompanyEvent;
    final hasImg = e.userImagePath != null && e.userImagePath!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(children: [
        Positioned.fill(
          child: hasImg
              ? Image.file(File(e.userImagePath!), fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: c))
              : e.imagePath.isNotEmpty
              ? Image.asset(e.imagePath, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: c))
              : Container(color: c),
        ),
        Positioned.fill(child: AnimatedBuilder(animation: _shim, builder: (_, __) => Positioned(
            left: -80 + _shim.value * (MediaQuery.of(context).size.width + 160), top: 0, bottom: 0,
            child: Container(width: 80, decoration: BoxDecoration(gradient: LinearGradient(colors: [
              Colors.white.withOpacity(0), Colors.white.withOpacity(0.09), Colors.white.withOpacity(0)])))))),
        _cloud(top: 18, left: 14, w: 52, h: 24),
        _cloud(top: 8, right: 46, w: 38, h: 18),
        _cloud(top: 44, right: 10, w: 28, h: 14),
        // Badge za company event
        if (isCompany)
          Positioned(top: 12, left: 12,
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.90), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.business_rounded, color: _bordo, size: 12), const SizedBox(width: 4),
                    Text(e.companyName ?? 'Tvrtka', style: const TextStyle(color: _bordo, fontSize: 11, fontWeight: FontWeight.w700)),
                  ]))),
        // Badge za user event
        if (isUser && !isCompany)
          Positioned(top: 12, left: 12,
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: _bordo.withOpacity(0.85), borderRadius: BorderRadius.circular(20)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.people_rounded, color: Colors.white, size: 12), SizedBox(width: 4),
                    Text('Event korisnika', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ]))),
        Positioned(bottom: 90, right: 12,
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.28), borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.touch_app_rounded, color: Colors.white, size: 13), SizedBox(width: 4),
                  Text('detalji', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ]))),
        // Ticket price badge
        if (e.ticketPrice != null && e.ticketPrice! > 0)
          Positioned(bottom: 90, left: 12,
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.50), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 12), const SizedBox(width: 4),
                    Text('${e.ticketPrice!.toStringAsFixed(0)} ${e.ticketCurrency ?? 'EUR'}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ]))),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            decoration: BoxDecoration(
              color: _bordo,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(e.title, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.location_on_rounded, color: Colors.white.withOpacity(0.55), size: 11), const SizedBox(width: 2),
                  Text(e.location, style: TextStyle(color: Colors.white.withOpacity(0.62), fontSize: 12)),
                ]),
              ])),
              const SizedBox(width: 8),
              Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(e.dateDay, style: const TextStyle(color: _bordo, fontSize: 17, fontWeight: FontWeight.w900, height: 1.0)),
                    Text(e.dateMonth, style: const TextStyle(color: _bordo, fontSize: 17, fontWeight: FontWeight.w900, height: 1.0)),
                  ])),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _cloud({double? top, double? bottom, double? left, double? right, required double w, required double h}) =>
      Positioned(top: top, bottom: bottom, left: left, right: right,
          child: Container(width: w, height: h, decoration: BoxDecoration(color: Colors.white.withOpacity(0.52), borderRadius: BorderRadius.circular(h/2))));
}

class _CityTile extends StatefulWidget {
  final String name; final bool isSelected; final VoidCallback onTap; final bool showDivider;
  const _CityTile({required this.name, required this.isSelected, required this.onTap, required this.showDivider});
  @override State<_CityTile> createState() => _CityTileState();
}

class _CityTileState extends State<_CityTile> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 80)); }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark  = ThemeState.instance.isDark;
    final primary = isDark ? kDarkPrimary : _bordo;
    final tileBg  = isDark ? kDarkCard : Colors.white;
    final hoverBg = isDark ? kDarkCardEl : const Color(0xFFF4EDED);
    final divCol  = isDark ? kDarkCardEl : const Color(0xFFE8D5D8);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTapDown: (_) => _c.forward(),
        onTapUp: (_) { _c.reverse(); widget.onTap(); },
        onTapCancel: () => _c.reverse(),
        child: AnimatedBuilder(animation: _c, builder: (_, __) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: widget.isSelected ? primary.withOpacity(0.08) : Color.lerp(tileBg, hoverBg, _c.value),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: Row(children: [
            AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(color: primary, fontSize: 14.5, fontWeight: widget.isSelected ? FontWeight.w800 : FontWeight.w500),
                child: Text(widget.name)),
            const Spacer(),
            if (widget.isSelected) Container(width: 20, height: 20,
                decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                child: Icon(Icons.check_rounded, color: isDark ? kDarkBg : Colors.white, size: 13)),
          ]),
        )),
      ),
      if (widget.showDivider) Divider(height: 1, thickness: 0.5, color: divCol, indent: 18, endIndent: 18),
    ]);
  }
}

class EventDetailScreen extends StatefulWidget {
  final EventData event;
  const EventDetailScreen({super.key, required this.event});
  @override State<EventDetailScreen> createState() => _EventDetailState();
}

class _EventDetailState extends State<EventDetailScreen> with TickerProviderStateMixin {
  bool get _joined => attendanceState[widget.event.title] ?? false;

  late final AnimationController _entryCtrl, _heroCtrl, _btnCtrl, _countCtrl, _mapCtrl;
  late final Animation<double> _entryFade, _heroScale, _btnScale, _countAnim;
  late final Animation<Offset> _contentSlide;
  bool _mapExpanded = false;
  late final MapController _mapController;

  bool get _isMyEvent =>
      widget.event.isUserEvent &&
          AuthState.instance.isLoggedIn &&
          widget.event.creatorId != null &&
          widget.event.creatorId == AuthState.instance.userId;

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
    _entryCtrl.forward(); _heroCtrl.forward();
  }

  void _onTheme() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeState.instance.removeListener(_onTheme);
    _entryCtrl.dispose(); _heroCtrl.dispose(); _btnCtrl.dispose(); _countCtrl.dispose(); _mapCtrl.dispose();
    super.dispose();
  }

  void _toggleJoin() async {
    if (widget.event.isCompanyEvent) {
      // Company eventi — prijava putem backend API-a
      if (!AuthState.instance.isLoggedIn) {
        _showSnack('Moraš biti prijavljen/a da se prijavljuješ na evente.');
        return;
      }
    }
    if (!_joined && widget.event.isUserEvent && widget.event.maxAttendees > 0) {
      if (_effectiveAttendees(widget.event) >= widget.event.maxAttendees) { _showFull(); return; }
    }
    HapticFeedback.mediumImpact();
    await _btnCtrl.forward(); await _btnCtrl.reverse();

    // Pokušaj backend toggle ako event ima ID
    if (widget.event.id.isNotEmpty && AuthState.instance.isLoggedIn) {
      try {
        final resp = await http.post(
          Uri.parse('http://localhost:8080/api/events/${widget.event.id}/attend'),
          headers: {'Authorization': 'Bearer ${AuthState.instance.accessToken}'},
        ).timeout(const Duration(seconds: 8));
        if (resp.statusCode != 200) {
          final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
          _showSnack(decoded['message'] ?? 'Greška pri prijavi.');
          return;
        }
      } catch (_) {
        // Nastavi lokalno ako backend nije dostupan
      }
    }

    final was = _joined;
    setState(() { attendanceState[widget.event.title] = !was; });
    _countCtrl.forward(from: 0);
    NotificationState.instance.onAttendanceChanged(widget.event.title, widget.event.location, widget.event.cardColor, !was);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: _bordo, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showFull() {
    HapticFeedback.mediumImpact();
    showDialog(context: context, builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0), duration: const Duration(milliseconds: 380), curve: Curves.easeOutBack,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: _bordo.withOpacity(0.20), blurRadius: 32, offset: const Offset(0,12))]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 60, height: 60, decoration: BoxDecoration(color: _bordoLight, shape: BoxShape.circle),
                child: const Icon(Icons.group_off_rounded, color: _bordo, size: 28)),
            const SizedBox(height: 16),
            const Text('Event je popunjen!', style: TextStyle(color: _bordo, fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Dostignut je maksimalan broj sudionika (${widget.event.maxAttendees}).',
                textAlign: TextAlign.center, style: TextStyle(color: _bordo.withOpacity(0.55), fontSize: 13.5, height: 1.5)),
            const SizedBox(height: 20),
            GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(height: 46, decoration: BoxDecoration(color: _bordo, borderRadius: BorderRadius.circular(23)),
                    child: const Center(child: Text('Razumijem', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))))),
          ]),
        ),
      ),
    ));
  }

  void _toggleMap() {
    HapticFeedback.selectionClick();
    setState(() => _mapExpanded = !_mapExpanded);
    _mapExpanded ? _mapCtrl.forward() : _mapCtrl.reverse();
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1.0),
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 36, offset: const Offset(0, 14))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 56, height: 56,
                  decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 28)),
              const SizedBox(height: 14),
              const Text('Obriši događaj?',
                  style: TextStyle(color: kPrimaryDark, fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 8),
              Text('Ova radnja se ne može poništiti.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kPrimaryDark.withOpacity(0.55), fontSize: 13.5)),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: kPrimaryDark.withOpacity(0.20))),
                  ),
                  child: Text('Odustani', style: TextStyle(color: kPrimaryDark.withOpacity(0.65), fontSize: 14)),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 13), elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Obriši', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                )),
              ]),
            ]),
          ),
        ),
      ),
    );

    if (confirmed != true) return;
    HapticFeedback.mediumImpact();

    try {
      final resp = await http.delete(
        Uri.parse('http://localhost:8080/api/events/${widget.event.id}'),
        headers: {'Authorization': 'Bearer ${AuthState.instance.accessToken}'},
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Događaj obrisan.', style: TextStyle(color: Colors.white)),
          backgroundColor: kPrimaryDark, behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context, 'deleted');
      } else {
        final decoded = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        _showSnack(decoded['message'] ?? 'Greška pri brisanju.');
      }
    } catch (_) {
      if (mounted) _showSnack('Ne mogu se spojiti na server.');
    }
  }

  Future<void> _editEvent() async {
    final e = widget.event;
    String eventDate = '';
    if (e.id.isNotEmpty) {
      try {
        final headers = <String, String>{};
        if (AuthState.instance.isLoggedIn) {
          headers['Authorization'] = 'Bearer ${AuthState.instance.accessToken}';
        }
        final resp = await http.get(
          Uri.parse('http://localhost:8080/api/events/${e.id}'),
          headers: headers,
        ).timeout(const Duration(seconds: 8));
        if (resp.statusCode == 200) {
          final data = jsonDecode(utf8.decode(resp.bodyBytes))['data'] as Map<String, dynamic>;
          eventDate = data['eventDate'] as String? ?? '';
        }
      } catch (_) {}
    }

    if (eventDate.isEmpty) {
      final day   = e.dateDay.replaceAll('.', '').padLeft(2, '0');
      final month = e.dateMonth.replaceAll('.', '').padLeft(2, '0');
      final year  = DateTime.now().year.toString();
      eventDate = '$year-$month-$day';
    }

    String? timeStart, timeEnd;
    if (e.time.contains('–')) {
      final parts = e.time.split('–');
      timeStart = parts[0].trim();
      timeEnd   = parts[1].trim();
    } else {
      timeStart = e.time.trim();
    }

    final editData = BackendEventEdit(
      id:               e.id,
      title:            e.title,
      description:      e.description.isNotEmpty ? e.description : null,
      city:             e.location,
      specificLocation: e.specificLocation.isNotEmpty ? e.specificLocation : null,
      eventDate:        eventDate,
      timeStart:        timeStart,
      timeEnd:          timeEnd,
      category:         e.categories.isNotEmpty ? e.categories.first : '',
      ageGroup:         e.ageGroup.name,
      genderGroup:      e.genderGroup.name,
      maxAttendees:     e.maxAttendees > 0 ? e.maxAttendees : null,
      cardColorHex:     '#${e.cardColor.value.toRadixString(16).substring(2).toUpperCase()}',
      latitude:         e.coordinates.latitude,
      longitude:        e.coordinates.longitude,
    );

    if (!mounted) return;
    final result = await Navigator.push<bool>(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => OrganizeMeetupScreen(editEvent: editData),
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 400),
    ));

    if (result == true && mounted) {
      Navigator.pop(context, 'updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq     = MediaQuery.of(context);
    final e      = widget.event;
    final c      = e.cardColor;
    final att    = _effectiveAttendees(e);
    final isDark = ThemeState.instance.isDark;
    final bgCol  = isDark ? kDarkBg : Colors.white;
    final primary = isDark ? kDarkPrimary : _bordoDark;
    final hasImg = e.userImagePath != null && e.userImagePath!.isNotEmpty;
    final locDisplay = e.specificLocation.isNotEmpty ? e.specificLocation : e.location;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 380), color: bgCol,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: ScaleTransition(scale: _heroScale,
                  child: Container(height: mq.size.height * 0.42, color: c,
                      child: Stack(fit: StackFit.expand, children: [
                        if (hasImg) Image.file(File(e.userImagePath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: c))
                        else if (e.imagePath.isNotEmpty) Image.asset(e.imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: c))
                        else Container(color: c),
                        Positioned(bottom: 0, left: 0, right: 0, height: 100,
                            child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.18)])))),
                        // Badge za user event - kreator
                        if (e.isUserEvent && _isMyEvent) Positioned(bottom: 16, left: 20,
                            child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: _bordo, borderRadius: BorderRadius.circular(20),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10)]),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.star_rounded, color: Colors.white, size: 14), const SizedBox(width: 5),
                                  Text(e.maxAttendees > 0 ? 'Tvoj event · max ${e.maxAttendees} ljudi' : 'Tvoj osobni event',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                ]))),
                        // Badge za user event - tuđi
                        if (e.isUserEvent && !_isMyEvent) Positioned(bottom: 16, left: 20,
                            child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: _bordo.withOpacity(0.85), borderRadius: BorderRadius.circular(20),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.20), blurRadius: 10)]),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.people_rounded, color: Colors.white, size: 14), const SizedBox(width: 5),
                                  Text(e.maxAttendees > 0 ? 'Event korisnika · max ${e.maxAttendees} mjesta' : 'Event korisnika',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                ]))),
                        _cw(top: 28, left: 18, w: 70, h: 32), _cw(top: 14, right: 60, w: 50, h: 24),
                        _cw(top: 60, right: 16, w: 36, h: 18),
                      ])))),

              SliverToBoxAdapter(child: FadeTransition(opacity: _entryFade,
                  child: SlideTransition(position: _contentSlide,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 22, 20, mq.padding.bottom + 100),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              AnimatedDefaultTextStyle(duration: const Duration(milliseconds: 300),
                                  style: TextStyle(color: isDark ? kDarkText : Colors.black87,
                                      fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.8, height: 1.1),
                                  child: Text(e.title)),
                              const SizedBox(height: 6),
                              AnimatedBuilder(animation: _countAnim, builder: (_, __) => Row(children: [
                                Transform.scale(scale: 1.0 + _countAnim.value * 0.12,
                                    child: Text('$att', style: TextStyle(color: primary, fontSize: 16, fontWeight: FontWeight.w800))),
                                Text(' ljudi se pridružilo',
                                    style: TextStyle(color: isDark ? kDarkTextSub : Colors.black.withOpacity(0.55), fontSize: 14)),
                              ])),
                            ])),
                            const SizedBox(width: 12),
                            Container(width: 68, height: 68,
                                decoration: BoxDecoration(color: _bordo, borderRadius: BorderRadius.circular(16),
                                    boxShadow: [BoxShadow(color: _bordo.withOpacity(0.30), blurRadius: 14, offset: const Offset(0,5))]),
                                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Text(e.dateDay, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.0)),
                                  Text(e.dateMonth, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.0)),
                                ])),
                          ]),

                          const SizedBox(height: 20),

                          GestureDetector(onTap: _toggleMap,
                              child: AnimatedContainer(duration: const Duration(milliseconds: 340), curve: Curves.easeOutCubic,
                                decoration: BoxDecoration(
                                    color: isDark ? kDarkCard : _bordoLight,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: primary.withOpacity(0.12), width: 1),
                                    boxShadow: [BoxShadow(color: primary.withOpacity(0.08), blurRadius: 16, offset: const Offset(0,4))]),
                                child: Column(children: [
                                  Padding(padding: const EdgeInsets.all(16),
                                      child: Row(children: [
                                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Row(children: [
                                            Icon(Icons.access_time_rounded, color: primary.withOpacity(0.70), size: 15), const SizedBox(width: 6),
                                            Text(e.time, style: TextStyle(color: isDark ? kDarkText : _bordoDark, fontSize: 17, fontWeight: FontWeight.w800)),
                                          ]),
                                          const SizedBox(height: 6),
                                          Row(children: [
                                            Icon(Icons.location_on_rounded, color: primary.withOpacity(0.70), size: 15), const SizedBox(width: 6),
                                            Expanded(child: Text(locDisplay,
                                                style: TextStyle(color: isDark ? kDarkText : _bordoDark, fontSize: 14, fontWeight: FontWeight.w700))),
                                          ]),
                                        ])),
                                        const SizedBox(width: 12),
                                        ClipRRect(borderRadius: BorderRadius.circular(12),
                                            child: SizedBox(width: 90, height: 70,
                                                child: Stack(children: [
                                                  FlutterMap(
                                                    mapController: _mapController,
                                                    options: MapOptions(initialCenter: e.coordinates, initialZoom: 14.5,
                                                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
                                                    children: [
                                                      TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                                                          subdomains: const ['a','b','c','d'], userAgentPackageName: 'com.meetcute.app'),
                                                      MarkerLayer(markers: [Marker(point: e.coordinates, width: 22, height: 22,
                                                          child: Container(decoration: BoxDecoration(color: _bordo, shape: BoxShape.circle,
                                                              border: Border.all(color: Colors.white, width: 2),
                                                              boxShadow: [BoxShadow(color: _bordo.withOpacity(0.5), blurRadius: 6)])))]),
                                                    ],
                                                  ),
                                                  Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(
                                                      colors: [Colors.transparent, Colors.black.withOpacity(0.12)],
                                                      begin: Alignment.topCenter, end: Alignment.bottomCenter)))),
                                                  Positioned(bottom: 4, right: 4, child: Container(
                                                      padding: const EdgeInsets.all(3),
                                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(6)),
                                                      child: Icon(_mapExpanded ? Icons.zoom_in_map_rounded : Icons.zoom_out_map_rounded, size: 12, color: _bordo))),
                                                ]))),
                                      ])),
                                  AnimatedBuilder(animation: _mapCtrl, builder: (_, __) {
                                    final h = _mapCtrl.value * 220.0;
                                    if (h < 1) return const SizedBox.shrink();
                                    return ClipRRect(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                                        child: SizedBox(height: h, child: FlutterMap(
                                          options: MapOptions(initialCenter: e.coordinates, initialZoom: 15.0,
                                              interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag)),
                                          children: [
                                            TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                                                subdomains: const ['a','b','c','d'], userAgentPackageName: 'com.meetcute.app'),
                                            MarkerLayer(markers: [Marker(point: e.coordinates, width: 36, height: 36,
                                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                                  Container(width: 26, height: 26, decoration: BoxDecoration(color: _bordo, shape: BoxShape.circle,
                                                      border: Border.all(color: Colors.white, width: 3),
                                                      boxShadow: [BoxShadow(color: _bordo.withOpacity(0.5), blurRadius: 8)])),
                                                  Container(width: 3, height: 7, decoration: BoxDecoration(color: _bordo, borderRadius: BorderRadius.circular(2))),
                                                ]))]),
                                          ],
                                        )));
                                  }),
                                ]),
                              )),

                          const SizedBox(height: 24),

                          // ── Company info kartica ───────────────────────────
                          if (e.isCompanyEvent && e.companyName != null) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2A1A1E) : _bordoLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? const Color(0xFFBF8997) : _bordo.withOpacity(0.20),
                                  width: isDark ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                // ── Gornji red: logo + naziv + cijena ─────────
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                                  child: Row(children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: e.companyLogoUrl != null
                                          ? Image.network(e.companyLogoUrl!, width: 40, height: 40, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _orgIcon())
                                          : _orgIcon(),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Organizira', style: TextStyle(
                                          color: isDark ? const Color(0xFFBF8997) : _bordo.withOpacity(0.55),
                                          fontSize: 11.5, fontWeight: FontWeight.w500)),
                                      Text(e.companyName!, style: TextStyle(
                                          color: isDark ? const Color(0xFFFFB3C6) : _bordo,
                                          fontSize: 14.5, fontWeight: FontWeight.w800)),
                                    ])),
                                    if (e.ticketPrice != null && e.ticketPrice! > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _bordo, borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(children: [
                                          Text('${e.ticketPrice!.toStringAsFixed(2)} ${e.ticketCurrency ?? 'EUR'}',
                                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                                          Text('ulaznica', style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 10)),
                                        ]),
                                      ),
                                  ]),
                                ),
                                // ── Plaćanje info (samo za plaćene evente) ────
                                if (e.ticketPrice != null && e.ticketPrice! > 0) ...[
                                  Divider(height: 1, color: isDark ? const Color(0xFFBF8997).withOpacity(0.25) : _bordo.withOpacity(0.12)),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Icon(Icons.info_outline_rounded,
                                          color: isDark ? const Color(0xFFBF8997) : _bordo.withOpacity(0.60), size: 15),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(
                                        'Prijavom će vaša ulaznica biti osigurana. Plaćanje se vrši uživo pri dolasku na događaj.',
                                        style: TextStyle(color: isDark ? const Color(0xFFBF8997) : _bordo.withOpacity(0.70),
                                            fontSize: 12.5, height: 1.5),
                                      )),
                                    ]),
                                  ),
                                ],
                                // ── Kontakt mail ──────────────────────────────
                                if (e.companyEmail != null && e.companyEmail!.isNotEmpty) ...[
                                  Divider(height: 1, color: _bordo.withOpacity(0.12)),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                                    child: Row(children: [
                                      Icon(Icons.mail_outline_rounded,
                                          color: isDark ? const Color(0xFFBF8997) : _bordo.withOpacity(0.60), size: 15),
                                      const SizedBox(width: 8),
                                      Text('Kontakt: ${e.companyEmail!}',
                                          style: TextStyle(color: isDark ? kDarkText.withOpacity(0.70) : _bordo.withOpacity(0.70),
                                              fontSize: 12.5)),
                                    ]),
                                  ),
                                ],
                              ]),
                            ),
                          ],

                          Text('Opis', style: TextStyle(color: isDark ? kDarkText : Colors.black87,
                              fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                          const SizedBox(height: 10),
                          Text(e.description.isNotEmpty ? e.description : 'Više informacija uskoro.',
                              textAlign: TextAlign.justify,
                              style: TextStyle(color: isDark ? kDarkText.withOpacity(0.65) : Colors.black.withOpacity(0.65), fontSize: 15, height: 1.65)),

                          if (e.ageGroup != AgeGroup.all || e.genderGroup != GenderGroup.all) ...[
                            const SizedBox(height: 24),
                            Text('Detalji eventi', style: TextStyle(color: isDark ? kDarkText : Colors.black87,
                                fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? kDarkCard : _bordoLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: primary.withOpacity(0.10)),
                              ),
                              child: Column(children: [
                                if (e.ageGroup != AgeGroup.all)
                                  _detailRow(isDark, Icons.cake_outlined, 'Dobna skupina', e.ageGroup.label, primary),
                                if (e.ageGroup != AgeGroup.all && e.genderGroup != GenderGroup.all)
                                  Divider(height: 20, thickness: 0.5, color: primary.withOpacity(0.10)),
                                if (e.genderGroup != GenderGroup.all)
                                  _detailRow(isDark, Icons.people_outline_rounded, 'Tražena grupa', e.genderGroup.label, primary),
                              ]),
                            ),
                          ],
                        ]),
                      )))),
            ],
          ),

          Positioned(top: mq.padding.top + 14, left: 14,
              child: FadeTransition(opacity: _entryFade, child: _BackBtn(onTap: () => Navigator.pop(context)))),

          Positioned(bottom: 0, left: 0, right: 0, child: _joinBar(mq)),
        ]),
      ),
    );
  }

  Widget _orgIcon() => Container(
    width: 40, height: 40,
    decoration: BoxDecoration(color: _bordo, borderRadius: BorderRadius.circular(10)),
    child: const Icon(Icons.business_rounded, color: Colors.white, size: 20),
  );

  Widget _detailRow(bool isDark, IconData icon, String label, String value, Color primary) {
    return Row(children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: primary.withOpacity(isDark ? 0.18 : 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primary, size: 17),
      ),
      const SizedBox(width: 12),
      Text(label, style: TextStyle(
        color: isDark ? kDarkText.withOpacity(0.65) : Colors.black.withOpacity(0.55),
        fontSize: 14,
      )),
      const Spacer(),
      Text(value, style: TextStyle(
        color: primary, fontSize: 14, fontWeight: FontWeight.w700,
      )),
    ]);
  }

  Widget _cw({double? top, double? bottom, double? left, double? right, required double w, required double h}) =>
      Positioned(top: top, bottom: bottom, left: left, right: right,
          child: Container(width: w, height: h, decoration: BoxDecoration(color: Colors.white.withOpacity(0.50), borderRadius: BorderRadius.circular(h/2))));

  Widget _joinBar(MediaQueryData mq) {
    final isDark  = ThemeState.instance.isDark;
    final cardBg  = isDark ? kDarkCard : Colors.white;
    final primary = isDark ? kDarkPrimary : _bordoDark;

    if (_isMyEvent) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 380),
        decoration: BoxDecoration(color: cardBg,
            boxShadow: [BoxShadow(color: primary.withOpacity(0.08), blurRadius: 20, offset: const Offset(0,-4))]),
        padding: EdgeInsets.fromLTRB(24, 14, 24, mq.padding.bottom + 14),
        child: Row(children: [
          Expanded(child: GestureDetector(
            onTap: _editEvent,
            child: Container(height: 50,
              decoration: BoxDecoration(
                color: isDark ? kDarkCard : _bordoLight,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: _bordo.withOpacity(0.40), width: 1.5),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.edit_rounded, color: _bordo, size: 18),
                const SizedBox(width: 8),
                Text('Uredi', style: TextStyle(color: _bordo, fontSize: 15, fontWeight: FontWeight.w700)),
              ]),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: _deleteEvent,
            child: Container(height: 50,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.30), blurRadius: 14, offset: const Offset(0, 5))],
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.delete_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Obriši', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ]),
            ),
          )),
        ]),
      );
    }

    final isFull = widget.event.maxAttendees > 0 &&
        _effectiveAttendees(widget.event) >= widget.event.maxAttendees && !_joined;

    return AnimatedContainer(duration: const Duration(milliseconds: 380),
      decoration: BoxDecoration(color: cardBg,
          boxShadow: [BoxShadow(color: primary.withOpacity(0.08), blurRadius: 20, offset: const Offset(0,-4))]),
      padding: EdgeInsets.fromLTRB(24, 14, 24, mq.padding.bottom + 14),
      child: AnimatedBuilder(animation: _btnScale,
        builder: (_, child) => Transform.scale(scale: _btnScale.value, child: child),
        child: GestureDetector(
          onTap: isFull ? _showFull : _toggleJoin,
          child: AnimatedContainer(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic, height: 54,
            decoration: BoxDecoration(
                color: isFull ? Colors.grey.withOpacity(0.35)
                    : _joined ? (isDark ? const Color(0xFF3A3A42) : const Color(0xFF2C2C2C))
                    : _bordo,
                borderRadius: BorderRadius.circular(27),
                boxShadow: [BoxShadow(
                    color: (isFull ? Colors.grey : _joined ? Colors.black : _bordo).withOpacity(0.28),
                    blurRadius: 16, offset: const Offset(0,6))]),
            child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
              AnimatedSwitcher(duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: Icon(isFull ? Icons.group_off_rounded : _joined ? Icons.close_rounded : Icons.check_rounded,
                      key: ValueKey(isFull ? 'full' : _joined), color: isDark ? kDarkBg : Colors.white, size: 20)),
              const SizedBox(width: 10),
              AnimatedSwitcher(duration: const Duration(milliseconds: 250),
                  child: Text(isFull ? 'Popunjeno' : _joined ? 'Otkaži prijavu' : 'Ja sam za!',
                      key: ValueKey(isFull ? 'full' : _joined),
                      style: TextStyle(color: isDark ? kDarkBg : Colors.white,
                          fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.1))),
            ])),
          ),
        ),
      ),
    );
  }
}

class _BackBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});
  @override State<_BackBtn> createState() => _BackBtnState();
}

class _BackBtnState extends State<_BackBtn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 90));
    _s = Tween<double>(begin: 1.0, end: 0.86).animate(CurvedAnimation(parent: _c, curve: Curves.easeIn));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(scale: _s,
          child: Container(width: 40, height: 40,
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.28), borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.25), width: 1)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16))),
    );
  }
}