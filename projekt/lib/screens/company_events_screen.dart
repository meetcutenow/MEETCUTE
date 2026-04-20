import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'company_auth_state.dart';
import 'company_organize_screen.dart';
import 'theme_state.dart';
import 'company_event_model.dart';

const Color _bordo      = Color(0xFF700D25);
const Color _bordoLight = Color(0xFFF2E8E9);
const String _base = 'http://localhost:8080/api';

// ── MODEL ─────────────────────────────────────────────────────────────────────



// ── MODEL za sudionika ────────────────────────────────────────────────────────

class _Attendee {
  final String  userId;
  final String  displayName;
  final String? photoUrl;
  final String? gender;
  final int?    birthYear;

  const _Attendee({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    this.gender,
    this.birthYear,
  });

  int? get age => birthYear != null ? DateTime.now().year - birthYear! : null;

  String get genderLabel {
    switch (gender) {
      case 'zensko': return '♀';
      case 'musko':  return '♂';
      default:       return '⚧';
    }
  }
}

// ── SCREEN ────────────────────────────────────────────────────────────────────

class CompanyEventsScreen extends StatefulWidget {
  const CompanyEventsScreen({super.key});
  @override State<CompanyEventsScreen> createState() => _CompanyEventsScreenState();
}

class _CompanyEventsScreenState extends State<CompanyEventsScreen>
    with TickerProviderStateMixin {

  List<CompanyEvent> _events  = [];
  bool    _loading = true;
  String? _error;

  late final AnimationController _entryCtrl;
  late final Animation<double>   _entryFade;

  @override
  void initState() {
    super.initState();
    ThemeState.instance.addListener(_onTheme);
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _load();
  }

  void _onTheme() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeState.instance.removeListener(_onTheme);
    _entryCtrl.dispose();
    super.dispose();
  }

  bool  get _isDark   => ThemeState.instance.isDark;
  Color get _bg       => _isDark ? kDarkBg   : const Color(0xFFF8F0F1);
  Color get _card     => _isDark ? kDarkCard : Colors.white;
  Color get _primary  => _isDark ? kDarkPrimary : _bordo;
  Color get _onPrimary => _isDark ? kDarkBg : Colors.white;

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await http.get(
        Uri.parse('$_base/company/events'),
        headers: {'Authorization': 'Bearer ${CompanyAuthState.instance.accessToken}'},
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final body = jsonDecode(utf8.decode(resp.bodyBytes));
        final list = body['data'] as List? ?? [];
        setState(() => _events = list
            .map((e) => CompanyEvent.fromJson(e as Map<String, dynamic>))
            .toList());
        _entryCtrl.forward(from: 0);
      } else {
        final body = jsonDecode(utf8.decode(resp.bodyBytes));
        setState(() => _error = body['message'] ?? 'Greška pri dohvaćanju podataka.');
      }
    } catch (_) {
      setState(() => _error = 'Ne mogu se spojiti na server.\nProvjeri je li backend pokrenut.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<_Attendee>> _loadAttendees(String eventId) async {
    try {
      final resp = await http.get(
        Uri.parse('$_base/events/$eventId/attendees'),
        headers: {'Authorization': 'Bearer ${CompanyAuthState.instance.accessToken}'},
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final list = jsonDecode(utf8.decode(resp.bodyBytes))['data'] as List? ?? [];
        return list.map((a) {
          print("PHOTO URL: ${a['photoUrl']}"); // 👈 DODANO

          return _Attendee(
            userId:      a['userId'] ?? '',
            displayName: a['displayName'] ?? '',
            photoUrl: a['photoUrl'] != null
                ? 'http://10.0.2.2:8080${a['photoUrl']}'
                : null,
            gender:      a['gender'],
            birthYear:   a['birthYear'],
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  // ── Uredi event ───────────────────────────────────────────────────────────
  Future<void> _editEvent(CompanyEvent ev) async {
    final result = await Navigator.push<bool>(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => CompanyOrganizeScreen(editEvent: ev),
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 400),
    ));
    if (result == true) _load();
  }

  // ── Obriši event ──────────────────────────────────────────────────────────
  Future<void> _deleteEvent(CompanyEvent ev) async {
    final confirmed = await _showDeleteDialog(ev.title);
    if (!confirmed) return;

    HapticFeedback.mediumImpact();
    try {
      final resp = await http.delete(
        Uri.parse('$_base/company/events/${ev.id}'),
        headers: {'Authorization': 'Bearer ${CompanyAuthState.instance.accessToken}'},
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Događaj obrisan. Sudionici su obaviješteni.',
              style: TextStyle(color: _onPrimary, fontWeight: FontWeight.w600)),
          backgroundColor: _primary, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ));
        _load();
      } else {
        final body = jsonDecode(utf8.decode(resp.bodyBytes));
        _showSnack(body['message'] ?? 'Greška pri brisanju.');
      }
    } catch (_) {
      if (mounted) _showSnack('Ne mogu se spojiti na server.');
    }
  }

  Future<bool> _showDeleteDialog(String title) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1.0),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(26),
              border: Border.all(color: _primary.withOpacity(0.15)),
              boxShadow: [BoxShadow(color: _primary.withOpacity(0.18),
                  blurRadius: 36, offset: const Offset(0, 14))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50, shape: BoxShape.circle,
                    border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 28)),
              const SizedBox(height: 14),
              Text('Obriši događaj?', style: TextStyle(
                  color: _primary, fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 8),
              Text('"$title"\n\nSvi prijavljeni korisnici će primiti obavijest o otkazu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _primary.withOpacity(0.60), fontSize: 13.5, height: 1.5)),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Container(height: 46,
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _primary.withOpacity(0.20)),
                      ),
                      child: Center(child: Text('Odustani',
                          style: TextStyle(color: _primary, fontSize: 14, fontWeight: FontWeight.w700)))),
                )),
                const SizedBox(width: 10),
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.pop(context, true),
                  child: Container(height: 46,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.28),
                            blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: const Center(child: Text('Obriši',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)))),
                )),
              ]),
            ]),
          ),
        ),
      ),
    ) ?? false;
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      color: _bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 380),
            color: _card,
            padding: EdgeInsets.only(top: mq.padding.top + 10, left: 6, right: 16, bottom: 16),
            child: Row(children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: _primary, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Moji događaji', style: TextStyle(color: _primary, fontSize: 22,
                    fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                Text('Svi objavljeni događaji', style: TextStyle(
                    color: _primary.withOpacity(0.45), fontSize: 13)),
              ])),
              GestureDetector(
                onTap: _load,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 380),
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primary.withOpacity(0.20)),
                  ),
                  child: Icon(Icons.refresh_rounded, color: _primary, size: 20),
                ),
              ),
            ]),
          ),

          Expanded(child: _loading
              ? Center(child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5))
              : _error != null
              ? _errorWidget()
              : _events.isEmpty
              ? _emptyWidget()
              : FadeTransition(
            opacity: _entryFade,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 16, 16, mq.padding.bottom + 16),
              itemCount: _events.length,
              itemBuilder: (_, i) => _EventCard(
                event: _events[i],
                isDark: _isDark,
                primary: _primary,
                onLoadAttendees: _loadAttendees,
                onEdit: () => _editEvent(_events[i]),
                onDelete: () => _deleteEvent(_events[i]),
              ),
            ),
          )),
        ]),
      ),
    );
  }

  Widget _errorWidget() => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.wifi_off_rounded, color: _primary.withOpacity(0.35), size: 56),
      const SizedBox(height: 16),
      Text(_error!, textAlign: TextAlign.center,
          style: TextStyle(color: _primary.withOpacity(0.65), fontSize: 14, height: 1.5)),
      const SizedBox(height: 24),
      GestureDetector(onTap: _load,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: _primary.withOpacity(0.30), blurRadius: 14, offset: const Offset(0, 5))]),
          child: Text('Pokušaj ponovo', style: TextStyle(
              color: _onPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    ]),
  ));

  Widget _emptyWidget() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 80, height: 80,
        decoration: BoxDecoration(color: _primary.withOpacity(0.08), shape: BoxShape.circle,
            border: Border.all(color: _primary.withOpacity(0.20))),
        child: Icon(Icons.event_note_rounded, color: _primary, size: 38)),
    const SizedBox(height: 20),
    Text('Nema objavljenih događaja', style: TextStyle(
        color: _primary, fontSize: 17, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    Text('Klikni "Organiziraj" na početnom ekranu\nda kreiraš svoj prvi događaj.',
        textAlign: TextAlign.center,
        style: TextStyle(color: _primary.withOpacity(0.50), fontSize: 13.5, height: 1.55)),
  ]));
}

