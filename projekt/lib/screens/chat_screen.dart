import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart' show NotificationsScreen;

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════
class ChatMessage {
  final String? text;
  final String? imagePath;
  final bool isMe;
  final String? timeDivider;
  const ChatMessage({this.text, this.imagePath, required this.isMe, this.timeDivider});
}

class ChatConversation {
  final String id;
  final String name;
  final List<ChatMessage> messages;

  const ChatConversation({
    required this.id,
    required this.name,
    required this.messages,
  });

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

  bool get hasUnread => lastMessage != null && !lastMessage!.isMe;
}

// ═══════════════════════════════════════════════════════════════════════════════
// GLOBAL STATE
// ═══════════════════════════════════════════════════════════════════════════════
class ChatState extends ChangeNotifier {
  static final ChatState instance = ChatState._();
  ChatState._();

  final List<ChatConversation> conversations = [
    ChatConversation(
      id: '1',
      name: 'Luka',
      messages: const [
        ChatMessage(text: 'Hej! Vidio sam da si i ti na ovom eventu 😄', isMe: true),
        ChatMessage(text: 'Haha jaa, idem svake godine!', isMe: false),
        ChatMessage(text: 'Super! Možda se vidimo tamo?', isMe: true),
        ChatMessage(timeDivider: 'Danas, 9:41', isMe: false),
        ChatMessage(text: 'Gdje ćeš bit otprilike?', isMe: false),
        ChatMessage(text: 'Bit ću kod glavne pozornice 🎶', isMe: true),
        ChatMessage(text: 'Ok savršeno, i ja tamo!', isMe: false),
        ChatMessage(text: 'Haha ok, vidimo se onda 😄', isMe: true),
      ],
    ),
    ChatConversation(
      id: '2',
      name: 'Matej',
      messages: const [
        ChatMessage(text: 'Hej, kako si?', isMe: true),
        ChatMessage(timeDivider: 'Danas, 11:45', isMe: false),
        ChatMessage(text: 'Hej, gdje si večeras?', isMe: false),
      ],
    ),
    ChatConversation(
      id: '3',
      name: 'Ivan',
      messages: const [
        ChatMessage(text: 'Vidimo se na eventu!', isMe: false),
        ChatMessage(text: 'Super, čujemo se! 👋', isMe: true),
      ],
    ),
  ];

  int get totalUnread => conversations.where((c) => c.hasUnread).length;

  void addMessage(String conversationId, ChatMessage msg) {
    final idx = conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) return;
    final old = conversations[idx];
    final newMsgs = List<ChatMessage>.from(old.messages)..add(msg);
    conversations[idx] = ChatConversation(id: old.id, name: old.name, messages: newMsgs);
    notifyListeners();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CHAT LIST SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _navBarCtrl;
  late List<AnimationController> _navTapCtrls;

  late Animation<double> _fade;
  late Animation<double> _navBarSlide;

  int _selectedNavIndex = 1;

  @override
  void initState() {
    super.initState();
    ChatState.instance.addListener(_onStateChanged);

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _navBarCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _navBarSlide = Tween<double>(begin: 70, end: 0)
        .animate(CurvedAnimation(parent: _navBarCtrl, curve: Curves.easeOutBack));

    _navTapCtrls = List.generate(5, (_) =>
        AnimationController(vsync: this, duration: const Duration(milliseconds: 450)));
    _navTapCtrls[1].value = 1.0;

    _fadeCtrl.forward();
    _navBarCtrl.forward();
  }

  void _onStateChanged() => setState(() {});

