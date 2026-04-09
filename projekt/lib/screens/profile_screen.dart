import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:io' as dart_io;
import 'home_screen.dart'
    show kPrimaryDark, kPrimaryLight, kGradientStart, kGradientEnd;
import 'profile_setup_screen.dart' show ProfileSetupData, ProfileSetupScreen, ProfileStep1, ProfileStep2, ProfileStep3;
import 'onboarding_screen.dart' show globalProfileData;


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {

  List<String> get _photos => globalProfileData.photoPaths.isNotEmpty
      ? globalProfileData.photoPaths
      : ['assets/images/profile_1.png'];

  int _photoIndex = 0;
  late final PageController _pageCtrl;

  double _sheetFrac = 0.50;
  double _dragBase  = 0.50;
  static const double _minFrac = 0.35;
  static const double _maxFrac = 0.80;

  late final AnimationController _entryCtrl;
  late final AnimationController _staggerCtrl;
  late final Animation<double> _photoFade;
  late final Animation<double> _cardFade;
  late final Animation<Offset>  _cardSlide;
  late List<Animation<double>> _chipFade;

  List<String> get _interests => globalProfileData.interests.isNotEmpty
      ? globalProfileData.interests
      : ['Priroda', 'Putovanja', 'Pisanje', 'Boks', 'Kuhanje'];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));

    _photoFade = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut));

    _cardFade = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.28, 1.0, curve: Curves.easeOut));

    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.28, 1.0, curve: Curves.easeOutCubic)));

    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _rebuildChipFade();
    _run();
  }

  void _rebuildChipFade() {
    final count = _interests.length;
    _chipFade = List.generate(count, (i) {
      final s = (i * 0.14).clamp(0.0, 0.85);
      final e = (s + 0.55).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _staggerCtrl,
          curve: Interval(s, e, curve: Curves.easeOutBack));
    });
  }

  Future<void> _run() async {
    await Future.delayed(const Duration(milliseconds: 60));
    _entryCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _staggerCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _entryCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails _) {
    _dragBase = _sheetFrac;
    HapticFeedback.selectionClick();
  }

  void _onDragUpdate(DragUpdateDetails d, double screenH) {
    setState(() {
      _sheetFrac = (_dragBase - d.primaryDelta! / screenH).clamp(_minFrac, _maxFrac);
    });
  }

  void _onDragEnd(DragEndDetails d) {
    final vel = -(d.primaryVelocity ?? 0) / 1000;
    final mid = (_minFrac + _maxFrac) / 2;
    double target;
    if (vel > 0.25)       target = _maxFrac;
    else if (vel < -0.25) target = _minFrac;
    else                  target = _sheetFrac > mid ? _maxFrac : _minFrac;
    HapticFeedback.lightImpact();
    _snapTo(target);
  }

  void _snapTo(double target) {
    final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    final from = _sheetFrac;
    ctrl
      ..addListener(() => setState(() =>
      _sheetFrac = lerpDouble(from, target,
          Curves.easeOutCubic.transform(ctrl.value))!))
      ..addStatusListener((s) { if (s == AnimationStatus.completed) ctrl.dispose(); })
      ..forward();
  }

  void _openSetup() {
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => ProfileSetupScreen(
        initial: globalProfileData.copy(),
        onSave: (saved) {
          setState(() {
            globalProfileData = saved;
            _photoIndex = 0;
            _rebuildChipFade();
            _staggerCtrl.reset();
            _staggerCtrl.forward();
          });
        },
      ),
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 420),
    ));
  }

  String get _displayName {
    final username = globalProfileData.photoPaths.isNotEmpty ? 'Lorna' : 'Lorna';
    if (globalProfileData.birthYear != null) {
      final age = DateTime.now().year - globalProfileData.birthYear!;
      return '$username, $age';
    }
    return username;
  }

  @override
  Widget build(BuildContext context) {
    final mq      = MediaQuery.of(context);
    final screenH = mq.size.height;
    final double sheetTop = screenH * (1.0 - _sheetFrac);
    final photos    = _photos;
    final interests = _interests;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(children: [

          // PHOTOS
          Positioned(
            top: 0, left: 0, right: 0, height: sheetTop + 2,
            child: FadeTransition(
              opacity: _photoFade,
              child: PageView.builder(
                controller: _pageCtrl,
                physics: const ClampingScrollPhysics(),
                itemCount: photos.length,
                onPageChanged: (i) => setState(() => _photoIndex = i),
                itemBuilder: (_, i) {
                  final path = photos[i];
                  return _isAsset(path)
                      ? Image.asset(path, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackPhoto())
                      : Image.file(dart_io.File(path), fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackPhoto());
                },
              ),
            ),
          ),

          // gradient overlay
          Positioned(
            left: 0, right: 0, top: sheetTop - 180, height: 210,
            child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, kPrimaryDark.withOpacity(0.22), kPrimaryDark.withOpacity(0.52)],
              ),
            ))),
          ),

          // page dots
          Positioned(
            left: 0, right: 0, bottom: screenH - sheetTop + 52,
            child: IgnorePointer(child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(photos.length, (i) {
                final active = i == _photoIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6, height: 6,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            )),
          ),

          // name
          Positioned(
            left: 0, right: 0, bottom: screenH - sheetTop + 14,
            child: IgnorePointer(child: Text(
              _displayName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                shadows: [Shadow(color: Colors.black.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 2))],
              ),
            )),
          ),

          // CARD
          Positioned(
            top: sheetTop, left: 0, right: 0, bottom: 0,
            child: FadeTransition(
              opacity: _cardFade,
              child: SlideTransition(
                position: _cardSlide,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: _onDragStart,
                  onVerticalDragUpdate: (d) => _onDragUpdate(d, screenH),
                  onVerticalDragEnd: _onDragEnd,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 18, offset: Offset(0, -3))],
                    ),
                    child: Stack(children: [
                      Column(children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 36, height: 4,
                          decoration: BoxDecoration(
                            color: kPrimaryDark.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(20, 14, 20, mq.padding.bottom + 80),
                            child: _CardBody(
                              chipFade: _chipFade,
                              interests: interests,
                              data: globalProfileData,
                            ),
                          ),
                        ),
                      ]),
                      Positioned(
                        bottom: mq.padding.bottom + 20, left: 0, right: 0,
                        child: Center(child: _EditBtn(onTap: _openSetup)),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          // back button
          Positioned(
            top: mq.padding.top + 15, left: 14,
            child: FadeTransition(
              opacity: _photoFade,
              child: _BackBtn(onTap: () => Navigator.pop(context)),
            ),
          ),
        ]),
      ),
    );
  }

  bool _isAsset(String path) => path.startsWith('assets/');

  Widget _fallbackPhoto() => Container(
    decoration: BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [const Color(0xFFD9C5BF), const Color(0xFFBF9090), kPrimaryDark],
    )),
    child: Icon(Icons.person_rounded, size: 110, color: Colors.white.withOpacity(0.18)),
  );
}

