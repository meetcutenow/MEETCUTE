import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'home_screen.dart' show kPrimaryDark, kPrimaryLight, kSurface;

// ═══════════════════════════════════════════════════════════════════════════════
// PROFILE DATA MODEL
// ═══════════════════════════════════════════════════════════════════════════════

class ProfileSetupData {
  List<String> photoPaths;
  int?    birthDay;
  int?    birthMonth;
  int?    birthYear;
  String? height;
  String? hairColor;
  String? eyeColor;
  String? piercing;
  String? tattoo;
  String? gender;
  List<String> interests;
  String iceBreaker;

  ProfileSetupData({
    List<String>? photoPaths,
    this.birthDay,
    this.birthMonth,
    this.birthYear,
    this.height,
    this.hairColor,
    this.eyeColor,
    this.piercing,
    this.tattoo,
    this.gender,
    List<String>? interests,
    this.iceBreaker = '',
  })  : photoPaths = photoPaths ?? [],
        interests  = interests  ?? [];

  ProfileSetupData copy() => ProfileSetupData(
    photoPaths:  List.from(photoPaths),
    birthDay:    birthDay,
    birthMonth:  birthMonth,
    birthYear:   birthYear,
    height:      height,
    hairColor:   hairColor,
    eyeColor:    eyeColor,
    piercing:    piercing,
    tattoo:      tattoo,
    gender:      gender,
    interests:   List.from(interests),
    iceBreaker:  iceBreaker,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROFILE SETUP SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class ProfileSetupScreen extends StatefulWidget {
  final ProfileSetupData? initial;
  final void Function(ProfileSetupData) onSave;

  const ProfileSetupScreen({
    super.key,
    this.initial,
    required this.onSave,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with TickerProviderStateMixin {

  int _step = 0;
  late ProfileSetupData _data;

  late AnimationController _progressCtrl;
  late AnimationController _pageCtrl;
  late Animation<Offset> _pageSlide;

  @override
  void initState() {
    super.initState();
    _data = widget.initial?.copy() ?? ProfileSetupData(
      photoPaths: ['assets/images/profile_1.png', 'assets/images/profile_2.png'],
    );
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 0.0,
    );
    _pageCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _pageSlide = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOutCubic));
    _pageCtrl.value = 1.0;
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_step == 2) {
      widget.onSave(_data);
      Navigator.pop(context);
      return;
    }
    HapticFeedback.lightImpact();
    _pageCtrl.reset();
    _pageCtrl.forward();
    setState(() => _step++);
    _progressCtrl.animateTo(
      (_step + 1) / 3,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        _Header(step: _step, progressCtrl: _progressCtrl, mq: mq),
        Expanded(
          child: SlideTransition(
            position: _pageSlide,
            child: _buildStepContent(mq),
          ),
        ),
        _NextButton(step: _step, onTap: _goNext, mq: mq),
      ]),
    );
  }

  Widget _buildStepContent(MediaQueryData mq) {
    switch (_step) {
      case 0: return _Step1(
        data: _data,
        onChange: (d) => setState(() => _data = d),
        mq: mq,
      );
      case 1: return _Step2(
        data: _data,
        onChange: (d) => setState(() => _data = d),
      );
      default: return _Step3(
        data: _data,
        onChange: (d) => setState(() => _data = d),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final int step;
  final AnimationController progressCtrl;
  final MediaQueryData mq;
  const _Header({required this.step, required this.progressCtrl, required this.mq});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: mq.padding.top + 16,
        left: 22, right: 22, bottom: 16,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'Izrada profila',
          style: TextStyle(
            color: kPrimaryDark,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 14),
        AnimatedBuilder(
          animation: progressCtrl,
          builder: (_, __) {
            return LayoutBuilder(builder: (_, box) {
              final filled = box.maxWidth * progressCtrl.value;
              return Container(
                height: 8,
                decoration: BoxDecoration(
                  color: kPrimaryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: filled.clamp(0.0, box.maxWidth),
                    decoration: BoxDecoration(
                      color: kPrimaryDark,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ]),
              );
            });
          },
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// NEXT BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class _NextButton extends StatefulWidget {
  final int step;
  final VoidCallback onTap;
  final MediaQueryData mq;
  const _NextButton({required this.step, required this.onTap, required this.mq});
  @override State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeIn));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final label = widget.step == 2 ? 'Završetak' : 'Iduće';
    return Padding(
      padding: EdgeInsets.only(bottom: widget.mq.padding.bottom + 16, top: 10),
      child: Center(
        child: GestureDetector(
          onTapDown: (_) => _c.forward(),
          onTapUp: (_) { _c.reverse(); widget.onTap(); },
          onTapCancel: () => _c.reverse(),
          child: ScaleTransition(
            scale: _s,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: kPrimaryDark,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryDark.withOpacity(0.30),
                    blurRadius: 16, offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 1 — Photos + personal info
// ═══════════════════════════════════════════════════════════════════════════════

class _Step1 extends StatefulWidget {
  final ProfileSetupData data;
  final void Function(ProfileSetupData) onChange;
  final MediaQueryData mq;
  const _Step1({required this.data, required this.onChange, required this.mq});
  @override State<_Step1> createState() => _Step1State();
}

class _Step1State extends State<_Step1> {
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _heightCtrl;
  late final TextEditingController _dayCtrl;
  late final TextEditingController _monthCtrl;
  late final TextEditingController _yearCtrl;

  // 'rusa' maknuta
  static const _hairOptions  = ['plava', 'smeđa', 'crna', 'crvena', 'sijeda', 'ostalo'];
  // 'zelenkasto-smeđe' i 'ostalo' maknuti
  static const _eyeOptions   = ['smeđe', 'zelene', 'plave', 'sive'];
  static const _yesNo        = ['da', 'ne'];
  static const _genderOptions = ['žensko', 'muško', 'ostalo'];

  @override
  void initState() {
    super.initState();
    _heightCtrl = TextEditingController(text: widget.data.height ?? '');
    _dayCtrl    = TextEditingController(text: widget.data.birthDay?.toString() ?? '');
    _monthCtrl  = TextEditingController(text: widget.data.birthMonth?.toString() ?? '');
    _yearCtrl   = TextEditingController(text: widget.data.birthYear?.toString() ?? '');
  }

  @override
  void dispose() {
    _heightCtrl.dispose(); _dayCtrl.dispose();
    _monthCtrl.dispose();  _yearCtrl.dispose();
    super.dispose();
  }

  void _update(ProfileSetupData Function(ProfileSetupData) fn) =>
      widget.onChange(fn(widget.data.copy()));

  Future<void> _pickPhoto(int idx) async {
    final xFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xFile == null) return;
    _update((d) {
      if (idx < d.photoPaths.length) d.photoPaths[idx] = xFile.path;
      else d.photoPaths.add(xFile.path);
      return d;
    });
  }

  Future<void> _addPhoto() async {
    if (widget.data.photoPaths.length >= 6) return;
    final xFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xFile == null) return;
    HapticFeedback.lightImpact();
    _update((d) { d.photoPaths.add(xFile.path); return d; });
  }

  void _removePhoto(int idx) {
    if (widget.data.photoPaths.length <= 1) return;
    HapticFeedback.mediumImpact();
    _update((d) { d.photoPaths.removeAt(idx); return d; });
  }

  bool _isAsset(String path) => path.startsWith('assets/');

  Widget _emptyPhotoContent() => Center(
    child: Icon(Icons.add_a_photo_rounded, color: kPrimaryDark.withOpacity(0.28), size: 28),
  );

  Widget _photoSlot(int idx) {
    final photos = widget.data.photoPaths;
    final hasPhoto = idx < photos.length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => _pickPhoto(idx),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: kPrimaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kPrimaryDark.withOpacity(0.10), width: 1),
            ),
            child: hasPhoto
                ? ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Stack(fit: StackFit.expand, children: [
                _isAsset(photos[idx])
                    ? Image.asset(photos[idx], fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _emptyPhotoContent())
                    : Image.file(File(photos[idx]), fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _emptyPhotoContent()),
                Positioned(
                  bottom: 4, right: 4,
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4)],
                    ),
                    child: Icon(Icons.edit_rounded, color: kPrimaryDark, size: 13),
                  ),
                ),
              ]),
            )
                : _emptyPhotoContent(),
          ),
        ),
        // X gumb — prikazan samo kad postoji foto i ima ih više od 1
        if (hasPhoto && photos.length > 1)
          Positioned(
            top: -8, right: -8,
            child: GestureDetector(
              onTap: () => _removePhoto(idx),
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: Colors.redAccent, shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 4)],
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 13),
              ),
            ),
          ),
      ],
    );
  }

  Widget _addSlot() => GestureDetector(
    onTap: _addPhoto,
    child: Container(
      decoration: BoxDecoration(
        color: kPrimaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kPrimaryDark.withOpacity(0.18), width: 1.5),
      ),
      child: Center(child: Icon(Icons.add_rounded, color: kPrimaryDark, size: 36)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final photos = d.photoPaths;
    final hairValue = _hairOptions.contains(d.hairColor) ? d.hairColor : null;
    final eyeValue  = _eyeOptions.contains(d.eyeColor)   ? d.eyeColor  : null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── PHOTO ROW ───────────────────────────────────────────────────────
        SizedBox(
          height: 156,
          child: Row(children: [
            Expanded(child: _photoSlot(0)),
            const SizedBox(width: 10),
            Expanded(
              child: photos.length >= 2 ? _photoSlot(1) : _addSlot(),
            ),
            if (photos.length >= 2) ...[
              const SizedBox(width: 10),
              Expanded(
                child: photos.length >= 3 ? _photoSlot(2) : _addSlot(),
              ),
            ],
            if (photos.length >= 3 && photos.length < 6) ...[
              const SizedBox(width: 10),
              Expanded(child: _addSlot()),
            ],
          ]),
        ),

        const SizedBox(height: 22),
        _label('Datum rođenja:'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _textField(ctrl: _dayCtrl, hint: 'DD', keyboardType: TextInputType.number,
              onChanged: (v) => _update((d) { d.birthDay = int.tryParse(v); return d; }))),
          const SizedBox(width: 8),
          Expanded(child: _textField(ctrl: _monthCtrl, hint: 'MM', keyboardType: TextInputType.number,
              onChanged: (v) => _update((d) { d.birthMonth = int.tryParse(v); return d; }))),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: _textField(ctrl: _yearCtrl, hint: 'GGGG', keyboardType: TextInputType.number,
              onChanged: (v) => _update((d) { d.birthYear = int.tryParse(v); return d; }))),
        ]),

        const SizedBox(height: 16),
        _label('Visina:'),
        const SizedBox(height: 8),
        _textField(ctrl: _heightCtrl, hint: '168', keyboardType: TextInputType.number,
            onChanged: (v) => _update((d) { d.height = v; return d; })),

        const SizedBox(height: 16),
        _label('Spol:'),
        const SizedBox(height: 8),
        _dropdown(value: d.gender, hint: 'odaberi', items: _genderOptions,
            onChanged: (v) => _update((dd) { dd.gender = v; return dd; })),

        const SizedBox(height: 16),
        _label('Boja kose:'),
        const SizedBox(height: 8),
        _dropdown(value: hairValue, hint: 'odaberi', items: _hairOptions,
            onChanged: (v) => _update((dd) { dd.hairColor = v; return dd; })),

        const SizedBox(height: 16),
        _label('Boja očiju:'),
        const SizedBox(height: 8),
        _dropdown(value: eyeValue, hint: 'odaberi', items: _eyeOptions,
            onChanged: (v) => _update((dd) { dd.eyeColor = v; return dd; })),

        const SizedBox(height: 16),
        _label('Pirsing:'),
        const SizedBox(height: 8),
        _dropdown(value: d.piercing, hint: 'odaberi', items: _yesNo,
            onChanged: (v) => _update((dd) { dd.piercing = v; return dd; })),

        const SizedBox(height: 16),
        _label('Tetovaža:'),
        const SizedBox(height: 8),
        _dropdown(value: d.tattoo, hint: 'odaberi', items: _yesNo,
            onChanged: (v) => _update((dd) { dd.tattoo = v; return dd; })),
      ]),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(color: kPrimaryDark, fontSize: 14.5, fontWeight: FontWeight.w600));

  Widget _textField({
    required TextEditingController ctrl, required String hint,
    TextInputType? keyboardType, required void Function(String) onChanged,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryDark.withOpacity(0.15), width: 1.2),
      ),
      child: TextField(
        controller: ctrl, keyboardType: keyboardType, onChanged: onChanged,
        style: TextStyle(color: kPrimaryDark, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: kPrimaryDark.withOpacity(0.30), fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          isDense: true,
        ),
      ),
    );
  }

  Widget _dropdown({
    required String? value, required String hint,
    required List<String> items, required void Function(String?) onChanged,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryDark.withOpacity(0.15), width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: kPrimaryDark.withOpacity(0.30), fontSize: 15)),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: kPrimaryDark.withOpacity(0.45)),
          style: TextStyle(color: kPrimaryDark, fontSize: 15, fontFamily: 'SF Pro Display'),
          dropdownColor: Colors.white, borderRadius: BorderRadius.circular(12),
          onChanged: onChanged,
          items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 2 — Interests
