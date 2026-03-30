import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════
class ChatMessage {
  final String? text;
  final String? imagePath;
  final bool isMe;
  final String? timeDivider;
  final DateTime? sentAt;
  const ChatMessage({this.text, this.imagePath, required this.isMe,
    this.timeDivider, this.sentAt});
}

class ChatConversation {
  final String id;
  final String name;
  final List<ChatMessage> messages;
  const ChatConversation({required this.id, required this.name, required this.messages});

  ChatMessage? get lastMessage {
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].timeDivider == null) return messages[i];
    }
    return null;
  }

  String get lastMessageText {
    final msg = lastMessage;
    if (msg == null) return '';
    if (msg.imagePath != null) return '📷 Slika';
    return msg.text ?? '';
  }

  String get lastMessageTime {
    final t = lastMessage?.sentAt;
    if (t == null) return '';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  bool get hasUnread => lastMessage != null && !lastMessage!.isMe;
}

String _fmt(DateTime? dt) {
  if (dt == null) return '';
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

// ═══════════════════════════════════════════════════════════════════════════════
// GLOBAL STATE
// ═══════════════════════════════════════════════════════════════════════════════
class ChatState extends ChangeNotifier {
  static final ChatState instance = ChatState._();
  ChatState._();

  final List<ChatConversation> conversations = [
    ChatConversation(id: '1', name: 'Luka', messages: [
      ChatMessage(text: 'Hej! Vidio sam da si i ti na ovom eventu 😄', isMe: true,
          sentAt: DateTime.now().subtract(const Duration(minutes: 42))),
      ChatMessage(text: 'Haha jaa, idem svake godine!', isMe: false,
          sentAt: DateTime.now().subtract(const Duration(minutes: 40))),
      ChatMessage(timeDivider: 'Danas', isMe: false),
      ChatMessage(text: 'Gdje ćeš bit otprilike?', isMe: false,
          sentAt: DateTime.now().subtract(const Duration(minutes: 15))),
      ChatMessage(text: 'Bit ću kod glavne pozornice 🎶', isMe: true,
          sentAt: DateTime.now().subtract(const Duration(minutes: 12))),
      ChatMessage(text: 'Ok savršeno, i ja tamo!', isMe: false,
          sentAt: DateTime.now().subtract(const Duration(minutes: 8))),
      ChatMessage(text: 'Haha ok, vidimo se onda 😄', isMe: true,
          sentAt: DateTime.now().subtract(const Duration(minutes: 5))),
    ]),
    ChatConversation(id: '2', name: 'Matej', messages: [
      ChatMessage(text: 'Hej, kako si?', isMe: true,
          sentAt: DateTime.now().subtract(const Duration(hours: 2))),
      ChatMessage(timeDivider: 'Danas', isMe: false),
      ChatMessage(text: 'Hej, gdje si večeras?', isMe: false,
          sentAt: DateTime.now().subtract(const Duration(minutes: 20))),
    ]),
    ChatConversation(id: '3', name: 'Ivan', messages: [
      ChatMessage(text: 'Vidimo se na eventu!', isMe: false,
          sentAt: DateTime.now().subtract(const Duration(hours: 1))),
      ChatMessage(text: 'Super, čujemo se! 👋', isMe: true,
          sentAt: DateTime.now().subtract(const Duration(minutes: 55))),
    ]),
  ];

  int get totalUnread => conversations.where((c) => c.hasUnread).length;

  void addMessage(String conversationId, ChatMessage msg) {
    final idx = conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) return;
    final old = conversations[idx];
    conversations[idx] = ChatConversation(
        id: old.id, name: old.name,
        messages: List<ChatMessage>.from(old.messages)..add(msg));
    notifyListeners();
  }

  void deleteConversation(String id) {
    conversations.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CHAT LIST SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  late AnimationController _entryCtrl;
  late AnimationController _navBarCtrl;
  late AnimationController _headerCtrl;
  late AnimationController _listCtrl;
  late List<AnimationController> _navTapCtrls;

  late Animation<double> _entryFade;
  late Animation<double> _navBarSlide;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _listFade;
  late Animation<Offset> _listSlide;

  int _selectedNavIndex = 1;

  @override
  void initState() {
    super.initState();
    ChatState.instance.addListener(_onStateChanged);
    _searchCtrl.addListener(() => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()));

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));

    _listCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _listFade = CurvedAnimation(parent: _listCtrl, curve: Curves.easeOut);
    _listSlide = Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(CurvedAnimation(parent: _listCtrl, curve: Curves.easeOutCubic));

    _navBarCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _navBarSlide = Tween<double>(begin: 90, end: 0)
        .animate(CurvedAnimation(parent: _navBarCtrl, curve: Curves.easeOutBack));

    _navTapCtrls = List.generate(5, (_) =>
        AnimationController(vsync: this, duration: const Duration(milliseconds: 450)));
    _navTapCtrls[1].value = 1.0;

    _start();
  }

  Future<void> _start() async {
    _entryCtrl.forward();
    _headerCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _listCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _navBarCtrl.forward();
  }

  void _onStateChanged() => setState(() {});

  @override
  void dispose() {
    ChatState.instance.removeListener(_onStateChanged);
    _searchCtrl.dispose();
    _entryCtrl.dispose(); _headerCtrl.dispose(); _listCtrl.dispose(); _navBarCtrl.dispose();
    for (final c in _navTapCtrls) c.dispose();
    super.dispose();
  }

  List<ChatConversation> get _filtered {
    if (_searchQuery.isEmpty) return ChatState.instance.conversations;
    return ChatState.instance.conversations
        .where((c) => c.name.toLowerCase().contains(_searchQuery) ||
        c.lastMessageText.toLowerCase().contains(_searchQuery))
        .toList();
  }

  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    HapticFeedback.selectionClick();
    if (index == 0) { Navigator.pop(context); return; }
    _navTapCtrls[_selectedNavIndex].reverse();
    setState(() => _selectedNavIndex = index);
    _navTapCtrls[index].forward(from: 0.0);

    Widget? screen;
    switch (index) {
      case 3: screen = const ProfileScreen(); break;
      case 2: screen = const NotificationsScreen(); break;
      case 4: screen = const SettingsScreen(); break;
      default: screen = null;
    }
    if (screen != null) {
      Navigator.push(context, PageRouteBuilder(
        pageBuilder: (_, a, __) => screen!,
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 320),
      )).then((_) {
        _navTapCtrls[index].reverse();
        _navTapCtrls[1].forward(from: 0.0);
        setState(() => _selectedNavIndex = 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: kSurface,
      body: FadeTransition(
        opacity: _entryFade,
        child: Column(children: [
          _buildHeader(mq),
          Expanded(
            child: FadeTransition(
              opacity: _listFade,
              child: SlideTransition(
                position: _listSlide,
                child: filtered.isEmpty ? _buildEmpty() : _buildList(filtered),
              ),
            ),
          ),
          _buildNavBar(mq),
        ]),
      ),
    );
  }

  Widget _buildHeader(MediaQueryData mq) {
    final unread = ChatState.instance.totalUnread;
    return FadeTransition(
      opacity: _headerFade,
      child: SlideTransition(
        position: _headerSlide,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: kPrimaryDark.withOpacity(0.06), width: 1)),
            boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.07), blurRadius: 22, offset: const Offset(0, 5))],
          ),
          padding: EdgeInsets.only(top: mq.padding.top + 18, left: 20, right: 20, bottom: 18),
          child: Column(children: [
            // Title row
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Text('Poruke',
                        style: TextStyle(color: kPrimaryDark, fontSize: 28,
                            fontWeight: FontWeight.w900, letterSpacing: -0.8)),
                    const SizedBox(width: 10),
                    if (unread > 0)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutBack,
                        builder: (_, v, child) => Transform.scale(scale: v, child: child),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: kPrimaryDark,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('$unread',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 3),
                  Text('${ChatState.instance.conversations.length} razgovora',
                      style: TextStyle(color: kPrimaryDark.withOpacity(0.38), fontSize: 13, fontWeight: FontWeight.w500)),
                ]),
              ),
              // Compose button
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: kPrimaryDark,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))],
                  ),
                  child: const Icon(Icons.edit_rounded, color: Colors.white, size: 19),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            // Search bar
            Container(
              height: 46,
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kPrimaryDark.withOpacity(0.10), width: 1.2),
              ),
              child: Row(children: [
                const SizedBox(width: 13),
                Icon(Icons.search_rounded, color: kPrimaryDark.withOpacity(0.32), size: 19),
                const SizedBox(width: 9),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(color: kPrimaryDark, fontSize: 14, fontWeight: FontWeight.w400),
                    decoration: InputDecoration(
                      hintText: 'Pretraži razgovore...',
                      hintStyle: TextStyle(color: kPrimaryDark.withOpacity(0.30), fontSize: 14),
                      border: InputBorder.none, isDense: true,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () { _searchCtrl.clear(); FocusScope.of(context).unfocus(); },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Icon(Icons.close_rounded, color: kPrimaryDark.withOpacity(0.45), size: 18),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 96, height: 96,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [kPrimaryLight, kPrimaryDark.withOpacity(0.10)]),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.12), blurRadius: 28, offset: const Offset(0, 10))],
        ),
        child: Icon(Icons.chat_bubble_outline_rounded, color: kPrimaryDark, size: 38),
      ),
      const SizedBox(height: 22),
      Text(_searchQuery.isEmpty ? 'Nema poruka' : 'Nema rezultata',
          style: const TextStyle(color: kPrimaryDark, fontWeight: FontWeight.w800, fontSize: 18)),
      const SizedBox(height: 7),
      Text(_searchQuery.isEmpty ? 'Izađi i upoznaj svog Cutieja! 💘' : 'Pokušaj drugi pojam',
          style: TextStyle(color: kPrimaryDark.withOpacity(0.40), fontSize: 13.5)),
    ]));
  }

  Widget _buildList(List<ChatConversation> convos) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      itemCount: convos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final convo = convos[i];
        return _DismissibleTile(
          key: ValueKey(convo.id),
          convo: convo,
          onDelete: () { HapticFeedback.mediumImpact(); ChatState.instance.deleteConversation(convo.id); },
          onTap: () => Navigator.push(context, PageRouteBuilder(
            pageBuilder: (_, a, __) => ChatConversationScreen(convo: convo),
            transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
                    .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
                child: child,
              ),
            ),
            transitionDuration: const Duration(milliseconds: 280),
          )).then((_) => setState(() {})),
        );
      },
    );
  }

  Widget _buildNavBar(MediaQueryData mq) {
    return AnimatedBuilder(
      animation: _navBarSlide,
      builder: (_, child) => Transform.translate(offset: Offset(0, _navBarSlide.value), child: child),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: kPrimaryDark.withOpacity(0.06), width: 1)),
          boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.10), blurRadius: 28, offset: const Offset(0, -5))],
        ),
        padding: EdgeInsets.only(bottom: mq.padding.bottom + 4, top: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (i) => _buildNavItem(i)),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _selectedNavIndex == index;
    final item = kNavItems[index];
    final showBadge = index == 1 && !isSelected && ChatState.instance.totalUnread > 0;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: AnimatedBuilder(
        animation: _navTapCtrls[index],
        builder: (_, __) {
          final t = _navTapCtrls[index].value;
          final scale = isSelected ? 1.0 + 0.16 * Curves.elasticOut.transform(t.clamp(0.0, 1.0)) : 1.0;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Transform.scale(scale: scale,
              child: Stack(clipBehavior: Clip.none, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: kNavPadH, vertical: kNavPadV),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimaryDark.withOpacity(0.09) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(isSelected ? item.selected : item.unselected,
                      color: isSelected ? kPrimaryDark : kPrimaryDark.withOpacity(0.25),
                      size: kNavIconSize),
                ),
                if (showBadge) Positioned(top: 2, right: 4,
                  child: Container(width: 17, height: 17,
                    decoration: const BoxDecoration(color: kPrimaryDark, shape: BoxShape.circle),
                    child: Center(child: Text('${ChatState.instance.totalUnread}',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
                  ),
                ),
              ]),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? kNavDotSize : 0, height: isSelected ? kNavDotSize : 0,
              margin: const EdgeInsets.only(top: 2),
              decoration: const BoxDecoration(color: kPrimaryDark, shape: BoxShape.circle),
            ),
          ]);
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DISMISSIBLE TILE
// ═══════════════════════════════════════════════════════════════════════════════
class _DismissibleTile extends StatefulWidget {
  final ChatConversation convo;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _DismissibleTile({super.key, required this.convo, required this.onTap, required this.onDelete});
  @override State<_DismissibleTile> createState() => _DismissibleTileState();
}

