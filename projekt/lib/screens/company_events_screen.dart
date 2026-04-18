import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'company_auth_state.dart';

const Color _bordo      = Color(0xFF700D25);
const Color _bordoLight = Color(0xFFF2E8E9);
const String _base = 'http://localhost:8080/api';

// ── DATA MODELS ───────────────────────────────────────────────

class CompanyEventStats {
  final String eventId;
  final String title;
  final String? eventDate;
  final int totalJoined;
  final int totalCancelled;
  final int maleCount;
  final int femaleCount;
  final int otherCount;
  final int age18_25;
  final int age26_35;
  final int age36_45;
  final int age45plus;
  final double? ticketPrice;
  final String? ticketCurrency;
  final double totalRevenue;

  const CompanyEventStats({
    required this.eventId, required this.title, this.eventDate,
    required this.totalJoined, required this.totalCancelled,
    required this.maleCount, required this.femaleCount, required this.otherCount,
    required this.age18_25, required this.age26_35,
    required this.age36_45, required this.age45plus,
    this.ticketPrice, this.ticketCurrency,
    required this.totalRevenue,
  });

  factory CompanyEventStats.fromJson(Map<String, dynamic> j) => CompanyEventStats(
    eventId:       j['eventId'] ?? '',
    title:         j['title'] ?? '',
    eventDate:     j['eventDate'],
    totalJoined:   j['totalJoined'] ?? 0,
    totalCancelled: j['totalCancelled'] ?? 0,
    maleCount:     j['maleCount'] ?? 0,
    femaleCount:   j['femaleCount'] ?? 0,
    otherCount:    j['otherCount'] ?? 0,
    age18_25:      j['age18_25'] ?? 0,
    age26_35:      j['age26_35'] ?? 0,
    age36_45:      j['age36_45'] ?? 0,
    age45plus:     j['age45plus'] ?? 0,
    ticketPrice:   (j['ticketPrice'] as num?)?.toDouble(),
    ticketCurrency: j['ticketCurrency'],
    totalRevenue:  (j['totalRevenue'] as num?)?.toDouble() ?? 0,
  );
}

// ── SCREEN ────────────────────────────────────────────────────

class CompanyEventsScreen extends StatefulWidget {
  const CompanyEventsScreen({super.key});
  @override State<CompanyEventsScreen> createState() => _CompanyEventsScreenState();
}

class _CompanyEventsScreenState extends State<CompanyEventsScreen> with TickerProviderStateMixin {

  List<CompanyEventStats> _stats = [];
  bool _loading = true;
  String? _error;

  late final AnimationController _entryCtrl;
  late final Animation<double>   _entryFade;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _loadStats();
  }

  @override
  void dispose() { _entryCtrl.dispose(); super.dispose(); }

  Future<void> _loadStats() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await http.get(
        Uri.parse('$_base/company/events/stats'),
        headers: {'Authorization': 'Bearer ${CompanyAuthState.instance.accessToken}'},
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final list = jsonDecode(utf8.decode(resp.bodyBytes))['data'] as List;
        setState(() => _stats = list.map((e) => CompanyEventStats.fromJson(e)).toList());
        _entryCtrl.forward();
      } else {
        setState(() => _error = 'Greška pri dohvaćanju podataka.');
      }
    } catch (e) {
      setState(() => _error = 'Ne mogu se spojiti na server.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDEF),
      body: Column(children: [
        _buildHeader(mq),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: _bordo, strokeWidth: 2))
            : _error != null
            ? _buildError()
            : _stats.isEmpty
            ? _buildEmpty()
            : FadeTransition(
          opacity: _entryFade,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 16, 16, mq.padding.bottom + 20),
            itemCount: _stats.length,
            itemBuilder: (_, i) => _EventStatsCard(stats: _stats[i]),
          ),
        )),
      ]),
    );
  }

  Widget _buildHeader(MediaQueryData mq) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(top: mq.padding.top + 12, left: 8, right: 18, bottom: 16),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _bordo, size: 20),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
        const Expanded(child: Text('Moji događaji',
            style: TextStyle(color: _bordo, fontSize: 22,
                fontWeight: FontWeight.w900, letterSpacing: -0.5))),
        GestureDetector(
          onTap: _loadStats,
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: _bordoLight, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.refresh_rounded, color: _bordo, size: 20),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 80, height: 80,
        decoration: BoxDecoration(color: _bordoLight, shape: BoxShape.circle),
        child: const Icon(Icons.event_busy_rounded, color: _bordo, size: 36)),
    const SizedBox(height: 20),
    const Text('Nema događanja', style: TextStyle(color: _bordo, fontSize: 18, fontWeight: FontWeight.w800)),
    const SizedBox(height: 8),
    Text('Organizirajte prvi event!', style: TextStyle(color: _bordo.withOpacity(0.50), fontSize: 14)),
  ]));

  Widget _buildError() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.wifi_off_rounded, color: _bordo, size: 48),
    const SizedBox(height: 14),
    Text(_error!, style: TextStyle(color: _bordo.withOpacity(0.65), fontSize: 14)),
    const SizedBox(height: 16),
    GestureDetector(
      onTap: _loadStats,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: _bordo, borderRadius: BorderRadius.circular(20)),
        child: const Text('Pokušaj ponovo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    ),
  ]));
}

// ── EVENT STATS CARD ──────────────────────────────────────────

class _EventStatsCard extends StatefulWidget {
  final CompanyEventStats stats;
  const _EventStatsCard({required this.stats});
  @override State<_EventStatsCard> createState() => _EventStatsCardState();
}

