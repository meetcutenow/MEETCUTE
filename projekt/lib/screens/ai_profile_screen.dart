import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'profile_setup_screen.dart' show ProfileSetupData;
import 'theme_state.dart';
import 'auth_state.dart';

// ─── Konstante ───────────────────────────────────────────────────────────────
const Color _bordo      = Color(0xFF700D25);
const Color _bordoLight = Color(0xFFF2E8E9);

const String _whisperUrl = 'http://localhost:5050';


// ─── Prompt za Claude ────────────────────────────────────────────────────────
const String _systemPrompt = '''
Ti si asistent koji pomaže korisnicima ispuniti profil na MeetCute aplikaciji za upoznavanje.

Korisnik ti daje transkripciju svog glasovnog opisa. Izvuci relevantne podatke i vrati JSON.

VAŽNO - Vrijednosti moraju biti TOČNO ovakve (ili null):

gender: "musko" | "zensko" | "ostalo"
hairColor: "plava" | "smeda" | "crna" | "crvena" | "sijeda" | "ostalo"
eyeColor: "smede" | "zelene" | "plave" | "sive"
piercing: "da" | "ne"
tattoo: "da" | "ne"
seekingGender: "musko" | "zensko" | "sve"
interests: Lista od ovih vrijednosti: ["Crtanje","Fotografija","Pisanje","Film","Trčanje","Biciklizam","Planinarenje","Teretana","Boks","Tenis","Nogomet","Odbojka","Kuhanje","Putovanja","Gaming","Formula","Glazba"]

Vrati SAMO JSON bez ikakvih komentara ili objašnjenja:
{
  "birthYear": null,
  "birthMonth": null,
  "birthDay": null,
  "height": null,
  "gender": null,
  "hairColor": null,
  "eyeColor": null,
  "piercing": null,
  "tattoo": null,
  "interests": [],
  "iceBreaker": null,
  "seekingGender": null,
  "prefAgeFrom": null,
  "prefAgeTo": null
}

Ako nešto nije rečeno, stavi null. iceBreaker treba biti kratka, zanimljiva rečenica na ISTOM jeziku kao transkripcija.
''';

// ─── Stanje ekrana ────────────────────────────────────────────────────────────
enum _ScreenState { idle, recording, processing, transcribing, parsing, done, error }

// ─── GLAVNI WIDGET ────────────────────────────────────────────────────────────
class AiProfileScreen extends StatefulWidget {
  final ProfileSetupData currentData;
  final void Function(ProfileSetupData) onFilled;

  const AiProfileScreen({
    super.key,
    required this.currentData,
    required this.onFilled,
  });

  @override
  State<AiProfileScreen> createState() => _AiProfileScreenState();
}