// ── Kartica događaja ──────────────────────────────────────────────────────────

class _EventCard extends StatefulWidget {
  final CompanyEvent event;
  final bool    isDark;
  final Color   primary;
  final Future<List<_Attendee>> Function(String) onLoadAttendees;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventCard({
    required this.event,
    required this.isDark,
    required this.primary,
    required this.onLoadAttendees,
    required this.onEdit,
    required this.onDelete,
  });

  @override State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _expanded      = false;
  bool _showPeople    = false;
  List<_Attendee> _attendees = [];
  bool _loadingAttendees = false;

  String get _dateStr {
    final d = widget.event.eventDate;
    if (d == null) return '—';
    try {
      final parts = d.split('-');
      return '${parts[2]}.${parts[1]}.${parts[0]}.';
    } catch (_) { return d; }
  }

  String get _timeStr {
    final s = widget.event.timeStart;
    final e = widget.event.timeEnd;
    if (s == null) return '—';
    final start = s.length >= 5 ? s.substring(0, 5) : s;
    if (e == null) return start;
    return '$start – ${e.length >= 5 ? e.substring(0, 5) : e}';
  }

  Color get _cardColor {
    try {
      final hex = widget.event.cardColorHex ?? '#700D25';
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) { return _bordo; }
  }

  Future<void> _togglePeople() async {
    if (!_showPeople && _attendees.isEmpty) {
      setState(() => _loadingAttendees = true);
      _attendees = await widget.onLoadAttendees(widget.event.id);
      setState(() => _loadingAttendees = false);
    }
    setState(() => _showPeople = !_showPeople);
  }