class _EventStatsCardState extends State<_EventStatsCard> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _expandCtrl;
  late final Animation<double>   _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _expandAnim = CurvedAnimation(parent: _expandCtrl, curve: Curves.easeOutCubic);
  }

  @override void dispose() { _expandCtrl.dispose(); super.dispose(); }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _expanded = !_expanded);
    _expanded ? _expandCtrl.forward() : _expandCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.stats;
    final total = s.totalJoined;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _bordo.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: _bordo.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 5))],
      ),
      child: Column(children: [
        // Header row
        GestureDetector(
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF700D25), Color(0xFF9E1535)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.event_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.title, style: const TextStyle(
                    color: _bordo, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(s.eventDate ?? '', style: TextStyle(
                    color: _bordo.withOpacity(0.50), fontSize: 12.5)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _statPill('$total sudionika', Icons.people_rounded),
                if (s.ticketPrice != null) ...[
                  const SizedBox(height: 5),
                  _statPill('${s.totalRevenue.toStringAsFixed(0)} ${s.ticketCurrency ?? 'EUR'}',
                      Icons.euro_rounded),
                ],
              ]),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(Icons.keyboard_arrow_down_rounded, color: _bordo, size: 22),
              ),
            ]),
          ),
        ),

        // Expanded stats
        SizeTransition(
          sizeFactor: _expandAnim,
          child: Column(children: [
            Divider(height: 1, thickness: 0.5, color: _bordo.withOpacity(0.10)),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Spol ─────────────────────────────────────
                _sectionTitle('Spol sudionika'),
                const SizedBox(height: 12),
                Row(children: [
                  _genderBar('Muško', s.maleCount, total, const Color(0xFF3B8BD4)),
                  const SizedBox(width: 10),
                  _genderBar('Žensko', s.femaleCount, total, const Color(0xFFD4537E)),
                  const SizedBox(width: 10),
                  _genderBar('Ostalo', s.otherCount, total, const Color(0xFF888780)),
                ]),
                const SizedBox(height: 20),

                // ── Dob ──────────────────────────────────────
                _sectionTitle('Dobna skupina'),
                const SizedBox(height: 12),
                _ageBar('18–25', s.age18_25, total),
                const SizedBox(height: 8),
                _ageBar('26–35', s.age26_35, total),
                const SizedBox(height: 8),
                _ageBar('36–45', s.age36_45, total),
                const SizedBox(height: 8),
                _ageBar('45+',   s.age45plus, total),
                const SizedBox(height: 20),

                // ── Ulaznice ─────────────────────────────────
                if (s.ticketPrice != null) ...[
                  _sectionTitle('Prihod od ulaznica'),
                  const SizedBox(height: 12),
                  Row(children: [
                    _infoBox('Cijena', '${s.ticketPrice!.toStringAsFixed(2)} ${s.ticketCurrency ?? 'EUR'}',
                        Icons.confirmation_number_rounded),
                    const SizedBox(width: 10),
                    _infoBox('Ukupno', '${s.totalRevenue.toStringAsFixed(2)} ${s.ticketCurrency ?? 'EUR'}',
                        Icons.euro_rounded),
                    const SizedBox(width: 10),
                    _infoBox('Prodano', '${s.totalJoined} karta', Icons.people_rounded),
                  ]),
                ],

                // ── Otkazivanja ───────────────────────────────
                const SizedBox(height: 14),
                Row(children: [
                  _infoBox('Prijavljeno',  '${s.totalJoined}',    Icons.check_circle_outline_rounded),
                  const SizedBox(width: 10),
                  _infoBox('Otkazano', '${s.totalCancelled}', Icons.cancel_outlined),
                ]),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(
      color: _bordo, fontSize: 13.5, fontWeight: FontWeight.w700));

  Widget _statPill(String label, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _bordo.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _bordo.withOpacity(0.12)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: _bordo, size: 12),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: _bordo, fontSize: 11.5, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _genderBar(String label, int count, int total, Color color) {
    final ratio = total > 0 ? count / total : 0.0;
    final pct   = (ratio * 100).round();
    return Expanded(child: Column(children: [
      Text('$pct%', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: ratio),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => Container(
          height: 8, decoration: BoxDecoration(
            color: _bordoLight, borderRadius: BorderRadius.circular(4)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: v.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      ),
      const SizedBox(height: 5),
      Text(label, style: TextStyle(color: _bordo.withOpacity(0.55), fontSize: 11.5)),
      Text('$count', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    ]));
  }

  Widget _ageBar(String label, int count, int total) {
    final ratio = total > 0 ? count / total : 0.0;
    final pct   = (ratio * 100).round();
    return Row(children: [
      SizedBox(width: 44, child: Text(label, style: TextStyle(
          color: _bordo.withOpacity(0.60), fontSize: 12, fontWeight: FontWeight.w600))),
      const SizedBox(width: 10),
      Expanded(child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: ratio),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => Container(
          height: 10, decoration: BoxDecoration(
            color: _bordoLight, borderRadius: BorderRadius.circular(5)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: v.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF700D25), Color(0xFF9E1535)]),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      )),
      const SizedBox(width: 10),
      SizedBox(width: 36, child: Text('$count ($pct%)', textAlign: TextAlign.right,
          style: const TextStyle(color: _bordo, fontSize: 11, fontWeight: FontWeight.w600))),
    ]);
  }

  Widget _infoBox(String label, String value, IconData icon) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: _bordoLight, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _bordo.withOpacity(0.10)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: _bordo.withOpacity(0.55), size: 16),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(color: _bordo, fontSize: 13.5, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: _bordo.withOpacity(0.50), fontSize: 11)),
    ]),
  ));
}