class _DismissibleTileState extends State<_DismissibleTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _tap;
  late Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _tap = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
    _tapScale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _tap, curve: Curves.easeIn));
  }
  @override void dispose() { _tap.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final convo = widget.convo;
    final hasUnread = convo.hasUnread;

    return Dismissible(
      key: Key(convo.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        return await showDialog<bool>(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.18), blurRadius: 36, offset: const Offset(0, 14))],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 54, height: 54,
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.10), shape: BoxShape.circle),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 27)),
                const SizedBox(height: 14),
                const Text('Obriši razgovor?',
                    style: TextStyle(color: kPrimaryDark, fontWeight: FontWeight.w800, fontSize: 17)),
                const SizedBox(height: 8),
                Text('Ova radnja se ne može poništiti.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kPrimaryDark.withOpacity(0.45), fontSize: 13.5)),
                const SizedBox(height: 22),
                Row(children: [
                  Expanded(child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: kPrimaryDark.withOpacity(0.15))),
                    ),
                    child: Text('Odustani', style: TextStyle(color: kPrimaryDark.withOpacity(0.55), fontSize: 14)),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 13), elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Obriši', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  )),
                ]),
              ]),
            ),
          ),
        ) ?? false;
      },
      onDismissed: (_) => widget.onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withOpacity(0.15)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 23),
          const SizedBox(height: 3),
          const Text('Obriši', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      ),
      child: GestureDetector(
        onTapDown: (_) => _tap.forward(),
        onTapUp: (_) { _tap.reverse(); widget.onTap(); },
        onTapCancel: () => _tap.reverse(),
        child: ScaleTransition(
          scale: _tapScale,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kPrimaryDark.withOpacity(hasUnread ? 0.12 : 0.05), width: 1),
              boxShadow: [
                BoxShadow(color: kPrimaryDark.withOpacity(0.07), blurRadius: 18, offset: const Offset(0, 5)),
              ],
            ),
            child: Row(children: [
              // Avatar
              Container(width: 52, height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [kPrimaryLight, kPrimaryDark.withOpacity(0.14)]),
                  border: Border.all(color: kPrimaryDark.withOpacity(0.10), width: 2),
                ),
                child: Icon(Icons.person_rounded, color: kPrimaryDark, size: 26),
              ),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(convo.name, style: TextStyle(
                    color: kPrimaryDark,
                    fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                    fontSize: 15.5,
                  )),
                  const Spacer(),
                  // Time
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: hasUnread ? kPrimaryDark.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(convo.lastMessageTime, style: TextStyle(
                      color: hasUnread ? kPrimaryDark : kPrimaryDark.withOpacity(0.30),
                      fontSize: 12, fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                    )),
                  ),
                ]),
                const SizedBox(height: 5),
                Row(children: [
                  Expanded(child: Text(convo.lastMessageText,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: kPrimaryDark.withOpacity(hasUnread ? 0.75 : 0.35),
                        fontSize: 13.5,
                        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                      ))),
                  if (hasUnread) ...[
                    const SizedBox(width: 8),
                    Container(width: 9, height: 9,
                        decoration: const BoxDecoration(color: kPrimaryDark, shape: BoxShape.circle)),
                  ],
                ]),
              ])),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CHAT CONVERSATION SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class ChatConversationScreen extends StatefulWidget {
  final ChatConversation convo;
  const ChatConversationScreen({super.key, required this.convo});
  @override State<ChatConversationScreen> createState() => _ConvoState();
}