  @override
  Widget build(BuildContext context) {
    final ev      = widget.event;
    final isDark  = widget.isDark;
    final primary = widget.primary;
    final cardBg  = isDark ? kDarkCard : Colors.white;
    final textCol = isDark ? kDarkText : _bordo;
    final subCol  = isDark ? kDarkTextSub : _bordo.withOpacity(0.55);
    final chipBg  = isDark ? kDarkCardEl  : _bordoLight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withOpacity(isDark ? 0.30 : 0.20), width: 1.2),
        boxShadow: [BoxShadow(
            color: primary.withOpacity(isDark ? 0.15 : 0.08),
            blurRadius: 18, offset: const Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header ──────────────────────────────────────────────────────────
        GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _expanded = !_expanded); },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardColor.withOpacity(isDark ? 0.18 : 0.10),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: primary.withOpacity(0.10))),
            ),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: _cardColor.withOpacity(isDark ? 0.35 : 0.22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _cardColor.withOpacity(0.45), width: 1.2),
                ),
                child: Icon(Icons.event_rounded,
                    color: isDark ? _cardColor.withOpacity(0.90) : _cardColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ev.title, style: TextStyle(color: textCol, fontSize: 15.5,
                    fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.location_on_rounded, color: subCol, size: 13),
                  const SizedBox(width: 3),
                  Expanded(child: Text(
                    ev.specificLocation != null ? '${ev.specificLocation}, ${ev.city}' : ev.city,
                    style: TextStyle(color: subCol, fontSize: 12.5),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  )),
                ]),
              ])),
              Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: primary.withOpacity(0.50), size: 22),
            ]),
          ),
        ),

        // ── Info redovi ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            _chip(Icons.calendar_today_rounded, _dateStr, chipBg, primary),
            const SizedBox(width: 8),
            _chip(Icons.access_time_rounded, _timeStr, chipBg, primary),
          ]),
        ),

        // ── Akcije: Sudionici | Uredi | Obriši ───────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(children: [
            // Sudionici gumb
            GestureDetector(
              onTap: _togglePeople,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ev.isFull
                      ? Colors.redAccent.withOpacity(0.12)
                      : _showPeople
                      ? primary.withOpacity(0.15)
                      : chipBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _showPeople
                      ? primary.withOpacity(0.40) : primary.withOpacity(0.15)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.people_rounded,
                      color: ev.isFull ? Colors.redAccent : primary, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    ev.maxAttendees != null
                        ? '${ev.attendeeCount}/${ev.maxAttendees}'
                        : '${ev.attendeeCount}',
                    style: TextStyle(
                        color: ev.isFull ? Colors.redAccent : primary,
                        fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 4),
                  Icon(_showPeople ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: primary.withOpacity(0.60), size: 16),
                ]),
              ),
            ),
            const Spacer(),
            // Uredi gumb
            GestureDetector(
              onTap: widget.onEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primary.withOpacity(0.25)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.edit_rounded, color: primary, size: 14),
                  const SizedBox(width: 5),
                  Text('Uredi', style: TextStyle(
                      color: primary, fontSize: 12.5, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            // Obriši gumb
            GestureDetector(
              onTap: widget.onDelete,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.30)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 14),
                  SizedBox(width: 5),
                  Text('Obriši', style: TextStyle(
                      color: Colors.redAccent, fontSize: 12.5, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ]),
        ),

        // ── Lista sudionika ──────────────────────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: _showPeople
              ? Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary.withOpacity(isDark ? 0.10 : 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primary.withOpacity(0.15)),
            ),
            child: _loadingAttendees
                ? Center(child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: primary)),
            ))
                : _attendees.isEmpty
                ? Padding(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                Icon(Icons.person_off_rounded, color: primary.withOpacity(0.40), size: 18),
                const SizedBox(width: 8),
                Text('Još nema prijavljenih sudionika',
                    style: TextStyle(color: primary.withOpacity(0.55), fontSize: 13)),
              ]),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prijavljeni sudionici (${_attendees.length})',
                    style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ..._attendees.map((a) => _AttendeeRow(
                    attendee: a, isDark: isDark, primary: primary)),
              ],
            ),
          )
              : const SizedBox(width: double.infinity),
        ),

        // ── Prošireni detalji ────────────────────────────────────────────────
        if (_expanded) ...[
          Divider(height: 1, color: primary.withOpacity(0.10)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              if (ev.ticketPrice != null) ...[
                _statRow(Icons.confirmation_number_rounded, 'Cijena ulaznice',
                    '${ev.ticketPrice!.toStringAsFixed(2)} ${ev.ticketCurrency ?? 'EUR'}',
                    isDark, primary),
                const SizedBox(height: 8),
                _statRow(Icons.payments_rounded, 'Prihod (trenutno)',
                    '${(ev.ticketPrice! * ev.attendeeCount).toStringAsFixed(2)} ${ev.ticketCurrency ?? 'EUR'}',
                    isDark, primary),
                const SizedBox(height: 8),
              ],

              if (ev.category != null)
                _statRow(Icons.category_rounded, 'Kategorija', ev.category!, isDark, primary),

              const SizedBox(height: 12),

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Popunjenost', style: TextStyle(
                    color: primary.withOpacity(0.70), fontSize: 12.5, fontWeight: FontWeight.w600)),
                Text(ev.maxAttendees != null
                    ? '${ev.attendeeCount} / ${ev.maxAttendees}'
                    : '${ev.attendeeCount} prijavljenih',
                    style: TextStyle(color: primary, fontSize: 12.5, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ev.maxAttendees != null && ev.maxAttendees! > 0
                      ? (ev.attendeeCount / ev.maxAttendees!).clamp(0.0, 1.0)
                      : 0.0,
                  minHeight: 8,
                  backgroundColor: primary.withOpacity(0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ev.isFull ? Colors.redAccent : primary,
                  ),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _chip(IconData icon, String label, Color bg, Color primary) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primary.withOpacity(0.15))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: primary, size: 12),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _statRow(IconData icon, String label, String value, bool isDark, Color primary) =>
      Row(children: [
        Icon(icon, color: primary.withOpacity(0.50), size: 15),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: primary.withOpacity(0.60), fontSize: 13)),
        Text(value, style: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.w700)),
      ]);
}

