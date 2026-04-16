import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'home_screen.dart' show kPrimaryDark, kPrimaryLight, kSurface;


// ═══════════════════════════════════════════════════════════════════════════════
// PROFILE DATA MODEL  (nepromijenjen)
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
// STEP 1 — fotografije i osobni podaci
// ISPRAVKA: vrijednosti u dropdownima su identične onima koji se spremaju
// ═══════════════════════════════════════════════════════════════════════════════

class ProfileStep1 extends StatefulWidget {
  final ProfileSetupData data;
  final void Function(ProfileSetupData) onChange;
  final MediaQueryData mq;
  const ProfileStep1({super.key, required this.data, required this.onChange, required this.mq});
  @override State<ProfileStep1> createState() => _ProfileStep1State();
}

class _ProfileStep1State extends State<ProfileStep1> {
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _heightCtrl;
  late final TextEditingController _dayCtrl;
  late final TextEditingController _monthCtrl;
  late final TextEditingController _yearCtrl;

  // ── Vrijednosti (BEZ dijakritika) — točno ono što se sprema u ProfileStorage ──
  static const _hairOptions   = ['plava', 'smeda', 'crna', 'crvena', 'sijeda', 'ostalo'];
  static const _eyeOptions    = ['smede', 'zelene', 'plave', 'sive'];
  static const _yesNo         = ['da', 'ne'];
  static const _genderOptions = ['zensko', 'musko', 'ostalo'];

  // ── Labele za prikaz korisniku (s dijakritima) ──────────────────────────────
  static const _hairLabels = {
    'plava':   'Plava',
    'smeda':   'Smeđa',
    'crna':    'Crna',
    'crvena':  'Crvena',
    'sijeda':  'Sijeda',
    'ostalo':  'Ostalo',
  };
  static const _eyeLabels = {
    'smede':   'Smeđe',
    'zelene':  'Zelene',
    'plave':   'Plave',
    'sive':    'Sive',
  };
  static const _genderLabels = {
    'zensko':  'Žensko',
    'musko':   'Muško',
    'ostalo':  'Ostalo',
  };
  static const _yesNoLabels = {
    'da': 'Da',
    'ne': 'Ne',
  };