// ── CARD BODY ─────────────────────────────────────────────────────────────────

class _CardBody extends StatelessWidget {
  final List<Animation<double>> chipFade;
  final List<String> interests;
  final ProfileSetupData data;
  const _CardBody({required this.chipFade, required this.interests, required this.data});

  static const _emojiMap = {
    'Crtanje': '🎨', 'Fotografija': '📸', 'Pisanje': '✍️', 'Film': '🎬',
    'Trčanje': '🏃‍♀️', 'Biciklizam': '🚴', 'Planinarenje': '🥾', 'Teretana': '🏋️',
    'Boks': '🥊', 'Tenis': '🎾', 'Nogomet': '⚽', 'Odbojka': '🏐',
    'Kuhanje': '👨‍🍳', 'Putovanja': '✈️', 'Gaming': '🎮', 'Formula': '🏎️',
    'Glazba': '🎵', 'Priroda': '🌿',
  };

  @override
  Widget build(BuildContext context) {
    final iceBreaker = data.iceBreaker.isNotEmpty
        ? data.iceBreaker : 'Pitaj me kakvu kavu pijem.';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Želim da mi priđeš...',
          style: TextStyle(color: kPrimaryDark, fontSize: 12.5, fontWeight: FontWeight.w500)),
      const SizedBox(height: 5),
      Text(iceBreaker, style: const TextStyle(
          color: Color(0xFF1C1C1E), fontSize: 15.5, fontWeight: FontWeight.w700, height: 1.3)),
      const SizedBox(height: 22),
      Divider(color: kPrimaryDark.withOpacity(0.10), thickness: 0.8, height: 1),
      const SizedBox(height: 18),
      Text('Interesi', style: TextStyle(
          color: kPrimaryDark, fontSize: 12.5, fontWeight: FontWeight.w500)),
      const SizedBox(height: 11),
      Wrap(
        spacing: 7, runSpacing: 7,
        children: List.generate(interests.length, (i) {
          final anim = i < chipFade.length ? chipFade[i] : chipFade.last;
          return AnimatedBuilder(
            animation: anim,
            builder: (_, __) {
              final t = anim.value.clamp(0.0, 1.0);
              return Opacity(opacity: t,
                child: Transform.scale(scale: 0.6 + 0.4 * t,
                  child: _Chip(
                    label: interests[i],
                    emoji: _emojiMap[interests[i]] ?? '✨',
                  ),
                ),
              );
            },
          );
        }),
      ),
      const SizedBox(height: 24),
      Divider(color: kPrimaryDark.withOpacity(0.10), thickness: 0.8, height: 1),
      const SizedBox(height: 18),
      Text('Osobni podaci', style: TextStyle(
          color: kPrimaryDark, fontSize: 12.5, fontWeight: FontWeight.w500)),
      const SizedBox(height: 12),
      if (data.birthYear != null)
        _DataRow(icon: Icons.cake_outlined, label: 'Godine',
            value: '${DateTime.now().year - data.birthYear!}'),
      if (data.birthYear == null)
        _DataRow(icon: Icons.cake_outlined, label: 'Godine', value: '22'),
      Divider(color: kPrimaryDark.withOpacity(0.08), thickness: 0.5, height: 1, indent: 28),
      _DataRow(icon: Icons.height_rounded, label: 'Visina',
          value: data.height != null ? '${data.height} cm' : '172 cm'),
    ]);
  }
}