  @override
  void dispose() {
    ChatState.instance.removeListener(_onStateChanged);
    _fadeCtrl.dispose();
    _navBarCtrl.dispose();
    for (final c in _navTapCtrls) c.dispose();
    super.dispose();
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
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: a,
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
    final convos = ChatState.instance.conversations;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            stops: [0.13, 0.97], colors: [kGradientStart, kGradientEnd],
          ),
        ),
        child: FadeTransition(
          opacity: _fade,
          child: Column(children: [
            _buildHeader(mq),
            Expanded(child: convos.isEmpty ? _buildEmpty() : _buildChatList(convos)),
            _buildNavBar(mq),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader(MediaQueryData mq) {
    return Container(
      color: kPrimaryLight,
      padding: EdgeInsets.only(
        top: mq.padding.top + kHeaderPadV,
        left: kHeaderPadH, right: kHeaderPadH, bottom: kHeaderPadV,
      ),
      child: const Row(children: [
        Icon(Icons.person_pin, color: kPrimaryDark, size: kHeaderIconSize),
        SizedBox(width: 6),
        Text('MeetCute',
            style: TextStyle(color: kPrimaryDark, fontSize: kHeaderFontSize,
                fontWeight: FontWeight.w800, letterSpacing: -0.3)),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Container(
        width: 200, height: 200,
        decoration: BoxDecoration(
          color: kPrimaryLight, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.10), blurRadius: 30, offset: const Offset(0, 6))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.group_outlined, color: kPrimaryDark, size: 38),
          const SizedBox(height: 10),
          const Text('Nema chata još...', style: TextStyle(color: kPrimaryDark, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Izađi i upoznaj svog Cutieja! 💘',
              textAlign: TextAlign.center,
              style: TextStyle(color: kPrimaryDark.withOpacity(0.55), fontSize: 11, fontStyle: FontStyle.italic)),
        ]),
      ),
    );
  }

  Widget _buildChatList(List<ChatConversation> convos) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: kContentPadH, vertical: 12),
      itemCount: convos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final convo = convos[i];
        return _ChatTile(
          convo: convo,
          onTap: () => Navigator.push(context, PageRouteBuilder(
            pageBuilder: (_, anim, __) => ChatConversationScreen(convo: convo),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
                    .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
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
          color: kPrimaryLight,
          boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.10), blurRadius: 16, offset: const Offset(0, -3))],
        ),
        padding: EdgeInsets.only(bottom: mq.padding.bottom + 4, top: 6),
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
          final scale = isSelected
              ? 1.0 + 0.18 * Curves.elasticOut.transform(t.clamp(0.0, 1.0))
              : 1.0;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Transform.scale(
              scale: scale,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: kNavPadH, vertical: kNavPadV),
                    decoration: BoxDecoration(
                      color: isSelected ? kPrimaryDark.withOpacity(0.10) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSelected ? item.selected : item.unselected,
                      color: isSelected ? kPrimaryDark : kPrimaryDark.withOpacity(0.35),
                      size: kNavIconSize,
                    ),
                  ),
                  if (showBadge)
                    Positioned(
                      top: 2, right: 4,
                      child: Container(
                        width: 16, height: 16,
                        decoration: const BoxDecoration(color: kPrimaryDark, shape: BoxShape.circle),
                        child: Center(
                          child: Text('${ChatState.instance.totalUnread}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: isSelected ? t.clamp(0.0, 1.0) : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: kNavDotSize, height: kNavDotSize,
                margin: const EdgeInsets.only(top: 2),
                decoration: const BoxDecoration(color: kPrimaryDark, shape: BoxShape.circle),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CHAT TILE
// ═══════════════════════════════════════════════════════════════════════════════
class _ChatTile extends StatefulWidget {
  final ChatConversation convo;
  final VoidCallback onTap;
  const _ChatTile({required this.convo, required this.onTap});
  @override
  State<_ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends State<_ChatTile> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final convo = widget.convo;
    final hasUnread = convo.hasUnread;
    final lastMsg = convo.lastMessageText;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: kPrimaryLight,
            borderRadius: BorderRadius.circular(kCardRadius),
            boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: kPrimaryDark,
                border: Border.all(color: kPrimaryDark, width: 2),
              ),
              child: const ClipOval(child: Icon(Icons.person, color: Colors.white, size: 26)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(convo.name, style: TextStyle(
                  color: kPrimaryDark,
                  fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                  fontSize: 14,
                )),
                const SizedBox(height: 2),
                Text(lastMsg,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: kPrimaryDark.withOpacity(hasUnread ? 0.9 : 0.55),
                      fontSize: 12,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                    )),
              ],
            )),
            const SizedBox(width: 8),
            if (hasUnread)
              Container(
                width: 20, height: 20,
                decoration: const BoxDecoration(color: kPrimaryDark, shape: BoxShape.circle),
                child: const Center(
                  child: Text('1', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
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
  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();

  List<ChatMessage> get _messages {
    final convo = ChatState.instance.conversations
        .firstWhere((c) => c.id == widget.convo.id, orElse: () => widget.convo);
    return convo.messages;
  }

  @override
  void initState() {
    super.initState();
    ChatState.instance.addListener(_onStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _onStateChanged() => setState(() {});

  @override
  void dispose() {
    ChatState.instance.removeListener(_onStateChanged);
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    _textCtrl.clear();
    final convo = ChatState.instance.conversations
        .firstWhere((c) => c.id == widget.convo.id, orElse: () => widget.convo);
    final newMsgs = List<ChatMessage>.from(convo.messages)
      ..add(ChatMessage(text: text, isMe: true));
    final idx = ChatState.instance.conversations.indexWhere((c) => c.id == widget.convo.id);
    if (idx != -1) {
      ChatState.instance.conversations[idx] =
          ChatConversation(id: convo.id, name: convo.name, messages: newMsgs);
    }
    setState(() {});
    ChatState.instance.notifyListeners();
    Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    HapticFeedback.lightImpact();
    final convo = ChatState.instance.conversations
        .firstWhere((c) => c.id == widget.convo.id, orElse: () => widget.convo);
    final newMsgs = List<ChatMessage>.from(convo.messages)
      ..add(ChatMessage(imagePath: picked.path, isMe: true));
    final idx = ChatState.instance.conversations.indexWhere((c) => c.id == widget.convo.id);
    if (idx != -1) {
      ChatState.instance.conversations[idx] =
          ChatConversation(id: convo.id, name: convo.name, messages: newMsgs);
    }
    setState(() {});
    ChatState.instance.notifyListeners();
    Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
  }

  void _onAvatarTap() {
    Navigator.push(context, PageRouteBuilder(
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
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            stops: [0.13, 0.97], colors: [kGradientStart, kGradientEnd],
          ),
        ),
        child: Column(children: [
          _buildHeader(mq),
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _buildBubble(_messages[i]),
              ),
            ),
          ),
          _buildInputBar(mq),
        ]),
      ),
    );
  }

  Widget _buildHeader(MediaQueryData mq) {
    return Container(
      color: kPrimaryLight,
      padding: EdgeInsets.only(
        top: mq.padding.top + kHeaderPadV,
        left: 4, right: kHeaderPadH, bottom: kHeaderPadV,
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kPrimaryDark, size: 18),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
        ),
        GestureDetector(
          onTap: _onAvatarTap,
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: kPrimaryDark,
              border: Border.all(color: kPrimaryDark, width: 2),
            ),
            child: const ClipOval(child: Icon(Icons.person, color: Colors.white, size: 20)),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _onAvatarTap,
          child: Text(widget.convo.name,
              style: const TextStyle(color: kPrimaryDark, fontSize: kHeaderFontSize,
                  fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        ),
      ]),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    if (msg.timeDivider != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Expanded(child: Divider(color: kPrimaryDark.withOpacity(0.15), thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(msg.timeDivider!, style: TextStyle(color: kPrimaryDark.withOpacity(0.40), fontSize: 11)),
          ),
          Expanded(child: Divider(color: kPrimaryDark.withOpacity(0.15), thickness: 0.5)),
        ]),
      );
    }

    final isMe = msg.isMe;

    if (msg.imagePath != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMe) _otherAvatar(),
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              child: Image.file(File(msg.imagePath!), width: 180, height: 200, fit: BoxFit.cover),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _otherAvatar(),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isMe ? kPrimaryDark : kPrimaryLight,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Text(msg.text ?? '',
                  style: TextStyle(color: isMe ? Colors.white : kPrimaryDark, fontSize: 13, height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _otherAvatar() {
    return GestureDetector(
      onTap: _onAvatarTap,
      child: Container(
        width: 26, height: 26,
        margin: const EdgeInsets.only(right: 6, bottom: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: kPrimaryDark,
          border: Border.all(color: kPrimaryDark, width: 1.5),
        ),
        child: const ClipOval(child: Icon(Icons.person, color: Colors.white, size: 15)),
      ),
    );
  }

  Widget _buildInputBar(MediaQueryData mq) {
    return Container(
      color: kPrimaryLight,
      padding: EdgeInsets.only(left: 12, right: 12, top: 8, bottom: mq.padding.bottom + 8),
      child: Row(children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 36, height: 36,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: kPrimaryDark.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(Icons.image_outlined, color: kPrimaryDark.withOpacity(0.6), size: 20),
          ),
        ),
        Expanded(
          child: TextField(
            controller: _textCtrl,
            focusNode: _focusNode,
            style: const TextStyle(color: kPrimaryDark, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Napiši poruku...',
              hintStyle: TextStyle(color: kPrimaryDark.withOpacity(0.35), fontSize: 13),
              filled: true, fillColor: const Color(0xFFEBD9DC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendMessage(),
          ),
        ),
        GestureDetector(
          onTap: _sendMessage,
          child: Container(
            width: 36, height: 36,
            margin: const EdgeInsets.only(left: 8),
            decoration: const BoxDecoration(color: kPrimaryDark, shape: BoxShape.circle),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
          ),
        ),
      ]),
    );
  }
}