// ═══════════════════════════════════════════════════════════════════════════════

class _Step2 extends StatefulWidget {
  final ProfileSetupData data;
  final void Function(ProfileSetupData) onChange;
  const _Step2({required this.data, required this.onChange});
  @override State<_Step2> createState() => _Step2State();
}

class _Step2State extends State<_Step2> with TickerProviderStateMixin {

  static const _allInterests = [
    ('Crtanje',    '🎨'), ('Fotografija','📸'), ('Pisanje',    '✍️'),
    ('Film',       '🎬'), ('Trčanje',    '🏃‍♀️'), ('Biciklizam', '🚴'),
    ('Planinarenje','🥾'), ('Teretana',  '🏋️'), ('Boks',       '🥊'),
    ('Tenis',      '🎾'), ('Nogomet',   '⚽'),  ('Odbojka',    '🏐'),
    ('Kuhanje',    '👨‍🍳'), ('Putovanja', '✈️'),  ('Gaming',     '🎮'),
    ('Formula',    '🏎️'), ('Glazba',    '🎵'),
  ];

  late final List<AnimationController> _tapCtrls;

  @override
  void initState() {
    super.initState();
    _tapCtrls = List.generate(_allInterests.length,
            (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 100)));
  }

  @override
  void dispose() {
    for (final c in _tapCtrls) c.dispose();
    super.dispose();
  }

  void _toggle(int idx) {
    final name = _allInterests[idx].$1;
    final copy = widget.data.copy();
    if (copy.interests.contains(name)) copy.interests.remove(name);
    else copy.interests.add(name);
    widget.onChange(copy);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.data.interests;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
        child: Text('Odaberi svoje interese:',
            style: TextStyle(color: kPrimaryDark.withOpacity(0.55), fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      Expanded(
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.05,
          ),
          itemCount: _allInterests.length,
          itemBuilder: (_, i) {
            final (name, emoji) = _allInterests[i];
            final isSel = selected.contains(name);
            return GestureDetector(
              onTapDown: (_) => _tapCtrls[i].forward(),
              onTapUp: (_) { _tapCtrls[i].reverse(); _toggle(i); },
              onTapCancel: () => _tapCtrls[i].reverse(),
              child: AnimatedBuilder(
                animation: _tapCtrls[i],
                builder: (_, __) => Transform.scale(
                  scale: 1.0 - _tapCtrls[i].value * 0.04,
                  child: _InterestCell(name: name, emoji: emoji, isSelected: isSel,
                      onRemove: isSel ? () => _toggle(i) : null),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _InterestCell extends StatelessWidget {
  final String name, emoji;
  final bool isSelected;
  final VoidCallback? onRemove;
  const _InterestCell({required this.name, required this.emoji,
    required this.isSelected, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: isSelected ? kPrimaryLight : kPrimaryLight.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isSelected ? kPrimaryDark.withOpacity(0.20) : Colors.transparent, width: 1.2),
        boxShadow: isSelected
            ? [BoxShadow(color: kPrimaryDark.withOpacity(0.10), blurRadius: 12, offset: const Offset(0, 4))]
            : [],
      ),
      child: Stack(children: [
        Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 8),
          Text(name, style: TextStyle(color: kPrimaryDark, fontSize: 15, fontWeight: FontWeight.w700)),
        ])),
        if (isSelected && onRemove != null)
          Positioned(
            top: 6, right: 6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4)],
                ),
                child: Icon(Icons.close_rounded, size: 14, color: kPrimaryDark),
              ),
            ),
          ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 3 — Ice-breaker
//
// POPRAVCI:
//   1) _stopEdit() poziva widget.onChange → iceBreaker se propagira u _data
//      i dalje u _globalProfileData (kroz onSave u profile_screen)
//   2) Gumb je desno i PRELAZI oba pravokutnika:
//      koristi LayoutBuilder + Stack + Positioned(top: boundary - fabSize/2)
//      gdje je boundary = totalHeight * 5/12 (flex 5 od ukupno 12)
// ═══════════════════════════════════════════════════════════════════════════════

class _Step3 extends StatefulWidget {
  final ProfileSetupData data;
  final void Function(ProfileSetupData) onChange;
  const _Step3({required this.data, required this.onChange});
  @override State<_Step3> createState() => _Step3State();
}

class _Step3State extends State<_Step3> with SingleTickerProviderStateMixin {
  bool _editing = false;
  late TextEditingController _ctrl;
  late FocusNode _focus;
  late AnimationController _editBounce;

  @override
  void initState() {
    super.initState();
    _ctrl       = TextEditingController(text: widget.data.iceBreaker);
    _focus      = FocusNode();
    _editBounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _ctrl.dispose(); _focus.dispose(); _editBounce.dispose();
    super.dispose();
  }

  void _startEdit() {
    setState(() => _editing = true);
    _focus.requestFocus();
    _editBounce.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  void _stopEdit() {
    setState(() => _editing = false);
    _focus.unfocus();
    // POPRAVAK 1: propagiraj promjenu u parent
    final copy = widget.data.copy();
    copy.iceBreaker = _ctrl.text;
    widget.onChange(copy);
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _ctrl.text.isNotEmpty;

    // POPRAVAK 2: LayoutBuilder da znamo tocnu visinu, pa Positioned gumb
    return LayoutBuilder(builder: (context, constraints) {
      const double fabSize = 52.0;
      // Gornji flex:5, donji flex:7 → granica na 5/12 ukupne visine
      final double boundary = constraints.maxHeight * 5 / 12;
      final double fabTop   = boundary - fabSize / 2;

      return GestureDetector(
        onTap: _editing ? _stopEdit : null,
        child: Stack(children: [

          // ── Oba pravokutnika ─────────────────────────────────────────────
          Column(children: [
            // Gornji — svjetlija ružičasta
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                color: kPrimaryLight.withOpacity(0.60),
                alignment: Alignment.centerLeft,
                // padding desno veći da tekst ne ide ispod gumba
                padding: const EdgeInsets.fromLTRB(28, 0, 90, 0),
                child: Text(
                  'Napiši kako želiš da ti\nnetko priđe:',
                  style: TextStyle(
                    color: kPrimaryDark.withOpacity(0.70),
                    fontSize: 22, fontWeight: FontWeight.w700, height: 1.4,
                  ),
                ),
              ),
            ),
            // Donji — tamnija ružičasta
            Expanded(
              flex: 7,
              child: Container(
                width: double.infinity,
                color: kPrimaryLight,
                padding: const EdgeInsets.fromLTRB(28, 18, 28, 0),
                child: _editing
                    ? TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _stopEdit(),
                  maxLines: null,
                  style: TextStyle(
                    color: kPrimaryDark,
                    fontSize: 26, fontWeight: FontWeight.w800, height: 1.3,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Napiši nešto zanimljivo...',
                    hintStyle: TextStyle(
                      color: kPrimaryDark.withOpacity(0.30),
                      fontSize: 22, fontWeight: FontWeight.w700,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                )
                    : GestureDetector(
                  onTap: _startEdit,
                  child: Text(
                    hasText ? _ctrl.text : 'Nek me pita koju\nseriju trenutno\nbingam...',
                    style: TextStyle(
                      color: hasText ? kPrimaryDark : kPrimaryDark.withOpacity(0.45),
                      fontSize: 26, fontWeight: FontWeight.w800, height: 1.3,
                    ),
                  ),
                ),
              ),
            ),
          ]),

          // ── FAB gumb — DESNO, PRELAZI oba pravokutnika ───────────────────
          Positioned(
            top: fabTop,
            right: 24,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: _editBounce, curve: Curves.easeOutBack),
              ),
              child: GestureDetector(
                onTap: _editing ? _stopEdit : _startEdit,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  width: fabSize, height: fabSize,
                  decoration: BoxDecoration(
                    color: _editing ? Colors.white : kPrimaryDark,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryDark.withOpacity(0.35),
                        blurRadius: 16, offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _editing ? Icons.check_rounded : Icons.edit_rounded,
                    color: _editing ? kPrimaryDark : Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),

        ]),
      );
    });
  }
}