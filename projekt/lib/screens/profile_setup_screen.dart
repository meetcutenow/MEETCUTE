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
  String? seekingGender;
  int?    prefAgeFrom;
  int?    prefAgeTo;

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
    this.seekingGender,
    this.prefAgeFrom,
    this.prefAgeTo,
  })  : photoPaths = photoPaths ?? [],
        interests  = interests  ?? [];

  ProfileSetupData copy() => ProfileSetupData(
    photoPaths:    List.from(photoPaths),
    birthDay:      birthDay,
    birthMonth:    birthMonth,
    birthYear:     birthYear,
    height:        height,
    hairColor:     hairColor,
    eyeColor:      eyeColor,
    piercing:      piercing,
    tattoo:        tattoo,
    gender:        gender,
    interests:     List.from(interests),
    iceBreaker:    iceBreaker,
    seekingGender: seekingGender,
    prefAgeFrom:   prefAgeFrom,
    prefAgeTo:     prefAgeTo,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 1 — fotografije i osobni podaci
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

  static const _hairOptions   = ['plava', 'smeda', 'crna', 'crvena', 'sijeda', 'ostalo'];
  static const _eyeOptions    = ['smede', 'zelene', 'plave', 'sive'];
  static const _yesNo         = ['da', 'ne'];
  static const _genderOptions = ['zensko', 'musko', 'ostalo'];

  static const _hairLabels = {
    'plava':  'Plava',  'smeda':  'Smeđa', 'crna':   'Crna',
    'crvena': 'Crvena', 'sijeda': 'Sijeda', 'ostalo': 'Ostalo',
  };
  static const _eyeLabels = {
    'smede': 'Smeđe', 'zelene': 'Zelene', 'plave': 'Plave', 'sive': 'Sive',
  };
  static const _genderLabels = {
    'zensko': 'Žensko', 'musko': 'Muško', 'ostalo': 'Ostalo',
  };
  static const _yesNoLabels = {'da': 'Da', 'ne': 'Ne'};

  @override
  void initState() {
    super.initState();
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
    return Stack(clipBehavior: Clip.none, children: [
      GestureDetector(
        onTap: () => _pickPhoto(idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: kPrimaryLight, borderRadius: BorderRadius.circular(14),
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
                    child: Icon(Icons.edit_rounded, color: kPrimaryDark, size: 13)),
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
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 13)),
            )),
    ]);
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

    final hairValue   = _hairOptions.contains(d.hairColor)   ? d.hairColor   : null;
    final eyeValue    = _eyeOptions.contains(d.eyeColor)     ? d.eyeColor    : null;
    final genderValue = _genderOptions.contains(d.gender)    ? d.gender      : null;
    final piercingVal = _yesNo.contains(d.piercing)          ? d.piercing    : null;
    final tattooVal   = _yesNo.contains(d.tattoo)            ? d.tattoo      : null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
        _label('Visina (cm):'),
        const SizedBox(height: 8),
        _textField(ctrl: _heightCtrl, hint: '168', keyboardType: TextInputType.number,
            onChanged: (v) => _update((d) { d.height = v; return d; })),
        const SizedBox(height: 16),
        _label('Spol:'),
        const SizedBox(height: 8),
        _dropdown(value: genderValue, hint: 'Odaberi spol', items: _genderOptions,
            labelMap: _genderLabels,
            onChanged: (v) => _update((dd) { dd.gender = v; return dd; })),
        const SizedBox(height: 16),
        _label('Boja kose:'),
        const SizedBox(height: 8),
        _dropdown(value: hairValue, hint: 'Odaberi boju kose', items: _hairOptions,
            labelMap: _hairLabels,
            onChanged: (v) => _update((dd) { dd.hairColor = v; return dd; })),
        const SizedBox(height: 16),
        _label('Boja očiju:'),
        const SizedBox(height: 8),
        _dropdown(value: eyeValue, hint: 'Odaberi boju očiju', items: _eyeOptions,
            labelMap: _eyeLabels,
            onChanged: (v) => _update((dd) { dd.eyeColor = v; return dd; })),
        const SizedBox(height: 16),
        _label('Pirsing:'),
        const SizedBox(height: 8),
        _dropdown(value: piercingVal, hint: 'Imaš li pirsing?', items: _yesNo,
            labelMap: _yesNoLabels,
            onChanged: (v) => _update((dd) { dd.piercing = v; return dd; })),
        const SizedBox(height: 16),
        _label('Tetovaža:'),
        const SizedBox(height: 8),
        _dropdown(value: tattooVal, hint: 'Imaš li tetovažu?', items: _yesNo,
            labelMap: _yesNoLabels,
            onChanged: (v) => _update((dd) { dd.tattoo = v; return dd; })),
        const SizedBox(height: 8),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kPrimaryDark.withOpacity(0.15), width: 1.2)),
      child: TextField(
        controller: ctrl, keyboardType: keyboardType, onChanged: onChanged,
        style: TextStyle(color: kPrimaryDark, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: kPrimaryDark.withOpacity(0.30), fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), isDense: true,
        ),
      ),
    );
  }

  Widget _dropdown({
    required String? value, required String hint, required List<String> items,
    Map<String, String>? labelMap, required void Function(String?) onChanged,
  }) {
    final safeValue = (value != null && items.contains(value)) ? value : null;
    return Container(
      height: 50,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: safeValue != null ? kPrimaryDark.withOpacity(0.35) : kPrimaryDark.withOpacity(0.15),
            width: 1.2,
          )),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: safeValue,
        hint: Text(hint, style: TextStyle(color: kPrimaryDark.withOpacity(0.30), fontSize: 15)),
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: kPrimaryDark.withOpacity(0.45)),
        style: TextStyle(color: kPrimaryDark, fontSize: 15, fontFamily: 'SF Pro Display'),
        dropdownColor: Colors.white, borderRadius: BorderRadius.circular(12),
        onChanged: onChanged,
        items: items.map((s) => DropdownMenuItem(value: s,
            child: Text(labelMap?[s] ?? s))).toList(),
      )),
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
  void dispose() { for (final c in _tapCtrls) c.dispose(); super.dispose(); }

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
          Positioned(top: 6, right: 6,
              child: GestureDetector(onTap: onRemove,
                  child: Container(width: 22, height: 22,
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4)]),
                      child: Icon(Icons.close_rounded, size: 14, color: kPrimaryDark)))),
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
  void dispose() { _ctrl.dispose(); _focus.dispose(); _editBounce.dispose(); super.dispose(); }

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
            Expanded(flex: 5,
                child: Container(width: double.infinity,
                    color: kPrimaryLight.withOpacity(0.60),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.fromLTRB(28, 0, 90, 0),
                    child: Text('Napiši kako želiš da ti\nnetko priđe:',
                        style: TextStyle(color: kPrimaryDark.withOpacity(0.70),
                            fontSize: 22, fontWeight: FontWeight.w700, height: 1.4)))),
            Expanded(flex: 7,
                child: Container(width: double.infinity, color: kPrimaryLight,
                    padding: const EdgeInsets.fromLTRB(28, 18, 28, 0),
                    child: _editing
                        ? TextField(controller: _ctrl, focusNode: _focus,
                        onChanged: (_) => setState(() {}), onSubmitted: (_) => _stopEdit(),
                        maxLines: null,
                        style: TextStyle(color: kPrimaryDark, fontSize: 26, fontWeight: FontWeight.w800, height: 1.3),
                        decoration: InputDecoration(
                            hintText: 'Napiši nešto zanimljivo...',
                            hintStyle: TextStyle(color: kPrimaryDark.withOpacity(0.30), fontSize: 22, fontWeight: FontWeight.w700),
                            border: InputBorder.none, contentPadding: EdgeInsets.zero))
                        : GestureDetector(onTap: _startEdit,
                        child: Text(hasText ? _ctrl.text : 'Nek me pita koju\nseriju trenutno\nbingam...',
                            style: TextStyle(
                                color: hasText ? kPrimaryDark : kPrimaryDark.withOpacity(0.45),
                                fontSize: 26, fontWeight: FontWeight.w800, height: 1.3))))),
          ]),
          Positioned(top: fabTop, right: 24,
              child: ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                      CurvedAnimation(parent: _editBounce, curve: Curves.easeOutBack)),
                  child: GestureDetector(
                      onTap: _editing ? _stopEdit : _startEdit,
                      child: AnimatedContainer(duration: const Duration(milliseconds: 260),
                          width: fabSize, height: fabSize,
                          decoration: BoxDecoration(
                              color: _editing ? Colors.white : kPrimaryDark, shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))]),
                          child: Icon(_editing ? Icons.check_rounded : Icons.edit_rounded,
                              color: _editing ? kPrimaryDark : Colors.white, size: 22))))),
        ]),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 4 — Preference (tražim spol + dobna skupina)
