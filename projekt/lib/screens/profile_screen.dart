import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'home_screen.dart'
    show kPrimaryDark, kPrimaryLight, kGradientStart, kGradientEnd;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {

  // ── photos (add/remove paths here, min 2 max 6) ───────────────────────────
  static const _photos = [
    'assets/images/profile_1.png',
    'assets/images/profile_2.png',
    'assets/images/profile_3.png',
  ];
  int _photoIndex = 0;
  late final PageController _pageCtrl;

  // ── sheet drag ─────────────────────────────────────────────────────────────
  double _sheetFrac = 0.50;
  double _dragBase  = 0.50;
  static const double _minFrac = 0.35;
  static const double _maxFrac = 0.80;

  // ── animations ─────────────────────────────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final AnimationController _staggerCtrl;
  late final Animation<double> _photoFade;
  late final Animation<double> _cardFade;
  late final Animation<Offset>  _cardSlide;
  late final List<Animation<double>> _chipFade;

  static const _interests = [
    ('Priroda',   '🌿'),
    ('Putovanja', '✈️'),
    ('Pisanje',   '✍️'),
    ('Boks',      '🥊'),
    ('Kuhanje',   '👨‍🍳'),
  ];

  @override
  void initState() {
    super.initState();

    _pageCtrl = PageController();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));

    _photoFade = CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut));

    _cardFade = CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.28, 1.0, curve: Curves.easeOut));

    _cardSlide = Tween<Offset>(
        begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.28, 1.0, curve: Curves.easeOutCubic)));

    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _chipFade = List.generate(_interests.length, (i) {
      final s = i * 0.14;
      final e = (s + 0.55).clamp(0.0, 1.0);
      return CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(s, e, curve: Curves.easeOutBack));
    });

    _run();
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

  // ── sheet drag ─────────────────────────────────────────────────────────────
  void _onDragStart(DragStartDetails _) {
    _dragBase = _sheetFrac;
    HapticFeedback.selectionClick();
  }

  void _onDragUpdate(DragUpdateDetails d, double screenH) {
    setState(() {
      _sheetFrac = (_dragBase - d.primaryDelta! / screenH)
          .clamp(_minFrac, _maxFrac);
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
    final ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    final from = _sheetFrac;
    ctrl
      ..addListener(() => setState(() =>
      _sheetFrac = lerpDouble(
          from, target, Curves.easeOutCubic.transform(ctrl.value))!))
      ..addStatusListener(
              (s) { if (s == AnimationStatus.completed) ctrl.dispose(); })
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final mq      = MediaQuery.of(context);
    final screenH = mq.size.height;
    final screenW = mq.size.width;
    final double sheetTop = screenH * (1.0 - _sheetFrac);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [

            // ── LAYER 0: PHOTO CAROUSEL (only covers photo zone, not card) ───
            Positioned(
              top: 0, left: 0, right: 0,
              // height = sheetTop + small overlap so no gap appears
              height: sheetTop + 2,
              child: FadeTransition(
                opacity: _photoFade,
                child: PageView.builder(
                  controller: _pageCtrl,
                  // Use ClampingScrollPhysics so horizontal swipe
                  // doesn't conflict with vertical sheet drag
                  physics: const ClampingScrollPhysics(),
                  itemCount: _photos.length,
                  onPageChanged: (i) => setState(() => _photoIndex = i),
                  itemBuilder: (_, i) => Image.asset(
                    _photos[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFFD9C5BF),
                            const Color(0xFFBF9090),
                            kPrimaryDark,
                          ],
                        ),
                      ),
                      child: Icon(Icons.person_rounded,
                          size: 110,
                          color: Colors.white.withOpacity(0.18)),
                    ),
                  ),
                ),
              ),
            ),

            // ── LAYER 1: GRADIENT FADE — bottom of photo → transparent ───────
            Positioned(
              left: 0, right: 0,
              top: sheetTop - 180,
              height: 210,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        kPrimaryDark.withOpacity(0.22),
                        kPrimaryDark.withOpacity(0.52),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── LAYER 2: DOTS INDICATOR ───────────────────────────────────────
            Positioned(
              left: 0, right: 0,
              bottom: screenH - sheetTop + 52,
              child: IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_photos.length, (i) {
                    final active = i == _photoIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width:  active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // ── LAYER 3: NAME ─────────────────────────────────────────────────
            Positioned(
              left: 0, right: 0,
              bottom: screenH - sheetTop + 14,
              child: IgnorePointer(
                child: Text(
                  'Lorna',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── LAYER 4: WHITE CARD ───────────────────────────────────────────
            Positioned(
              top: sheetTop,
              left: 0, right: 0, bottom: 0,
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
                        borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x18000000),
                            blurRadius: 18,
                            offset: Offset(0, -3),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // scrollable content
                          Column(
                            children: [
                              const SizedBox(height: 10),
                              // drag handle
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
                                  padding: EdgeInsets.fromLTRB(
                                      20, 14, 20,
                                      mq.padding.bottom + 80),
                                  child: _CardBody(chipFade: _chipFade),
                                ),
                              ),
                            ],
                          ),
                          // edit button pinned to bottom-center
                          Positioned(
                            bottom: mq.padding.bottom + 20,
                            left: 0, right: 0,
                            child: Center(child: _EditBtn()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── LAYER 5: BACK BUTTON ──────────────────────────────────────────
            Positioned(
              top: mq.padding.top + 15,
              left: 14,
              child: FadeTransition(
                opacity: _photoFade,
                child: _BackBtn(onTap: () => Navigator.pop(context)),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD BODY
// ─────────────────────────────────────────────────────────────────────────────
class _CardBody extends StatelessWidget {
  final List<Animation<double>> chipFade;
  static const _interests = [
    ('Priroda',   '🌿'),
    ('Putovanja', '✈️'),
    ('Pisanje',   '✍️'),
    ('Boks',      '🥊'),
    ('Kuhanje',   '👨‍🍳'),
  ];

  const _CardBody({required this.chipFade});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text('Želim da mi priđeš...',
            style: TextStyle(
              color: kPrimaryDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            )),
        const SizedBox(height: 5),
        const Text('Pitaj me kakvu kavu pijem.',
            style: TextStyle(
              color: Color(0xFF1C1C1E),
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              height: 1.3,
            )),

        const SizedBox(height: 22),
        _div(),
        const SizedBox(height: 18),

        Text('Interesi',
            style: TextStyle(
              color: kPrimaryDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            )),
        const SizedBox(height: 11),

        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: List.generate(_interests.length, (i) {
            return AnimatedBuilder(
              animation: chipFade[i],
              builder: (_, __) {
                final t = chipFade[i].value.clamp(0.0, 1.0);
                return Opacity(
                  opacity: t,
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * t,
                    child: _Chip(
                      label: _interests[i].$1,
                      emoji: _interests[i].$2,
                    ),
                  ),
                );
              },
            );
          }),
        ),

        const SizedBox(height: 24),
        _div(),
        const SizedBox(height: 18),

        Text('Osobni podaci',
            style: TextStyle(
              color: kPrimaryDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            )),
        const SizedBox(height: 12),

        _DataRow(icon: Icons.cake_outlined,  label: 'Godine', value: '22'),
        Divider(color: kPrimaryDark.withOpacity(0.08),
            thickness: 0.5, height: 1, indent: 28),
        _DataRow(icon: Icons.height_rounded, label: 'Visina', value: '172 cm'),
      ],
    );
  }

  Widget _div() => Divider(
      color: kPrimaryDark.withOpacity(0.10), thickness: 0.8, height: 1);
}

// ─────────────────────────────────────────────────────────────────────────────
// INTEREST CHIP
// ─────────────────────────────────────────────────────────────────────────────
class _Chip extends StatefulWidget {
  final String label;
  final String emoji;
  const _Chip({required this.label, required this.emoji});

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeIn));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_)   => _c.reverse(),
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD5C0C4), width: 1.1),
          ),
          child: Text(
            '${widget.label} ${widget.emoji}',
            style: const TextStyle(
              color: Color(0xFF1C1C1E),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA ROW
// ─────────────────────────────────────────────────────────────────────────────
class _DataRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _DataRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryDark, size: 18),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                color: Color(0xFF1C1C1E),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              )),
          const Spacer(),
          Text(value,
              style: TextStyle(
                color: kPrimaryDark.withOpacity(0.55),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BACK BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _BackBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});

  @override
  State<_BackBtn> createState() => _BackBtnState();
}

class _BackBtnState extends State<_BackBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 90));
    _s = Tween<double>(begin: 1.0, end: 0.86)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeIn));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_)   { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withOpacity(0.38), width: 1),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 15),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _EditBtn extends StatefulWidget {
  @override
  State<_EditBtn> createState() => _EditBtnState();
}

class _EditBtnState extends State<_EditBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _shim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
  }

  @override
  void dispose() { _shim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { setState(() => _pressed = true); HapticFeedback.lightImpact(); },
      onTapUp: (_)   => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 26),
          decoration: BoxDecoration(
            color: kPrimaryDark,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: kPrimaryDark.withOpacity(0.30),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _shim,
                  builder: (_, __) => Transform.translate(
                    offset: Offset((_shim.value * 2 - 0.5) * 140, 0),
                    child: Container(
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.12),
                          Colors.white.withOpacity(0.0),
                        ]),
                      ),
                    ),
                  ),
                ),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text('Uredi profil',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}