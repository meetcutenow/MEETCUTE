import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'home_screen.dart' show kPrimaryDark, kPrimaryLight, kSurface;
import 'theme_state.dart';
import '../services/api_service.dart';

// ─── Ekran koji prikazuje obližnji profil za like/dislike ──────────────────────

class ProximityMatchScreen extends StatefulWidget {
  final NearbyUserData user;
  const ProximityMatchScreen({super.key, required this.user});

  @override
  State<ProximityMatchScreen> createState() => _ProximityMatchScreenState();
}

class _ProximityMatchScreenState extends State<ProximityMatchScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _entryScale, _entryFade;
  bool _reacting = false;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _entryScale = Tween<double>(begin: 0.88, end: 1.0).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack));
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _react(bool liked) async {
    if (_reacting) return;
    setState(() => _reacting = true);
    HapticFeedback.mediumImpact();

    try {
      final result = await ApiService().react(widget.user.userId, liked);

      if (!mounted) return;

      if (result != null && result.matched) {
        // Zamijeni ovaj screen s match result screenom
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, a, __) => MatchResultScreen(
            matched: true,
            myPhoto: result.myPhoto,
            otherPhoto: result.otherPhoto ?? widget.user.primaryPhoto,
            otherUserName: result.otherUserName ?? widget.user.displayName,
            conversationId: result.match?.conversationId,
          ),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ));
      } else {
        // No match - pokazi zao nam je ili samo zatvori
        if (!liked) {
          Navigator.pushReplacement(context, PageRouteBuilder(
            pageBuilder: (_, a, __) => const MatchResultScreen(
              matched: false,
              myPhoto: null,
              otherPhoto: null,
              otherUserName: '',
            ),
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ));
        } else {
          // Liked ali nema mutual match još - samo zatvori i čekaj
          Navigator.pop(context, {'liked': true, 'matched': false});
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _reacting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isDark = ThemeState.instance.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A0A0F) : const Color(0xFFF5EDEF),
      body: FadeTransition(
        opacity: _entryFade,
        child: ScaleTransition(
          scale: _entryScale,
          child: SafeArea(
            child: Column(
              children: [
                // ─── Header ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.close, color: kPrimaryDark, size: 20),
                        ),
                      ),
                      const Spacer(),
                      Image.asset('assets/images/logo.png', height: 28,
                          errorBuilder: (_, __, ___) => const Text('MeetCute',
                              style: TextStyle(color: kPrimaryDark,
                                  fontWeight: FontWeight.w900, fontSize: 18))),
                      const Spacer(),
                      const SizedBox(width: 38),
                    ],
                  ),
                ),

                // ─── Profile Card ───────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // Photo
                          Container(
                            height: mq.size.height * 0.42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                    color: kPrimaryDark.withOpacity(0.25),
                                    blurRadius: 32, offset: const Offset(0, 12)),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _buildPhoto(widget.user.primaryPhoto),
                                  // Gradient overlay s imenom
                                  Positioned(
                                    bottom: 0, left: 0, right: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.75),
                                          ],
                                        ),
                                      ),
                                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                                      child: Text(
                                        widget.user.displayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Info card (identično slici)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(color: kPrimaryDark.withOpacity(0.08),
                                    blurRadius: 20, offset: const Offset(0, 6)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Ice breaker
                                if (widget.user.iceBreaker != null &&
                                    widget.user.iceBreaker!.isNotEmpty) ...[
                                  Text('Želim da mi priđeš...',
                                      style: TextStyle(
                                          color: kPrimaryDark.withOpacity(0.55),
                                          fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Text(widget.user.iceBreaker!,
                                      style: const TextStyle(
                                          color: kPrimaryDark,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700)),
                                  const Divider(height: 24),
                                ],

                                // Interesi
                                if (widget.user.interests.isNotEmpty) ...[
                                  Text('Interesi',
                                      style: TextStyle(
                                          color: kPrimaryDark,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8, runSpacing: 8,
                                    children: widget.user.interests.map((i) =>
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: kPrimaryDark.withOpacity(0.15)),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(i,
                                              style: const TextStyle(
                                                  color: kPrimaryDark,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500)),
                                        )).toList(),
                                  ),
                                  const Divider(height: 24),
                                ],

                                // Osobni podaci
                                Text('Osobni podaci',
                                    style: TextStyle(
                                        color: kPrimaryDark,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 12),
                                if (widget.user.age != null)
                                  _buildInfoRow(Icons.cake_outlined, 'Godine',
                                      '${widget.user.age}'),
                                if (widget.user.heightCm != null)
                                  _buildInfoRow(Icons.height, 'Visina',
                                      '${widget.user.heightCm} cm'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),

                // ─── Action Buttons (X i srce) ──────────────────────
                Padding(
                  padding: EdgeInsets.only(
                      bottom: mq.padding.bottom + 24, left: 60, right: 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // X button
                      _ActionButton(
                        onTap: _reacting ? null : () => _react(false),
                        child: const Icon(Icons.close, color: Colors.white, size: 28),
                        color: kPrimaryDark,
                        size: 64,
                      ),
                      // Srce button
                      _ActionButton(
                        onTap: _reacting ? null : () => _react(true),
                        child: _reacting
                            ? const SizedBox(width: 24, height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                            : const Icon(Icons.favorite, color: Colors.white, size: 28),
                        color: const Color(0xFFE8C0CB),
                        size: 64,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(String? url) {
    if (url != null && url.startsWith('http')) {
      return Image.network(url, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _photoPlaceholder());
    }
    return _photoPlaceholder();
  }

  Widget _photoPlaceholder() => Container(
    color: kPrimaryLight,
    child: const Icon(Icons.person, color: kPrimaryDark, size: 80),
  );

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryDark, size: 18),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(color: kPrimaryDark,
                  fontWeight: FontWeight.w700, fontSize: 14)),
          const Spacer(),
          Text(value,
              style: const TextStyle(color: kPrimaryDark,
                  fontWeight: FontWeight.w800, fontSize: 15)),
        ],
      ),
    );
  }
}

// ─── Action Button widget ─────────────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final Color color;
  final double size;
  const _ActionButton(
      {required this.onTap, required this.child,
        required this.color, required this.size});
  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 100));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _ctrl.forward() : null,
      onTapUp: widget.onTap != null ? (_) {
        _ctrl.reverse();
        widget.onTap!();
      } : null,
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - _ctrl.value * 0.08,
          child: child,
        ),
        child: Container(
          width: widget.size, height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                  color: widget.color.withOpacity(0.45),
                  blurRadius: 18, offset: const Offset(0, 6)),
            ],
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