  @override
  void initState() {
    super.initState();
    // ── ISPRAVKA: inicijalizacija s existing podacima ─────────────────────────
    _heightCtrl = TextEditingController(text: widget.data.height ?? '');
    _dayCtrl    = TextEditingController(text: widget.data.birthDay?.toString()   ?? '');
    _monthCtrl  = TextEditingController(text: widget.data.birthMonth?.toString() ?? '');
    _yearCtrl   = TextEditingController(text: widget.data.birthYear?.toString()  ?? '');
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
                Positioned(bottom: 4, right: 4,
                  child: Container(width: 24, height: 24,
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4)]),
                    child: Icon(Icons.edit_rounded, color: kPrimaryDark, size: 13),
                  ),
                ),
              ]),
            )
                : _emptyPhotoContent(),
          ),
        ),
        if (hasPhoto && photos.length > 1)
          Positioned(top: -8, right: -8,
            child: GestureDetector(
              onTap: () => _removePhoto(idx),
              child: Container(width: 22, height: 22,
                decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 4)]),
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
        color: kPrimaryLight, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kPrimaryDark.withOpacity(0.18), width: 1.5),
      ),
      child: Center(child: Icon(Icons.add_rounded, color: kPrimaryDark, size: 36)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final photos = d.photoPaths;

    // ── ISPRAVKA: safe vrijednosti za dropdown — null ako nije u listi ─────────
    final hairValue   = _hairOptions.contains(d.hairColor)   ? d.hairColor   : null;
    final eyeValue    = _eyeOptions.contains(d.eyeColor)     ? d.eyeColor    : null;
    final genderValue = _genderOptions.contains(d.gender)    ? d.gender      : null;
    final piercingVal = _yesNo.contains(d.piercing)          ? d.piercing    : null;
    final tattooVal   = _yesNo.contains(d.tattoo)            ? d.tattoo      : null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Slike ──────────────────────────────────────────────────────────────
        SizedBox(
          height: 156,
          child: Row(children: [
            Expanded(child: _photoSlot(0)),
            const SizedBox(width: 10),
            Expanded(child: photos.length >= 2 ? _photoSlot(1) : _addSlot()),
            if (photos.length >= 2) ...[
              const SizedBox(width: 10),
              Expanded(child: photos.length >= 3 ? _photoSlot(2) : _addSlot()),
            ],
            if (photos.length >= 3 && photos.length < 6) ...[
              const SizedBox(width: 10),
              Expanded(child: _addSlot()),
            ],
          ]),
        ),

        // ── Datum rođenja ──────────────────────────────────────────────────────
        const SizedBox(height: 22),
        _label('Datum rođenja:'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _textField(
            ctrl: _dayCtrl, hint: 'DD', keyboardType: TextInputType.number,
            onChanged: (v) => _update((d) { d.birthDay = int.tryParse(v); return d; }),
          )),
          const SizedBox(width: 8),
          Expanded(child: _textField(
            ctrl: _monthCtrl, hint: 'MM', keyboardType: TextInputType.number,
            onChanged: (v) => _update((d) { d.birthMonth = int.tryParse(v); return d; }),
          )),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: _textField(
            ctrl: _yearCtrl, hint: 'GGGG', keyboardType: TextInputType.number,
            onChanged: (v) => _update((d) { d.birthYear = int.tryParse(v); return d; }),
          )),
        ]),

        // ── Visina ─────────────────────────────────────────────────────────────
        const SizedBox(height: 16),
        _label('Visina (cm):'),
        const SizedBox(height: 8),
        _textField(
          ctrl: _heightCtrl, hint: '168', keyboardType: TextInputType.number,
          onChanged: (v) => _update((d) { d.height = v; return d; }),
        ),

        // ── Spol ───────────────────────────────────────────────────────────────
        const SizedBox(height: 16),
        _label('Spol:'),
        const SizedBox(height: 8),
        _dropdown(
          value: genderValue,
          hint: 'Odaberi spol',
          items: _genderOptions,
          labelMap: _genderLabels,
          onChanged: (v) => _update((dd) { dd.gender = v; return dd; }),
        ),

        // ── Boja kose ─────────────────────────────────────────────────────────
        const SizedBox(height: 16),
        _label('Boja kose:'),
        const SizedBox(height: 8),
        _dropdown(
          value: hairValue,
          hint: 'Odaberi boju kose',
          items: _hairOptions,
          labelMap: _hairLabels,
          onChanged: (v) => _update((dd) { dd.hairColor = v; return dd; }),
        ),

        // ── Boja očiju ────────────────────────────────────────────────────────
        const SizedBox(height: 16),
        _label('Boja očiju:'),
        const SizedBox(height: 8),
        _dropdown(
          value: eyeValue,
          hint: 'Odaberi boju očiju',
          items: _eyeOptions,
          labelMap: _eyeLabels,
          onChanged: (v) => _update((dd) { dd.eyeColor = v; return dd; }),
        ),

        // ── Pirsing ───────────────────────────────────────────────────────────
        const SizedBox(height: 16),
        _label('Pirsing:'),
        const SizedBox(height: 8),
        _dropdown(
          value: piercingVal,
          hint: 'Imaš li pirsing?',
          items: _yesNo,
          labelMap: _yesNoLabels,
          onChanged: (v) => _update((dd) { dd.piercing = v; return dd; }),
        ),

        // ── Tetovaža ──────────────────────────────────────────────────────────
        const SizedBox(height: 16),
        _label('Tetovaža:'),
        const SizedBox(height: 8),
        _dropdown(
          value: tattooVal,
          hint: 'Imaš li tetovažu?',
          items: _yesNo,
          labelMap: _yesNoLabels,
          onChanged: (v) => _update((dd) { dd.tattoo = v; return dd; }),
        ),

        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(color: kPrimaryDark, fontSize: 14.5, fontWeight: FontWeight.w600));

  Widget _textField({
    required TextEditingController ctrl,
    required String hint,
    TextInputType? keyboardType,
    required void Function(String) onChanged,
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
    required String? value,
    required String hint,
    required List<String> items,
    Map<String, String>? labelMap,
    required void Function(String?) onChanged,
  }) {
    // Osiguraj da value postoji u listi — ako ne, prikaži hint
    final safeValue = (value != null && items.contains(value)) ? value : null;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // Vizualno naglasi kad ima odabranu vrijednost
          color: safeValue != null
              ? kPrimaryDark.withOpacity(0.35)
              : kPrimaryDark.withOpacity(0.15),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          hint: Text(hint, style: TextStyle(color: kPrimaryDark.withOpacity(0.30), fontSize: 15)),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: kPrimaryDark.withOpacity(0.45)),
          style: TextStyle(color: kPrimaryDark, fontSize: 15, fontFamily: 'SF Pro Display'),
          dropdownColor: Colors.white, borderRadius: BorderRadius.circular(12),
          onChanged: onChanged,
          items: items.map((s) => DropdownMenuItem(
            value: s,
            child: Text(labelMap?[s] ?? s),
          )).toList(),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 2 — interesi