class _ConvoState extends State<ChatConversationScreen> with TickerProviderStateMixin {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();

  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  List<ChatMessage> get _messages {
    final convo = ChatState.instance.conversations
        .firstWhere((c) => c.id == widget.convo.id, orElse: () => widget.convo);
    return convo.messages;
  }

  @override
  void initState() {
    super.initState();
    ChatState.instance.addListener(_rebuild);
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));
    _headerCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _rebuild() => setState(() {});
  @override
  void dispose() {
    ChatState.instance.removeListener(_rebuild);
    _headerCtrl.dispose();
    _textCtrl.dispose(); _scrollCtrl.dispose(); _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _sendMessage() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    _textCtrl.clear();
    final convo = ChatState.instance.conversations
        .firstWhere((c) => c.id == widget.convo.id, orElse: () => widget.convo);
    final idx = ChatState.instance.conversations.indexWhere((c) => c.id == widget.convo.id);
    if (idx != -1) ChatState.instance.conversations[idx] = ChatConversation(
        id: convo.id, name: convo.name,
        messages: List<ChatMessage>.from(convo.messages)
          ..add(ChatMessage(text: text, isMe: true, sentAt: DateTime.now())));
    setState(() {});
    ChatState.instance.notifyListeners();
    Future.delayed(const Duration(milliseconds: 60), _scrollToBottom);
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    HapticFeedback.lightImpact();
    final convo = ChatState.instance.conversations
        .firstWhere((c) => c.id == widget.convo.id, orElse: () => widget.convo);
    final idx = ChatState.instance.conversations.indexWhere((c) => c.id == widget.convo.id);
    if (idx != -1) ChatState.instance.conversations[idx] = ChatConversation(
        id: convo.id, name: convo.name,
        messages: List<ChatMessage>.from(convo.messages)
          ..add(ChatMessage(imagePath: picked.path, isMe: true, sentAt: DateTime.now())));
    setState(() {});
    ChatState.instance.notifyListeners();
    Future.delayed(const Duration(milliseconds: 60), _scrollToBottom);
  }

  void _onAvatarTap() => Navigator.push(context, PageRouteBuilder(
    pageBuilder: (_, a, __) => const ProfileScreen(),
    transitionsBuilder: (_, a, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: a, curve: Curves.easeIn),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1.0)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
    transitionDuration: const Duration(milliseconds: 320),
  ));

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: kSurface,
      body: Column(children: [
        _buildHeader(mq),
        Expanded(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: ListView.builder(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _buildBubble(_messages[i]),
            ),
          ),
        ),
        _buildInput(mq),
      ]),
    );
  }

  Widget _buildHeader(MediaQueryData mq) {
    return FadeTransition(
      opacity: _headerFade,
      child: SlideTransition(
        position: _headerSlide,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: kPrimaryDark.withOpacity(0.06), width: 1)),
            boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.07), blurRadius: 18, offset: const Offset(0, 4))],
          ),
          padding: EdgeInsets.only(top: mq.padding.top + 10, left: 10, right: 16, bottom: 14),
          child: Row(children: [
            // Back
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: kPrimaryDark, size: 16),
              ),
            ),
            const SizedBox(width: 11),
            // Avatar
            GestureDetector(
              onTap: _onAvatarTap,
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [kPrimaryLight, kPrimaryDark.withOpacity(0.14)]),
                  border: Border.all(color: kPrimaryDark.withOpacity(0.14), width: 2),
                  boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.14), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Icon(Icons.person_rounded, color: kPrimaryDark, size: 23),
              ),
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              child: GestureDetector(
                onTap: _onAvatarTap,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.convo.name,
                      style: const TextStyle(color: kPrimaryDark, fontSize: 17,
                          fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  Text('Klikni za profil',
                      style: TextStyle(color: kPrimaryDark.withOpacity(0.32), fontSize: 12, fontWeight: FontWeight.w400)),
                ]),
              ),
            ),
            // More
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(13)),
              child: Icon(Icons.more_horiz_rounded, color: kPrimaryDark, size: 20),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    if (msg.timeDivider != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(children: [
          Expanded(child: Container(height: 1,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [
                Colors.transparent, kPrimaryDark.withOpacity(0.10), Colors.transparent,
              ])))),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPrimaryDark.withOpacity(0.08)),
              boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.04), blurRadius: 6)],
            ),
            child: Text(msg.timeDivider!,
                style: TextStyle(color: kPrimaryDark.withOpacity(0.40), fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Container(height: 1,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [
                Colors.transparent, kPrimaryDark.withOpacity(0.10), Colors.transparent,
              ])))),
        ]),
      );
    }

    final isMe = msg.isMe;
    final timeStr = _fmt(msg.sentAt);

    Widget bubble;
    if (msg.imagePath != null) {
      bubble = Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMe) _avatar(),
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              child: Image.file(File(msg.imagePath!), width: 195, height: 215, fit: BoxFit.cover),
            ),
          ],
        ),
      );
    } else {
      bubble = Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) _avatar(),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 268),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                decoration: BoxDecoration(
                  color: isMe ? kPrimaryDark : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  border: isMe ? null : Border.all(color: kPrimaryDark.withOpacity(0.07)),
                  boxShadow: [BoxShadow(
                    color: isMe ? kPrimaryDark.withOpacity(0.22) : kPrimaryDark.withOpacity(0.06),
                    blurRadius: 12, offset: const Offset(0, 4),
                  )],
                ),
                child: Text(msg.text ?? '',
                    style: TextStyle(
                      color: isMe ? Colors.white : kPrimaryDark,
                      fontSize: 14, height: 1.4, fontWeight: FontWeight.w400,
                    )),
              ),
            ),
          ],
        ),
      );
    }

    return _SwipeRevealTime(isMe: isMe, timeStr: timeStr, child: bubble);
  }

  Widget _avatar() {
    return GestureDetector(
      onTap: _onAvatarTap,
      child: Container(
        width: 30, height: 30,
        margin: const EdgeInsets.only(right: 7, bottom: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [kPrimaryLight, kPrimaryDark.withOpacity(0.12)]),
          border: Border.all(color: kPrimaryDark.withOpacity(0.12), width: 1.5),
        ),
        child: Icon(Icons.person_rounded, color: kPrimaryDark, size: 16),
      ),
    );
  }

  Widget _buildInput(MediaQueryData mq) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kPrimaryDark.withOpacity(0.07), width: 1)),
        boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      padding: EdgeInsets.only(left: 14, right: 14, top: 11, bottom: mq.padding.bottom + 11),
      child: Row(children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 42, height: 42, margin: const EdgeInsets.only(right: 9),
            decoration: BoxDecoration(
              color: kPrimaryLight, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kPrimaryDark.withOpacity(0.10)),
            ),
            child: Icon(Icons.add_photo_alternate_rounded, color: kPrimaryDark, size: 19),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: kSurface, borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kPrimaryDark.withOpacity(0.10), width: 1.2),
            ),
            child: TextField(
              controller: _textCtrl, focusNode: _focusNode,
              style: const TextStyle(color: kPrimaryDark, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Napiši poruku...',
                hintStyle: TextStyle(color: kPrimaryDark.withOpacity(0.28), fontSize: 14),
                filled: false,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
        ),
        GestureDetector(
          onTap: _sendMessage,
          child: Container(
            width: 42, height: 42, margin: const EdgeInsets.only(left: 9),
            decoration: BoxDecoration(
              color: kPrimaryDark,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))],
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SWIPE TO REVEAL TIME
// ═══════════════════════════════════════════════════════════════════════════════
class _SwipeRevealTime extends StatefulWidget {
  final Widget child;
  final bool isMe;
  final String timeStr;
  const _SwipeRevealTime({required this.child, required this.isMe, required this.timeStr});
  @override State<_SwipeRevealTime> createState() => _SwipeRevealTimeState();
}

class _SwipeRevealTimeState extends State<_SwipeRevealTime>
    with SingleTickerProviderStateMixin {
  late AnimationController _snap;
  double _offset = 0;
  static const double _max = 64;

  @override
  void initState() {
    super.initState();
    _snap = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
  }
  @override void dispose() { _snap.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (d) {
        setState(() => _offset = (_offset + d.primaryDelta!).clamp(-_max, 0));
      },
      onHorizontalDragEnd: (_) {
        final from = _offset;
        _snap.reset();
        _snap.addListener(() => setState(() =>
        _offset = _lerp(from, 0, Curves.easeOut.transform(_snap.value))));
        _snap.forward();
      },
      child: Stack(children: [
        // Time label
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: AnimatedOpacity(
                opacity: (-_offset / _max).clamp(0.0, 1.0),
                duration: Duration.zero,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kPrimaryDark.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(widget.timeStr,
                      style: TextStyle(color: kPrimaryDark.withOpacity(0.50),
                          fontSize: 11.5, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(_offset, 0),
          child: widget.child,
        ),
      ]),
    );
  }
}