class _AiProfileScreenState extends State<AiProfileScreen>
    with TickerProviderStateMixin {

  final Record _recorder = Record();
  _ScreenState _state = _ScreenState.idle;
  String? _transcript;
  String? _errorMsg;
  Map<String, dynamic>? _parsedData;
  String? _recordingPath;

  // Animacije
  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;
  late AnimationController _entryCtrl;
  late Animation<double>   _pulseAnim;
  late Animation<double>   _entryFade;
  late Animation<Offset>   _entrySlide;

  bool get _isDark => ThemeState.instance.isDark;
  Color get _primary => _isDark ? kDarkPrimary : _bordo;
  Color get _bg => _isDark ? kDarkBg : const Color(0xFFFAF5F6);
  Color get _card => _isDark ? kDarkCard : Colors.white;

  @override
  void initState() {
    super.initState();
    ThemeState.instance.addListener(_onTheme);

    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _waveCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1800))..repeat();

    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  void _onTheme() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeState.instance.removeListener(_onTheme);
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _entryCtrl.dispose();
    _recorder.dispose();
    super.dispose();
  }

  // ── SNIMANJE ────────────────────────────────────────────────────────────────
  Future<void> _startRecording() async {
    HapticFeedback.mediumImpact();

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      setState(() {
        _state = _ScreenState.error;
        _errorMsg = 'Potrebna je dozvola za mikrofon.\nIdi u Postavke i dopusti pristup.';
      });
      return;
    }

    final dir = await getTemporaryDirectory();
    _recordingPath = '${dir.path}/ai_profile_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.start(
      path: _recordingPath!,
      encoder: AudioEncoder.wav,
      samplingRate: 16000,
    );

    setState(() => _state = _ScreenState.recording);
  }

  Future<void> _stopRecording() async {
    HapticFeedback.lightImpact();
    final path = await _recorder.stop();
    if (path == null) {
      setState(() {
        _state = _ScreenState.error;
        _errorMsg = 'Snimanje nije uspjelo. Pokušaj ponovo.';
      });
      return;
    }
    _recordingPath = path;
    await _processAudio();
  }

  // ── OBRADA AUDIO → TEKST → PROFIL ───────────────────────────────────────────
  Future<void> _processAudio() async {
    // 1. Whisper transkript
    setState(() => _state = _ScreenState.transcribing);

    String? transcript;
    try {
      final file = File(_recordingPath!);
      final request = http.MultipartRequest('POST', Uri.parse('$_whisperUrl/transcribe'));
      request.files.add(http.MultipartFile.fromBytes(
        'audio',
        await file.readAsBytes(),
        filename: 'recording.wav',
      ));
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode != 200) throw Exception('Whisper greška: ${resp.body}');
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['success'] != true) throw Exception(data['error'] ?? 'Greška');
      transcript = data['text'] as String;
    } catch (e) {
      setState(() {
        _state = _ScreenState.error;
        _errorMsg = 'Ne mogu se spojiti na Whisper server.\n\n'
            'Provjeri je li pokrenut:\n'
            'cd whisper-server\n'
            'python server.py';
      });
      return;
    }

    setState(() {
      _transcript = transcript;
      _state = _ScreenState.parsing;
    });

    // 2. Claude parsira podatke
    // 2. Backend poziva Claude i parsira podatke
    try {
      final resp = await http.post(
        Uri.parse('http://localhost:8080/api/ai/parse-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthState.instance.accessToken}',
        },
        body: jsonEncode({'transcript': transcript}),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;

      if (resp.statusCode == 200 && data['success'] == true) {
        final parsed = data['data'] as Map<String, dynamic>;
        setState(() {
          _parsedData = parsed;
          _state = _ScreenState.done;
        });
      } else {
        setState(() {
          _state = _ScreenState.error;
          _errorMsg = data['message'] ?? 'Greška pri obradi s Claude AI.';
        });
      }
    } catch (e) {
      setState(() {
        _state = _ScreenState.error;
        _errorMsg = 'Greška pri obradi s Claude AI.\nProva internet vezu.';
      });
    }
  }

  // ── PRIMIJENI PODATKE NA PROFIL ──────────────────────────────────────────────
  void _applyToProfile() {
      if (_parsedData == null) return;
      HapticFeedback.mediumImpact();

      final d = _parsedData!;
      final updated = widget.currentData.copy();

      print('=== PARSED DATA: $d');
      print('=== HEIGHT: ${d['height']}');
      print('=== BIRTH YEAR: ${d['birthYear']}');

    if (d['birthYear'] != null) updated.birthYear = d['birthYear'] as int?;
    if (d['birthMonth'] != null) updated.birthMonth = d['birthMonth'] as int?;
    if (d['birthDay'] != null) updated.birthDay = d['birthDay'] as int?;
    if (d['height'] != null) {
      final h = d['height'];
      updated.height = h is int ? h.toString() : h.toString().replaceAll('.0', '');
    }
    if (d['gender'] != null) updated.gender = d['gender'] as String?;
    if (d['hairColor'] != null) updated.hairColor = d['hairColor'] as String?;
    if (d['eyeColor'] != null) updated.eyeColor = d['eyeColor'] as String?;
    if (d['piercing'] != null) updated.piercing = d['piercing'] as String?;
    if (d['tattoo'] != null) updated.tattoo = d['tattoo'] as String?;
    if (d['iceBreaker'] != null) updated.iceBreaker = d['iceBreaker'].toString();
    if (d['seekingGender'] != null) updated.seekingGender = d['seekingGender'].toString();
    if (d['prefAgeFrom'] != null) updated.prefAgeFrom = d['prefAgeFrom'] as int?;
    if (d['prefAgeTo'] != null) updated.prefAgeTo = d['prefAgeTo'] as int?;

    final interests = d['interests'];
    if (interests is List && interests.isNotEmpty) {
      updated.interests = List<String>.from(interests);
    }

    widget.onFilled(updated);
    Navigator.pop(context);
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      color: _bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FadeTransition(
          opacity: _entryFade,
          child: SlideTransition(
            position: _entrySlide,
            child: Column(children: [
              _buildHeader(mq),
              Expanded(child: _buildBody()),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(MediaQueryData mq) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      color: _card,
      padding: EdgeInsets.only(
          top: mq.padding.top + 10, left: 6, right: 16, bottom: 16),
      child: Row(children: [
        IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _primary, size: 20),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 6),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AI Asistent', style: TextStyle(
              color: _primary, fontSize: 22,
              fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        ])),
      ]),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ScreenState.idle:      return _buildIdle();
      case _ScreenState.recording: return _buildRecording();
      case _ScreenState.processing:
      case _ScreenState.transcribing:
      case _ScreenState.parsing:   return _buildProcessing();
      case _ScreenState.done:      return _buildDone();
      case _ScreenState.error:     return _buildError();
    }
  }

  // ── IDLE ─────────────────────────────────────────────────────────────────────
  Widget _buildIdle() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(children: [
        // Ilustracija mikrofona
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _primary.withOpacity(0.10),
            border: Border.all(color: _primary.withOpacity(0.25), width: 2),
          ),
          child: Icon(Icons.mic_rounded, color: _primary, size: 56),
        ),
        const SizedBox(height: 28),
        Text('Opiši se glasom!',
            style: TextStyle(color: _primary, fontSize: 26,
                fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 10),
        Text(
          'AI će automatski popuniti tvoj profil.\nNe moraš spominjati slike — one se dodaju ručno.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _primary.withOpacity(0.55),
              fontSize: 14.5, height: 1.55),
        ),
        const SizedBox(height: 28),

        // Primjeri
        _buildExampleCard(),
        const SizedBox(height: 32),

        // Start gumb
        GestureDetector(
          onTap: _startRecording,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(
                  color: _primary.withOpacity(0.40),
                  blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text('Počni snimati', style: TextStyle(
                  color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildExampleCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primary.withOpacity(0.12)),
        boxShadow: [BoxShadow(
            color: _primary.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.tips_and_updates_rounded, color: _primary, size: 16),
          const SizedBox(width: 8),
          Text('Što možeš reći:',
              style: TextStyle(color: _primary, fontSize: 13.5, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        ..._exampleLines.map((line) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 6, right: 10),
                decoration: BoxDecoration(color: _primary.withOpacity(0.40), shape: BoxShape.circle)),
            Expanded(child: Text(line,
                style: TextStyle(color: _primary.withOpacity(0.65),
                    fontSize: 13, height: 1.5))),
          ]),
        )),
      ]),
    );
  }

  static const _exampleLines = [
    'Imam 24 godine, visok sam 180 cm, muškarac sam s tamnom kosom i smeđim očima.',
    'Volim trčanje, boks i putovanja. Nemam tetovažu ni pirsing.',
    'Tražim žene između 20 i 30 godina. Možeš mi prići s pitanjem o mom omiljenom putovanju.',
  ];

  // ── RECORDING ────────────────────────────────────────────────────────────────
  Widget _buildRecording() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        // Animirani valovi
        AnimatedBuilder(
          animation: _waveCtrl,
          builder: (_, __) => Stack(alignment: Alignment.center, children: [
            // Vanjski val
            Transform.scale(
              scale: 1.0 + 0.25 * math.sin(_waveCtrl.value * 2 * math.pi),
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primary.withOpacity(0.06),
                ),
              ),
            ),
            // Srednji val
            Transform.scale(
              scale: 1.0 + 0.15 * math.sin(_waveCtrl.value * 2 * math.pi + 1),
              child: Container(
                width: 130, height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primary.withOpacity(0.10),
                ),
              ),
            ),
            // Gumb za stop
            GestureDetector(
              onTap: _stopRecording,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Transform.scale(scale: _pulseAnim.value, child: child),
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _primary,
                    boxShadow: [BoxShadow(
                        color: _primary.withOpacity(0.50),
                        blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.stop_rounded, color: Colors.white, size: 42),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 36),
        Text('Snimam...', style: TextStyle(
            color: _primary, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text('Pritisni za zaustavljanje',
            style: TextStyle(color: _primary.withOpacity(0.45), fontSize: 14.5)),
      ]),
    );
  }

  // ── PROCESSING ───────────────────────────────────────────────────────────────
  Widget _buildProcessing() {
    final (icon, label, sub) = switch (_state) {
      _ScreenState.transcribing => (Icons.graphic_eq_rounded,
      'Prepisujem govor...', 'Hvala na strpljenju!'),
      _ScreenState.parsing => (Icons.auto_awesome_rounded,
      'Claude popunjava profil...', 'AI izvlači podatke iz teksta'),
      _ => (Icons.hourglass_empty_rounded, 'Obrađujem...', ''),
    };

    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedBuilder(
          animation: _waveCtrl,
          builder: (_, __) => Transform.rotate(
            angle: _waveCtrl.value * 2 * math.pi,
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: _primary, width: 3, style: BorderStyle.solid),
                gradient: SweepGradient(
                  colors: [_primary.withOpacity(0), _primary],
                  stops: const [0.7, 1.0],
                ),
              ),
              child: Center(child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: _bg),
                child: Icon(icon, color: _primary, size: 34),
              )),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text(label, style: TextStyle(
            color: _primary, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(sub, style: TextStyle(color: _primary.withOpacity(0.45), fontSize: 14)),
        if (_transcript != null) ...[
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _primary.withOpacity(0.12)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Transkript:', style: TextStyle(
                  color: _primary.withOpacity(0.55), fontSize: 11.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('"$_transcript"', style: TextStyle(
                  color: _primary, fontSize: 14, height: 1.5,
                  fontStyle: FontStyle.italic)),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── DONE ─────────────────────────────────────────────────────────────────────
  Widget _buildDone() {
    final d = _parsedData!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Uspjeh header
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.green.shade50, shape: BoxShape.circle,
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Icon(Icons.check_rounded, color: Colors.green.shade600, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Profil popunjen!',
                style: TextStyle(color: _primary, fontSize: 18, fontWeight: FontWeight.w900)),
            Text('Provjeri i ispravi ako je potrebno',
                style: TextStyle(color: _primary.withOpacity(0.45), fontSize: 12.5)),
          ])),
        ]),
        const SizedBox(height: 16),

        // Transkript
        if (_transcript != null) AnimatedContainer(
          duration: const Duration(milliseconds: 380),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _primary.withOpacity(0.12)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Što si rekao/la:',
                style: TextStyle(color: _primary.withOpacity(0.55),
                    fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            Text('"$_transcript"', style: TextStyle(
                color: _primary, fontSize: 13, height: 1.5,
                fontStyle: FontStyle.italic)),
          ]),
        ),
        const SizedBox(height: 18),

        // Parsed fields
        _buildResultSection('Osobni podaci', [
          if (d['birthYear'] != null || d['birthMonth'] != null || d['birthDay'] != null)
            _ResultRow('Datum rođenja',
                '${d['birthDay'] ?? '?'}.${d['birthMonth'] ?? '?'}.${d['birthYear'] ?? '?'}',
                Icons.cake_outlined),
          if (d['height'] != null) _ResultRow('Visina', '${d['height']} cm', Icons.height_rounded),
          if (d['gender'] != null) _ResultRow('Spol', _mapLabel(d['gender'], _genderMap), Icons.person_outline_rounded),
          if (d['hairColor'] != null) _ResultRow('Boja kose', _mapLabel(d['hairColor'], _hairMap), Icons.face_rounded),
          if (d['eyeColor'] != null) _ResultRow('Boja očiju', _mapLabel(d['eyeColor'], _eyeMap), Icons.visibility_outlined),
          if (d['piercing'] != null) _ResultRow('Pirsing', d['piercing'] == 'da' ? 'Da' : 'Ne', Icons.circle_outlined),
          if (d['tattoo'] != null) _ResultRow('Tetovaža', d['tattoo'] == 'da' ? 'Da' : 'Ne', Icons.draw_outlined),
        ]),

        if ((d['interests'] as List?)?.isNotEmpty == true) ...[
          const SizedBox(height: 14),
          _buildResultSection('Interesi', [
            _ResultRow('', (d['interests'] as List).join(', '), Icons.star_outline_rounded),
          ]),
        ],

        if (d['iceBreaker'] != null) ...[
          const SizedBox(height: 14),
          _buildResultSection('Ice breaker', [
            _ResultRow('', '"${d['iceBreaker']}"', Icons.chat_bubble_outline_rounded),
          ]),
        ],

        if (d['seekingGender'] != null || d['prefAgeFrom'] != null) ...[
          const SizedBox(height: 14),
          _buildResultSection('Preference', [
            if (d['seekingGender'] != null) _ResultRow(
                'Tražim', _mapLabel(d['seekingGender'], _seekingMap), Icons.favorite_outline_rounded),
            if (d['prefAgeFrom'] != null && d['prefAgeTo'] != null) _ResultRow(
                'Dob', '${d['prefAgeFrom']} – ${d['prefAgeTo']} god.', Icons.people_outline_rounded),
          ]),
        ],

        const SizedBox(height: 28),

        // Gumbi
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => setState(() {
              _state = _ScreenState.idle;
              _transcript = null;
              _parsedData = null;
            }),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: _primary.withOpacity(0.30), width: 1.5),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.refresh_rounded, color: _primary, size: 18),
                const SizedBox(width: 8),
                Text('Ponovi', style: TextStyle(
                    color: _primary, fontSize: 15, fontWeight: FontWeight.w700)),
              ]),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: GestureDetector(
            onTap: _applyToProfile,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [BoxShadow(
                    color: _primary.withOpacity(0.38),
                    blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Primijeni na profil',
                    style: TextStyle(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
              ]),
            ),
          )),
        ]),
      ]),
    );
  }

  Widget _buildResultSection(String title, List<_ResultRow> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 340),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withOpacity(0.10)),
        boxShadow: [BoxShadow(
            color: _primary.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(title, style: TextStyle(
              color: _primary.withOpacity(0.50),
              fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        ),
        ...rows.asMap().entries.map((e) => Column(children: [
          if (e.key > 0) Divider(height: 1, color: _primary.withOpacity(0.07), indent: 16),
          _buildResultRow(e.value),
        ])),
        const SizedBox(height: 4),
      ]),
    );
  }

  Widget _buildResultRow(_ResultRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Icon(row.icon, color: _primary.withOpacity(0.50), size: 16),
        const SizedBox(width: 10),
        if (row.label.isNotEmpty) ...[
          Text('${row.label}: ', style: TextStyle(
              color: _primary.withOpacity(0.55), fontSize: 13.5)),
        ],
        Expanded(child: Text(row.value,
            style: TextStyle(color: _primary, fontSize: 13.5, fontWeight: FontWeight.w700))),
      ]),
    );
  }

  // ── ERROR ─────────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.red.shade50, shape: BoxShape.circle,
              border: Border.all(color: Colors.redAccent.withOpacity(0.30)),
            ),
            child: const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 38),
          ),
          const SizedBox(height: 20),
          Text('Greška', style: TextStyle(
              color: _primary, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(_errorMsg ?? 'Nepoznata greška',
              textAlign: TextAlign.center,
              style: TextStyle(color: _primary.withOpacity(0.60),
                  fontSize: 14, height: 1.6, fontFamily: 'monospace')),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => setState(() {
              _state = _ScreenState.idle;
              _errorMsg = null;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: _primary, borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(
                    color: _primary.withOpacity(0.35),
                    blurRadius: 14, offset: const Offset(0, 5))],
              ),
              child: const Text('Pokušaj ponovo',
                  style: TextStyle(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Helperi za mape ──────────────────────────────────────────────────────────
  static const _genderMap = {'musko':'Muško','zensko':'Žensko','ostalo':'Ostalo'};
  static const _hairMap = {
    'plava':'Plava','smeda':'Smeđa','crna':'Crna',
    'crvena':'Crvena','sijeda':'Sijeda','ostalo':'Ostalo'
  };
  static const _eyeMap = {'smede':'Smeđe','zelene':'Zelene','plave':'Plave','sive':'Sive'};
  static const _seekingMap = {'musko':'Muško','zensko':'Žensko','sve':'Svejedno'};

  String _mapLabel(dynamic val, Map<String, String> map) =>
      map[val?.toString()] ?? val?.toString() ?? '—';
}

class _ResultRow {
  final String label, value;
  final IconData icon;
  const _ResultRow(this.label, this.value, this.icon);
}