// ═══════════════════════════════════════════════════════════════════════════════

class ProfileStep2 extends StatefulWidget {
  final ProfileSetupData data;
  final void Function(ProfileSetupData) onChange;
  const ProfileStep2({super.key, required this.data, required this.onChange});
  @override State<ProfileStep2> createState() => _ProfileStep2State();
}

class _ProfileStep2State extends State<ProfileStep2> with TickerProviderStateMixin {

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
            final name  = _allInterests[i].$1;
            final emoji = _allInterests[i].$2;
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
// STEP 3 — icebreaker
// ═══════════════════════════════════════════════════════════════════════════════

class ProfileStep3 extends StatefulWidget {
  final ProfileSetupData data;
  final void Function(ProfileSetupData) onChange;
  const ProfileStep3({super.key, required this.data, required this.onChange});
  @override State<ProfileStep3> createState() => _ProfileStep3State();
}

class _ProfileStep3State extends State<ProfileStep3> with SingleTickerProviderStateMixin {
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
    final copy = widget.data.copy();
    copy.iceBreaker = _ctrl.text;
    widget.onChange(copy);
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _ctrl.text.isNotEmpty;

    return LayoutBuilder(builder: (context, constraints) {
      const double fabSize = 52.0;
      final double boundary = constraints.maxHeight * 5 / 12;
      final double fabTop   = boundary - fabSize / 2;

      return GestureDetector(
        onTap: _editing ? _stopEdit : null,
        child: Stack(children: [
          Column(children: [
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                color: kPrimaryLight.withOpacity(0.60),
                alignment: Alignment.centerLeft,
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

// ignore: unused_element
typedef _Step1 = ProfileStep1;
// ignore: unused_element
typedef _Step2 = ProfileStep2;
// ignore: unused_element
typedef _Step3 = ProfileStep3;

class ProfileSetupScreen extends StatefulWidget {
  final ProfileSetupData initial;
  final Function(ProfileSetupData) onSave;

  const ProfileSetupScreen({
    super.key,
    required this.initial,
    required this.onSave,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late ProfileSetupData data;
  int step = 0;

  @override
  void initState() {
    super.initState();
    data = widget.initial;
  }

  void _update(ProfileSetupData newData) {
    setState(() => data = newData);
  }

  void _next() {
    if (step < 2) {
      setState(() => step++);
    } else {
      widget.onSave(data);
      Navigator.pop(context);
    }
  }

  void _back() {
    if (step > 0) {
      setState(() => step--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget currentStep;

    if (step == 0) {
      currentStep = ProfileStep1(
        data: data,
        onChange: _update,
        mq: MediaQuery.of(context),
      );
    } else if (step == 1) {
      currentStep = ProfileStep2(
        data: data,
        onChange: _update,
      );
    } else {
      currentStep = ProfileStep3(
        data: data,
        onChange: _update,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // TOP BAR
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _back,
                ),
                const Spacer(),
                Text('Korak ${step + 1}/3'),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),

            Expanded(child: currentStep),

            // NEXT BUTTON
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(step == 2 ? 'Spremi' : 'Dalje'),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}