// ── Red sudionika ─────────────────────────────────────────────────────────────

class _AttendeeRow extends StatelessWidget {
  final _Attendee attendee;
  final bool  isDark;
  final Color primary;
  const _AttendeeRow({required this.attendee, required this.isDark, required this.primary});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? kDarkBg : Colors.white;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primary.withOpacity(0.12)),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withOpacity(0.12),
            border: Border.all(color: primary.withOpacity(0.25), width: 1.5),
          ),
          child: attendee.photoUrl != null
              ? ClipOval(child: Image.network(attendee.photoUrl!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initial()))
              : _initial(),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(attendee.displayName,
            style: TextStyle(color: primary, fontSize: 13.5, fontWeight: FontWeight.w700))),
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.08), shape: BoxShape.circle,
            border: Border.all(color: primary.withOpacity(0.20)),
          ),
          child: Center(child: Text(attendee.genderLabel,
              style: const TextStyle(fontSize: 13))),
        ),
        const SizedBox(width: 8),
        if (attendee.age != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primary.withOpacity(0.18)),
            ),
            child: Text('${attendee.age} g.',
                style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
      ]),
    );
  }

  Widget _initial() => Center(
    child: Text(
      attendee.displayName.isNotEmpty ? attendee.displayName[0].toUpperCase() : '?',
      style: TextStyle(color: primary, fontSize: 16, fontWeight: FontWeight.w800),
    ),
  );
}