// ─── Match Result Screen (IMATE MATCH / ŽAO NAM JE) ──────────────────────────

class MatchResultScreen extends StatefulWidget {
  final bool matched;
  final String? myPhoto;
  final String? otherPhoto;
  final String otherUserName;
  final String? conversationId;

  const MatchResultScreen({
    super.key,
    required this.matched,
    required this.myPhoto,
    required this.otherPhoto,
    required this.otherUserName,
    this.conversationId,
  });
  @override
  State<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends State<MatchResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl, _photoCtrl;
  late Animation<double> _fade, _photoScale;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    _photoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _photoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _photoCtrl, curve: Curves.elasticOut));

    _entryCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _photoCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _photoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF700D25),
      body: FadeTransition(
        opacity: _fade,
        child: SafeArea(
          child: widget.matched ? _buildMatchedScreen() : _buildNoMatchScreen(),
        ),
      ),
    );
  }

  Widget _buildMatchedScreen() {
    return Column(
      children: [
        const Spacer(),

        // Logo
        Image.asset('assets/images/logo.png', height: 60,
            color: Colors.white.withOpacity(0.9),
            errorBuilder: (_, __, ___) => const Text('MeetCute',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w900, fontSize: 28))),
        const SizedBox(height: 40),

        // Slike oboje (identično slici 3)
        ScaleTransition(
          scale: _photoScale,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCirclePhoto(widget.myPhoto, 110),
              const SizedBox(width: 16),
              _buildCirclePhoto(widget.otherPhoto, 110),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // IMATE MATCH tekst
        const Text(
          'IMATE MATCH',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Pričite si i upoznajte se!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Chat će se otvoriti za 30 minuta 💬',
          style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontSize: 13,
          ),
        ),

        const Spacer(),

        // Gumbi
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
                child: Container(
                  height: 52, width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Center(
                    child: Text('Nastavi istraživanje',
                        style: TextStyle(
                            color: Color(0xFF700D25),
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoMatchScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo
        Image.asset('assets/images/logo.png', height: 70,
            color: Colors.white.withOpacity(0.9),
            errorBuilder: (_, __, ___) => const Text('MeetCute',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w900, fontSize: 28))),
        const SizedBox(height: 48),

        // ŽAO NAM JE
        const Text(
          'ŽAO NAM JE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Ovoga puta, nažalost, nije\ndošlo do podudaranja. Ne\nbrinite, sigurni smo da ćete\nuskoro upoznati nekoga\ntko vam odgovara!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 16,
              height: 1.65,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(height: 60),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: GestureDetector(
            onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Center(
                child: Text('Natrag',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCirclePhoto(String? url, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3),
              blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipOval(
        child: url != null && url.startsWith('http')
            ? Image.network(url, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _photoPlaceholder())
            : _photoPlaceholder(),
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
    color: kPrimaryLight,
    child: const Icon(Icons.person, color: kPrimaryDark, size: 40),
  );
}