import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'company_auth_state.dart';

const Color _bordo      = Color(0xFF700D25);
const Color _bordoLight = Color(0xFFF2E8E9);
const String _base = 'http://localhost:8080/api';

// ── MODEL ─────────────────────────────────────────────────────

class _CompanyEvent {
  final String id;
  final String title;
  final String city;
  final String? specificLocation;
  final String? eventDate;
  final String? timeStart;
  final String? timeEnd;
  final String? category;
  final int attendeeCount;
  final int? maxAttendees;
  final bool isFull;
  final double? ticketPrice;
  final String? ticketCurrency;
  final String? cardColorHex;

  const _CompanyEvent({
    required this.id, required this.title, required this.city,
    this.specificLocation, this.eventDate, this.timeStart, this.timeEnd,
    this.category, required this.attendeeCount, this.maxAttendees,
    required this.isFull, this.ticketPrice, this.ticketCurrency, this.cardColorHex,
  });

  factory _CompanyEvent.fromJson(Map<String, dynamic> j) => _CompanyEvent(
    id:               j['id'] ?? '',
    title:            j['title'] ?? '',
    city:             j['city'] ?? '',
    specificLocation: j['specificLocation'],
    eventDate:        j['eventDate'],
    timeStart:        j['timeStart'],
    timeEnd:          j['timeEnd'],
    category:         j['category'],
    attendeeCount:    j['attendeeCount'] ?? 0,
    maxAttendees:     j['maxAttendees'],
    isFull:           j['full'] ?? false,
    ticketPrice:      (j['ticketPrice'] as num?)?.toDouble(),
    ticketCurrency:   j['ticketCurrency'],
    cardColorHex:     j['cardColorHex'],
  );
}

// ── SCREEN ────────────────────────────────────────────────────

class CompanyEventsScreen extends StatefulWidget {
  const CompanyEventsScreen({super.key});
  @override State<CompanyEventsScreen> createState() => _CompanyEventsScreenState();
}

class _CompanyEventsScreenState extends State<CompanyEventsScreen>
    with TickerProviderStateMixin {

  List<_CompanyEvent> _events = [];
  bool   _loading = true;
  String? _error;

  late final AnimationController _entryCtrl;
  late final Animation<double>   _entryFade;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() { _entryCtrl.dispose(); super.dispose(); }

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
        setState(() => _events = list.map((e) => _CompanyEvent.fromJson(e as Map<String, dynamic>)).toList());
        _entryCtrl.forward(from: 0);
      } else {
        final body = jsonDecode(utf8.decode(resp.bodyBytes));
        setState(() => _error = body['message'] ?? 'Greška pri dohvaćanju podataka.');
      }
    } catch (e) {
      setState(() => _error = 'Ne mogu se spojiti na server.\nProvjeri je li backend pokrenut.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F0F1),
      body: Column(children: [
        // ── Header ──────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: EdgeInsets.only(top: mq.padding.top + 10, left: 6, right: 16, bottom: 18),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _bordo, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Moji događaji', style: TextStyle(color: _bordo, fontSize: 22,
                  fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              Text('Svi tvoji objavljeni eventi', style: TextStyle(
                  color: _bordo, fontSize: 13, fontWeight: FontWeight.w400)),
            ])),
            // Refresh
            GestureDetector(
              onTap: _load,
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: _bordoLight, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.refresh_rounded, color: _bordo, size: 22),
              ),
            ),
          ]),
        ),

        // ── Sadržaj ─────────────────────────────────────────
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: _bordo, strokeWidth: 2.5))
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
            itemBuilder: (_, i) => _EventCard(event: _events[i]),
          ),
        ),
        ),
      ]),
    );
  }

  Widget _errorWidget() => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.wifi_off_rounded, color: _bordo.withOpacity(0.35), size: 56),
      const SizedBox(height: 16),
      Text(_error!, textAlign: TextAlign.center,
          style: TextStyle(color: _bordo.withOpacity(0.65), fontSize: 14, height: 1.5)),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: _load,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(color: _bordo, borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: _bordo.withOpacity(0.30), blurRadius: 14, offset: const Offset(0, 5))]),
          child: const Text('Pokušaj ponovo', style: TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    ]),
  ));

  Widget _emptyWidget() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 80, height: 80,
        decoration: BoxDecoration(color: _bordoLight, shape: BoxShape.circle),
        child: const Icon(Icons.event_note_rounded, color: _bordo, size: 38)),
    const SizedBox(height: 20),
    const Text('Nemaš još objavljenih eventi', style: TextStyle(
        color: _bordo, fontSize: 17, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    Text('Klikni "Organiziraj" na početnom ekranu\nda kreiraš svoj prvi event.',
        textAlign: TextAlign.center,
        style: TextStyle(color: _bordo.withOpacity(0.55), fontSize: 13.5, height: 1.55)),
  ]));
}