class _Chip extends StatefulWidget {
  final String label, emoji;
  const _Chip({required this.label, required this.emoji});
  @override State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeIn));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) => _c.reverse(),
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(scale: _s,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD5C0C4), width: 1.1),
          ),
          child: Text('${widget.label} ${widget.emoji}',
              style: const TextStyle(color: Color(0xFF1C1C1E), fontSize: 13, fontWeight: FontWeight.w400)),
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DataRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Icon(icon, color: kPrimaryDark, size: 18),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(
            color: Color(0xFF1C1C1E), fontSize: 14, fontWeight: FontWeight.w700)),
        const Spacer(),
        Text(value, style: TextStyle(
            color: kPrimaryDark.withOpacity(0.55), fontSize: 14, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ── BACK BUTTON ───────────────────────────────────────────────────────────────

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
        child: ClipRRect(borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.38), width: 1),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 15),
            ),
          ),
        ),
      ),
    );
  }
}

// ── EDIT BUTTON ───────────────────────────────────────────────────────────────

class _EditBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _EditBtn({required this.onTap});
  @override State<_EditBtn> createState() => _EditBtnState();
}

class _EditBtnState extends State<_EditBtn> with SingleTickerProviderStateMixin {
  late final AnimationController _shim;
  bool _pressed = false;
  @override void initState() {
    super.initState();
    _shim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  }
  @override void dispose() { _shim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { setState(() => _pressed = true); HapticFeedback.lightImpact(); },
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 26),
          decoration: BoxDecoration(
            color: kPrimaryDark, borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(
                color: kPrimaryDark.withOpacity(0.30), blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(alignment: Alignment.center, children: [
              AnimatedBuilder(
                animation: _shim,
                builder: (_, __) => Transform.translate(
                  offset: Offset((_shim.value * 2 - 0.5) * 140, 0),
                  child: Container(width: 40,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.0),
                    ])),
                  ),
                ),
              ),
              const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text('Uredi profil', style: TextStyle(
                    color: Colors.white, fontSize: 13.5,
                    fontWeight: FontWeight.w700, letterSpacing: 0.2)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}