// ═══════════════════════════════════════════════════════════════════════════════

class ProfileStep4 extends StatefulWidget {
  final ProfileSetupData data;
  final void Function(ProfileSetupData) onChange;
  const ProfileStep4({super.key, required this.data, required this.onChange});
  @override State<ProfileStep4> createState() => _ProfileStep4State();
}

class _ProfileStep4State extends State<ProfileStep4> with TickerProviderStateMixin {

  static const _seekingOptions = ['zensko', 'musko', 'sve'];
  static const _seekingLabels  = {
    'zensko': 'Žensko',
    'musko':  'Muško',
    'sve':    'Svejedno',
  };

  late final TextEditingController _ageFromCtrl;
  late final TextEditingController _ageToCtrl;
  late final List<AnimationController> _chipCtrls;

  @override
  void initState() {
    super.initState();
    _ageFromCtrl = TextEditingController(
        text: widget.data.prefAgeFrom?.toString() ?? '');
    _ageToCtrl   = TextEditingController(
        text: widget.data.prefAgeTo?.toString() ?? '');
    _chipCtrls   = List.generate(3,
            (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 120)));
  }

  @override
  void dispose() {
    _ageFromCtrl.dispose(); _ageToCtrl.dispose();
    for (final c in _chipCtrls) c.dispose();
    super.dispose();
  }

  void _update(ProfileSetupData Function(ProfileSetupData) fn) =>
      widget.onChange(fn(widget.data.copy()));

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final seekingValue = _seekingOptions.contains(d.seekingGender) ? d.seekingGender : null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kPrimaryLight.withOpacity(0.60),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kPrimaryDark.withOpacity(0.10)),
          ),
          child: Row(children: [
            Container(width: 42, height: 42,
                decoration: BoxDecoration(color: kPrimaryDark.withOpacity(0.08), shape: BoxShape.circle),
                child: const Icon(Icons.tune_rounded, color: kPrimaryDark, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Text('Postavi preference da ti bolje predložimo matcheve.',
                style: TextStyle(color: kPrimaryDark.withOpacity(0.65), fontSize: 13.5, height: 1.4))),
          ]),
        ),

        const SizedBox(height: 28),

        _sectionTitle('Tražim:'),
        const SizedBox(height: 12),
        Row(children: List.generate(_seekingOptions.length, (i) {
          final opt = _seekingOptions[i];
          final isSel = seekingValue == opt;
          final label = _seekingLabels[opt] ?? opt;
          return Expanded(child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
            child: GestureDetector(
              onTapDown: (_) => _chipCtrls[i].forward(),
              onTapUp: (_) {
                _chipCtrls[i].reverse();
                HapticFeedback.selectionClick();
                _update((d) { d.seekingGender = opt; return d; });
              },
              onTapCancel: () => _chipCtrls[i].reverse(),
              child: AnimatedBuilder(
                animation: _chipCtrls[i],
                builder: (_, __) => Transform.scale(
                  scale: 1.0 - _chipCtrls[i].value * 0.04,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 54,
                    decoration: BoxDecoration(
                      color: isSel ? kPrimaryDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isSel ? kPrimaryDark : kPrimaryDark.withOpacity(0.15), width: 1.5),
                      boxShadow: isSel ? [BoxShadow(
                          color: kPrimaryDark.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))] : [],
                    ),
                    child: Center(child: Text(label,
                        style: TextStyle(
                          color: isSel ? Colors.white : kPrimaryDark,
                          fontSize: 14, fontWeight: FontWeight.w700,
                        ), textAlign: TextAlign.center)),
                  ),
                ),
              ),
            ),
          ));
        })),

        const SizedBox(height: 30),

        _sectionTitle('Dobna skupina koja mi odgovara:'),
        const SizedBox(height: 8),
        Text('Upiši raspon godina koji ti odgovara.',
            style: TextStyle(color: kPrimaryDark.withOpacity(0.45), fontSize: 12.5)),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: _ageField(
            ctrl: _ageFromCtrl, hint: 'Od (npr. 18)',
            onChanged: (v) => _update((d) { d.prefAgeFrom = int.tryParse(v); return d; }),
          )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('–', style: TextStyle(color: kPrimaryDark, fontSize: 22, fontWeight: FontWeight.w700)),
          ),
          Expanded(child: _ageField(
            ctrl: _ageToCtrl, hint: 'Do (npr. 30)',
            onChanged: (v) => _update((d) { d.prefAgeTo = int.tryParse(v); return d; }),
          )),
        ]),

        const SizedBox(height: 12),
        _ageHint(d),
      ]),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: TextStyle(color: kPrimaryDark, fontSize: 15.5, fontWeight: FontWeight.w700));

  Widget _ageField({
    required TextEditingController ctrl,
    required String hint,
    required void Function(String) onChanged,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kPrimaryDark.withOpacity(0.15), width: 1.2),
      ),
      child: TextField(
        controller: ctrl, keyboardType: TextInputType.number,
        onChanged: (v) { setState(() {}); onChanged(v); },
        style: TextStyle(color: kPrimaryDark, fontSize: 16, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: kPrimaryDark.withOpacity(0.28), fontSize: 13),
          border: InputBorder.none, isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _ageHint(ProfileSetupData d) {
    final from = d.prefAgeFrom;
    final to   = d.prefAgeTo;

    if (from == null && to == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 14),
          const SizedBox(width: 7),
          Expanded(child: Text('Oba polja su obavezna.',
              style: TextStyle(color: Colors.orange.shade800, fontSize: 12.5, fontWeight: FontWeight.w500))),
        ]),
      );
    }

    bool ok = true;
    String msg = '';
    if (from == null) { ok = false; msg = 'Upiši donju granicu dobi.'; }
    else if (to == null) { ok = false; msg = 'Upiši gornju granicu dobi.'; }
    // CHANGED: min age 16 → 18
    else if (from < 18 || from > 99) { ok = false; msg = 'Minimalna dob je 18 godina.'; }
    else if (to < 18 || to > 99) { ok = false; msg = 'Maksimalna dob je 99 godina.'; }
    else if (from > to) { ok = false; msg = 'Gornja granica mora biti veća od donje.'; }
    else { msg = 'Tražiš osobe od $from do $to godina. ✓'; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ok ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ok ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Row(children: [
        Icon(ok ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
            color: ok ? Colors.green.shade600 : Colors.redAccent, size: 14),
        const SizedBox(width: 7),
        Expanded(child: Text(msg, style: TextStyle(
            color: ok ? Colors.green.shade700 : Colors.redAccent,
            fontSize: 12.5, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROFILE SETUP SCREEN — za UREDI PROFIL (iz profile_screen)
// ═══════════════════════════════════════════════════════════════════════════════

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

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with TickerProviderStateMixin {
  late ProfileSetupData _data;
  int _step = 0;
  static const int _totalSteps = 4;

  late AnimationController _progressCtrl;
  late AnimationController _pageCtrl;
  late Animation<Offset> _pageSlide;

  @override
  void initState() {
    super.initState();
    _data = widget.initial.copy();
    _progressCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600), value: 1 / _totalSteps);
    _pageCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _pageSlide = Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOutCubic));
    _pageCtrl.value = 1.0;
  }

  @override
  void dispose() { _progressCtrl.dispose(); _pageCtrl.dispose(); super.dispose(); }

  void _update(ProfileSetupData newData) => setState(() => _data = newData);

  void _next() {
    if (_step == 3) {
      final err = _validateStep4();
      if (err != null) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          backgroundColor: kPrimaryDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ));
        return;
      }
    }

    if (_step < _totalSteps - 1) {
      HapticFeedback.lightImpact();
      _pageCtrl.reset(); _pageCtrl.forward();
      setState(() => _step++);
      _progressCtrl.animateTo((_step + 1) / _totalSteps,
          duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    } else {
      widget.onSave(_data);
      Navigator.pop(context);
    }
  }

  String? _validateStep4() {
    if (_data.seekingGender == null) return 'Odaberi koga tražiš.';
    if (_data.prefAgeFrom == null) return 'Upiši donju granicu dobi.';
    if (_data.prefAgeTo == null) return 'Upiši gornju granicu dobi.';
    final from = _data.prefAgeFrom!;
    final to   = _data.prefAgeTo!;
    // CHANGED: min age 16 → 18
    if (from < 18 || from > 99) return 'Minimalna dob je 18 godina.';
    if (to < 18 || to > 99) return 'Maksimalna dob je 99 godina.';
    if (from > to) return 'Gornja granica mora biti veća od donje.';
    return null;
  }

  void _back() {
    if (_step > 0) {
      HapticFeedback.selectionClick();
      _pageCtrl.reset(); _pageCtrl.forward();
      setState(() => _step--);
      _progressCtrl.animateTo((_step + 1) / _totalSteps,
          duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    Widget currentStep;
    switch (_step) {
      case 0: currentStep = ProfileStep1(key: const ValueKey('s1'), data: _data, onChange: _update, mq: mq); break;
      case 1: currentStep = ProfileStep2(key: const ValueKey('s2'), data: _data, onChange: _update); break;
      case 2: currentStep = ProfileStep3(key: const ValueKey('s3'), data: _data, onChange: _update); break;
      default: currentStep = ProfileStep4(key: const ValueKey('s4'), data: _data, onChange: _update);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        _buildHeader(mq),
        Expanded(child: SlideTransition(position: _pageSlide, child: currentStep)),
        _buildNextBtn(mq),
      ]),
    );
  }

  // CHANGED: removed step label text, bigger progress bar (10px height)
  Widget _buildHeader(MediaQueryData mq) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(top: mq.padding.top + 10, left: 8, right: 20, bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: _back,
            child: Container(width: 40, height: 40,
                decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(13)),
                child: Icon(Icons.arrow_back_ios_new_rounded, color: kPrimaryDark, size: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(child: AnimatedBuilder(
            animation: _progressCtrl,
            builder: (_, __) => LayoutBuilder(builder: (_, box) {
              final w = box.maxWidth * _progressCtrl.value;
              return Container(
                height: 10,
                decoration: BoxDecoration(
                    color: kPrimaryDark.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8)),
                child: Align(alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: w.clamp(0.0, box.maxWidth),
                      decoration: BoxDecoration(
                          color: kPrimaryDark,
                          borderRadius: BorderRadius.circular(8)),
                    )),
              );
            }),
          )),
        ]),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text('Uredi profil',
              style: TextStyle(color: kPrimaryDark, fontSize: 22,
                  fontWeight: FontWeight.w900, letterSpacing: -0.4)),
        ),
      ]),
    );
  }

  Widget _buildNextBtn(MediaQueryData mq) {
    final isLast = _step == _totalSteps - 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 10, 24, mq.padding.bottom + 14),
      child: _SetupNextBtnWidget(
        label: isLast ? 'Spremi' : 'Nastavi',
        onTap: _next,
      ),
    );
  }
}

class _SetupNextBtnWidget extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _SetupNextBtnWidget({required this.label, required this.onTap});
  @override State<_SetupNextBtnWidget> createState() => _SetupNextBtnWidgetState();
}

class _SetupNextBtnWidgetState extends State<_SetupNextBtnWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.95)
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
        child: Container(
          height: 54, width: double.infinity,
          decoration: BoxDecoration(
            color: kPrimaryDark,
            borderRadius: BorderRadius.circular(27),
            boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.35),
                blurRadius: 18, offset: const Offset(0, 7), spreadRadius: -3)],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(widget.label,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            Container(width: 26, height: 26,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 18)),
          ]),
        ),
      ),
    );
  }
}