// ── Kartica eventa ─────────────────────────────────────────────

class _EventCard extends StatefulWidget {
  final _CompanyEvent event;
  const _EventCard({required this.event});
  @override State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _expanded = false;

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
    final end = e.length >= 5 ? e.substring(0, 5) : e;
    return '$start – $end';
  }

  Color get _cardColor {
    try {
      final hex = widget.event.cardColorHex ?? '#700D25';
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) { return _bordo; }
  }

  @override
  Widget build(BuildContext context) {
    final ev = widget.event;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _expanded = !_expanded); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _bordo.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 5))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Gornji dio s bojom ─────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardColor.withOpacity(0.10),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: _cardColor.withOpacity(0.12))),
            ),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.event_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ev.title, style: const TextStyle(color: _bordo, fontSize: 15.5,
                    fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.location_on_rounded, color: _bordo.withOpacity(0.45), size: 13),
                  const SizedBox(width: 3),
                  Expanded(child: Text(
                    ev.specificLocation != null ? '${ev.specificLocation}, ${ev.city}' : ev.city,
                    style: TextStyle(color: _bordo.withOpacity(0.55), fontSize: 12.5),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  )),
                ]),
              ])),
              Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: _bordo.withOpacity(0.40), size: 22),
            ]),
          ),

          // ── Info redovi ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(children: [
              _infoChip(Icons.calendar_today_rounded, _dateStr),
              const SizedBox(width: 8),
              _infoChip(Icons.access_time_rounded, _timeStr),
              const Spacer(),
              // Broj sudionika
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ev.isFull ? Colors.redAccent.withOpacity(0.12) : _bordoLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.people_rounded,
                      color: ev.isFull ? Colors.redAccent : _bordo, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    ev.maxAttendees != null
                        ? '${ev.attendeeCount}/${ev.maxAttendees}'
                        : '${ev.attendeeCount}',
                    style: TextStyle(
                      color: ev.isFull ? Colors.redAccent : _bordo,
                      fontSize: 12.5, fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (ev.isFull) ...[
                    const SizedBox(width: 4),
                    Text('• Popunjeno', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                  ],
                ]),
              ),
            ]),
          ),

          // ── Prošireni detalji (statistike) ─────────────
          if (_expanded) ...[
            Divider(height: 1, color: _bordo.withOpacity(0.08)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                if (ev.ticketPrice != null) ...[
                  _statRow(Icons.confirmation_number_rounded,
                    'Cijena ulaznice',
                    '${ev.ticketPrice!.toStringAsFixed(2)} ${ev.ticketCurrency ?? 'EUR'}',
                  ),
                  const SizedBox(height: 8),
                  _statRow(Icons.payments_rounded,
                    'Prihod (trenutno)',
                    '${(ev.ticketPrice! * ev.attendeeCount).toStringAsFixed(2)} ${ev.ticketCurrency ?? 'EUR'}',
                  ),
                  const SizedBox(height: 8),
                ],

                if (ev.category != null)
                  _statRow(Icons.category_rounded, 'Kategorija', ev.category!),

                const SizedBox(height: 12),

                // ── Popunjenost ─────────────────────────
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Popunjenost', style: TextStyle(
                      color: _bordo.withOpacity(0.70), fontSize: 12.5, fontWeight: FontWeight.w600)),
                  Text(ev.maxAttendees != null
                      ? '${ev.attendeeCount} / ${ev.maxAttendees}'
                      : '${ev.attendeeCount} prijavljenih',
                      style: const TextStyle(color: _bordo, fontSize: 12.5, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ev.maxAttendees != null && ev.maxAttendees! > 0
                        ? (ev.attendeeCount / ev.maxAttendees!).clamp(0.0, 1.0)
                        : (ev.attendeeCount > 0 ? 1.0 : 0.0),
                    minHeight: 8,
                    backgroundColor: _bordo.withOpacity(0.10),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ev.isFull ? Colors.redAccent : _bordo,
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _bordoLight, borderRadius: BorderRadius.circular(8),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: _bordo, size: 12),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: _bordo, fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _statRow(IconData icon, String label, String value) => Row(children: [
    Icon(icon, color: _bordo.withOpacity(0.45), size: 15),
    const SizedBox(width: 8),
    Text('$label: ', style: TextStyle(color: _bordo.withOpacity(0.55), fontSize: 13)),
    Text(value, style: const TextStyle(color: _bordo, fontSize: 13, fontWeight: FontWeight.w700)),
  ]);
}