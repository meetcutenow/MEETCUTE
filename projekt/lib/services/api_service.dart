import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _base = 'http://localhost:8080/api';
  static const String _tokenKey = 'access_token';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() { _loadToken(); }

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  bool get isLoggedIn => AuthState.instance.isLoggedIn;

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (AuthState.instance.accessToken != null)
      'Authorization': 'Bearer ${AuthState.instance.accessToken}',
  };

  Map<String, String> get _publicHeaders => {
    'Content-Type': 'application/json',
  };

  Future<Map<String, dynamic>> _get(String path, {bool auth = true}) async {
    final resp = await http.get(
      Uri.parse('$_base$path'),
      headers: auth ? _authHeaders : _publicHeaders,
    );
    return _handle(resp);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final resp = await http.post(
      Uri.parse('$_base$path'),
      headers: auth ? _authHeaders : _publicHeaders,
      body: jsonEncode(body),
    );
    return _handle(resp);
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final resp = await http.put(
      Uri.parse('$_base$path'),
      headers: auth ? _authHeaders : _publicHeaders,
      body: jsonEncode(body),
    );
    return _handle(resp);
  }

  Map<String, dynamic> _handle(http.Response resp) {
    final body = utf8.decode(resp.bodyBytes).trim();
    if (body.isEmpty) {
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return {'success': true, 'data': null};
      }
      throw ApiException('Greška servera (\${resp.statusCode})', resp.statusCode);
    }
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return decoded;
    }
    final msg = decoded['message'] ?? 'Greška servera (\${resp.statusCode})';
    throw ApiException(msg, resp.statusCode);
  }


  Future<AuthResult> register(RegisterPayload payload) async {
    final resp = await _post('/auth/register', payload.toJson(), auth: false);
    return _saveTokens(resp);
  }

  /// Učitaj token iz diska pri pokretanju
  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_tokenKey);
    } catch (_) {}
  }

  /// Spremi token na disk
  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (_) {}
  }

  /// Obrisi token s diska
  Future<void> _clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (_) {}
  }

  Future<AuthResult> login(String username, String password) async {
    final resp = await _post('/auth/login',
        {'username': username, 'password': password}, auth: false);
    return _saveTokens(resp);
  }

  Future<AuthResult> refreshToken() async {
    if (_refreshToken == null) throw ApiException('Nisi prijavljen/a', 401);
    final resp = await _post('/auth/refresh',
        {'refreshToken': _refreshToken!}, auth: false);
    return _saveTokens(resp);
  }

  Future<void> logout() async {
    if (_refreshToken != null) {
      try {
        await _post('/auth/logout', {'refreshToken': _refreshToken!});
      } catch (_) {}
    }
    _accessToken = null;
    _clearToken();
    _refreshToken = null;
  }

  AuthResult _saveTokens(Map<String, dynamic> resp) {
    final data = resp['data'] as Map<String, dynamic>;
    _accessToken = data['accessToken'];
    _saveToken(_accessToken!);
    _refreshToken = data['refreshToken'];
    return AuthResult.fromJson(data);
  }

  Future<UserData> getMyProfile() async {
    final resp = await _get('/users/me');
    return UserData.fromJson(resp['data']);
  }

  Future<UserData> getUserProfile(String userId) async {
    final resp = await _get('/users/$userId');
    return UserData.fromJson(resp['data']);
  }

  Future<UserData> updateProfile({
    String? iceBreaker,
    String? seekingGender,
    int? maxDistancePrefM,
    bool? isVisible,
  }) async {
    final resp = await _put('/users/me', {
      if (iceBreaker != null) 'iceBreaker': iceBreaker,
      if (seekingGender != null) 'seekingGender': seekingGender,
      if (maxDistancePrefM != null) 'maxDistancePrefM': maxDistancePrefM,
      if (isVisible != null) 'isVisible': isVisible,
    });
    return UserData.fromJson(resp['data']);
  }

  Future<void> updateLocation(double lat, double lng, {String? city}) async {
    await _put('/users/me/location', {
      'latitude': lat,
      'longitude': lng,
      if (city != null) 'city': city,
    });
  }

  Future<bool> toggleVisibility() async {
    final resp = await _post('/users/me/visibility', {});
    return resp['data']['isVisible'] as bool;
  }

  Future<List<SecretQuestion>> getSecretQuestions() async {
    final resp = await _get('/questions', auth: false);
    final list = resp['data'] as List;
    return list.map((e) => SecretQuestion.fromJson(e)).toList();
  }

  Future<List<EventData>> getEvents({String? city}) async {
    final path = city != null ? '/events?city=$city' : '/events';
    final resp = await _get(path, auth: false);
    final list = resp['data'] as List;
    return list.map((e) => EventData.fromJson(e)).toList();
  }

  Future<EventData> getEvent(String id) async {
    final resp = await _get('/events/$id', auth: false);
    return EventData.fromJson(resp['data']);
  }

  Future<EventData> createEvent(CreateEventPayload payload) async {
    final resp = await _post('/events', payload.toJson());
    return EventData.fromJson(resp['data']);
  }

  Future<EventData> toggleAttendance(String eventId) async {
    final resp = await _post('/events/$eventId/attend', {});
    return EventData.fromJson(resp['data']);
  }

  Future<MatchData?> likeUser(String likedUserId,
      {String contextType = 'proximity', String? contextEventId}) async {
    final resp = await _post('/likes', {
      'likedUserId': likedUserId,
      'contextType': contextType,
      if (contextEventId != null) 'contextEventId': contextEventId,
    });
    if (resp['data'] == null) return null;
    return MatchData.fromJson(resp['data']);
  }

  Future<List<MatchData>> getMatches() async {
    final resp = await _get('/matches');
    final list = resp['data'] as List;
    return list.map((e) => MatchData.fromJson(e)).toList();
  }

  Future<MatchData> answerSecretQuestion(int matchId, String answer) async {
    final resp = await _post('/matches/$matchId/answer', {'answer': answer});
    return MatchData.fromJson(resp['data']);
  }

  Future<List<MessageData>> getMessages(String conversationId) async {
    final resp = await _get('/conversations/$conversationId/messages');
    final list = resp['data'] as List;
    return list.map((e) => MessageData.fromJson(e)).toList();
  }

  Future<MessageData> sendMessage(String conversationId, String body,
      {String? photoUrl}) async {
    final resp = await _post('/conversations/$conversationId/messages', {
      'body': body,
      if (photoUrl != null) 'photoUrl': photoUrl,
    });
    return MessageData.fromJson(resp['data']);
  }

  Future<List<NotificationData>> getNotifications() async {
    final resp = await _get('/notifications');
    final list = resp['data'] as List;
    return list.map((e) => NotificationData.fromJson(e)).toList();
  }

  Future<void> markAllNotificationsRead() async {
    await _post('/notifications/read', {});
  }

  // ─── Proximity / Matching ─────────────────────────────────────

  Future<bool> setActiveStatus(bool active, {double? lat, double? lng}) async {
    final resp = await _post('/proximity/active', {
      'active': active,
      if (lat != null) 'latitude': lat,
      if (lng != null) 'longitude': lng,
    });
    return resp['data']['active'] as bool;
  }

  Future<bool> getActiveStatus() async {
    final resp = await _get('/proximity/active/status');
    return resp['data']['active'] as bool? ?? false;
  }

  Future<List<NearbyUserData>> scanNearby(double lat, double lng) async {
    final resp = await _post('/proximity/scan', {
      'latitude': lat,
      'longitude': lng,
    });
    if (resp['data'] == null) return [];
    final list = resp['data'] as List;
    return list.map((e) => NearbyUserData.fromJson(e)).toList();
  }

  Future<LikeResultData?> react(String targetUserId, bool liked) async {
    final resp = await _post('/proximity/react', {
      'targetUserId': targetUserId,
      'liked': liked,
    });
    if (resp['data'] == null) return null;
    return LikeResultData.fromJson(resp['data']);
  }

  Future<List<ConversationData>> getConversations() async {
    final resp = await _get('/conversations');
    final list = resp['data'] as List? ?? [];
    return list.map((e) => ConversationData.fromJson(e)).toList();
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final UserData user;

  AuthResult({required this.accessToken, required this.refreshToken, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
    accessToken: j['accessToken'],
    refreshToken: j['refreshToken'],
    user: UserData.fromJson(j['user']),
  );
}

class UserData {
  final String id;
  final String username;
  final String displayName;
  final bool isPremium;
  final ProfileData? profile;
  final List<String> photoUrls;
  final List<String> interests;

  UserData({
    required this.id,
    required this.username,
    required this.displayName,
    required this.isPremium,
    this.profile,
    required this.photoUrls,
    required this.interests,
  });

  factory UserData.fromJson(Map<String, dynamic> j) => UserData(
    id: j['id'],
    username: j['username'],
    displayName: j['displayName'],
    isPremium: j['isPremium'] ?? false,
    profile: j['profile'] != null ? ProfileData.fromJson(j['profile']) : null,
    photoUrls: List<String>.from(j['photoUrls'] ?? []),
    interests: List<String>.from(j['interests'] ?? []),
  );
}

class ProfileData {
  final int? birthYear;
  final int? age;
  final String? gender;
  final String? seekingGender;
  final int? heightCm;
  final String? hairColor;
  final String? eyeColor;
  final bool? hasPiercing;
  final bool? hasTattoo;
  final String? iceBreaker;
  final bool? isVisible;
  final String? secretQuestion;

  ProfileData({
    this.birthYear, this.age, this.gender, this.seekingGender,
    this.heightCm, this.hairColor, this.eyeColor, this.hasPiercing,
    this.hasTattoo, this.iceBreaker, this.isVisible, this.secretQuestion,
  });

  factory ProfileData.fromJson(Map<String, dynamic> j) => ProfileData(
    birthYear: j['birthYear'],
    age: j['age'],
    gender: j['gender'],
    seekingGender: j['seekingGender'],
    heightCm: j['heightCm'],
    hairColor: j['hairColor'],
    eyeColor: j['eyeColor'],
    hasPiercing: j['hasPiercing'],
    hasTattoo: j['hasTattoo'],
    iceBreaker: j['iceBreaker'],
    isVisible: j['isVisible'],
    secretQuestion: j['secretQuestion'],
  );
}

class SecretQuestion {
  final int id;
  final String questionText;
  final String? category;

  SecretQuestion({required this.id, required this.questionText, this.category});

  factory SecretQuestion.fromJson(Map<String, dynamic> j) => SecretQuestion(
    id: j['id'],
    questionText: j['questionText'],
    category: j['category'],
  );
}

class EventData {
  final String id;
  final String title;
  final String city;
  final String? specificLocation;
  final String? eventDate;
  final String? timeStart;
  final String? timeEnd;
  final String? description;
  final String? category;
  final String? ageGroup;
  final String? genderGroup;
  final int? maxAttendees;
  final int attendeeCount;
  final bool isFull;
  final String? coverPhotoUrl;
  final String? cardColorHex;
  final bool isUserEvent;
  final double? latitude;
  final double? longitude;
  final bool isAttending;

  EventData({
    required this.id, required this.title, required this.city,
    this.specificLocation, this.eventDate, this.timeStart, this.timeEnd,
    this.description, this.category, this.ageGroup, this.genderGroup,
    this.maxAttendees, required this.attendeeCount, required this.isFull,
    this.coverPhotoUrl, this.cardColorHex, required this.isUserEvent,
    this.latitude, this.longitude, required this.isAttending,
  });

  factory EventData.fromJson(Map<String, dynamic> j) => EventData(
    id: j['id'],
    title: j['title'],
    city: j['city'],
    specificLocation: j['specificLocation'],
    eventDate: j['eventDate'],
    timeStart: j['timeStart'],
    timeEnd: j['timeEnd'],
    description: j['description'],
    category: j['category'],
    ageGroup: j['ageGroup'],
    genderGroup: j['genderGroup'],
    maxAttendees: j['maxAttendees'],
    attendeeCount: j['attendeeCount'] ?? 0,
    isFull: j['isFull'] ?? false,
    coverPhotoUrl: j['coverPhotoUrl'],
    cardColorHex: j['cardColorHex'],
    isUserEvent: j['isUserEvent'] ?? false,
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
    isAttending: j['isAttending'] ?? false,
  );
}

class MatchData {
  final int matchId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;
  final int? commonInterests;
  final int? distanceM;
  final String status;
  final String? matchedAt;
  final String? conversationId;
  final String? secretQuestion;
  final int? attemptsLeft;

  MatchData({
    required this.matchId, required this.otherUserId, required this.otherUserName,
    this.otherUserPhoto, this.commonInterests, this.distanceM,
    required this.status, this.matchedAt, this.conversationId,
    this.secretQuestion, this.attemptsLeft,
  });

  factory MatchData.fromJson(Map<String, dynamic> j) => MatchData(
    matchId: j['matchId'],
    otherUserId: j['otherUserId'],
    otherUserName: j['otherUserName'],
    otherUserPhoto: j['otherUserPhoto'],
    commonInterests: j['commonInterests'],
    distanceM: j['distanceM'],
    status: j['status'],
    matchedAt: j['matchedAt'],
    conversationId: j['conversationId'],
    secretQuestion: j['secretQuestion'],
    attemptsLeft: j['attemptsLeft'],
  );
}

class MessageData {
  final int id;
  final String senderId;
  final String senderName;
  final String? body;
  final String? photoUrl;
  final String? sentAt;
  final bool isMe;

  MessageData({
    required this.id, required this.senderId, required this.senderName,
    this.body, this.photoUrl, this.sentAt, required this.isMe,
  });

  factory MessageData.fromJson(Map<String, dynamic> j) => MessageData(
    id: j['id'],
    senderId: j['senderId'],
    senderName: j['senderName'],
    body: j['body'],
    photoUrl: j['photoUrl'],
    sentAt: j['sentAt'],
    isMe: j['isMe'] ?? false,
  );
}

class NotificationData {
  final int id;
  final String type;
  final String title;
  final String body;
  final String? eventId;
  final int? matchId;
  final bool isRead;
  final String? accentColor;
  final String? createdAt;

  NotificationData({
    required this.id, required this.type, required this.title, required this.body,
    this.eventId, this.matchId, required this.isRead, this.accentColor, this.createdAt,
  });

  factory NotificationData.fromJson(Map<String, dynamic> j) => NotificationData(
    id: j['id'],
    type: j['type'],
    title: j['title'],
    body: j['body'],
    eventId: j['eventId'],
    matchId: j['matchId'],
    isRead: j['isRead'] ?? false,
    accentColor: j['accentColor'],
    createdAt: j['createdAt'],
  );
}

class RegisterPayload {
  final String username;
  final String displayName;
  final String password;
  final int birthDay;
  final int birthMonth;
  final int birthYear;
  final int heightCm;
  final String gender;
  final String hairColor;
  final String eyeColor;
  final bool hasPiercing;
  final bool hasTattoo;
  final List<int> interestIds;
  final String iceBreaker;
  final int secretQuestionId;
  final String secretAnswer;

  RegisterPayload({
    required this.username, required this.displayName, required this.password,
    required this.birthDay, required this.birthMonth, required this.birthYear,
    required this.heightCm, required this.gender, required this.hairColor,
    required this.eyeColor, required this.hasPiercing, required this.hasTattoo,
    required this.interestIds, required this.iceBreaker,
    required this.secretQuestionId, required this.secretAnswer,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'displayName': displayName,
    'password': password,
    'birthDay': birthDay,
    'birthMonth': birthMonth,
    'birthYear': birthYear,
    'heightCm': heightCm,
    'gender': gender,
    'hairColor': hairColor,
    'eyeColor': eyeColor,
    'hasPiercing': hasPiercing,
    'hasTattoo': hasTattoo,
    'interestIds': interestIds,
    'iceBreaker': iceBreaker,
    'secretQuestionId': secretQuestionId,
    'secretAnswer': secretAnswer,
  };
}

class CreateEventPayload {
  final String title;
  final String? description;
  final String city;
  final String? specificLocation;
  final String eventDate;
  final String? timeStart;
  final String? timeEnd;
  final String category;
  final String? ageGroup;
  final String? genderGroup;
  final int? maxAttendees;
  final String? cardColorHex;
  final double? latitude;
  final double? longitude;

  CreateEventPayload({
    required this.title, this.description, required this.city,
    this.specificLocation, required this.eventDate, this.timeStart, this.timeEnd,
    required this.category, this.ageGroup, this.genderGroup, this.maxAttendees,
    this.cardColorHex, this.latitude, this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    if (description != null) 'description': description,
    'city': city,
    if (specificLocation != null) 'specificLocation': specificLocation,
    'eventDate': eventDate,
    if (timeStart != null) 'timeStart': timeStart,
    if (timeEnd != null) 'timeEnd': timeEnd,
    'category': category,
    if (ageGroup != null) 'ageGroup': ageGroup,
    if (genderGroup != null) 'genderGroup': genderGroup,
    if (maxAttendees != null) 'maxAttendees': maxAttendees,
    if (cardColorHex != null) 'cardColorHex': cardColorHex,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };
}

class NearbyUserData {
  final String userId;
  final String displayName;
  final String? primaryPhoto;
  final List<String> allPhotos;
  final String? iceBreaker;
  final int? age;
  final int? heightCm;
  final String? gender;
  final String? hairColor;
  final String? eyeColor;
  final bool? hasTattoo;
  final bool? hasPiercing;
  final List<String> interests;
  final int commonInterests;

  NearbyUserData({
    required this.userId,
    required this.displayName,
    this.primaryPhoto,
    required this.allPhotos,
    this.iceBreaker,
    this.age,
    this.heightCm,
    this.gender,
    this.hairColor,
    this.eyeColor,
    this.hasTattoo,
    this.hasPiercing,
    required this.interests,
    required this.commonInterests,
  });

  factory NearbyUserData.fromJson(Map<String, dynamic> j) => NearbyUserData(
    userId: j['userId'],
    displayName: j['displayName'],
    primaryPhoto: j['primaryPhoto'],
    allPhotos: List<String>.from(j['allPhotos'] ?? []),
    iceBreaker: j['iceBreaker'],
    age: j['age'],
    heightCm: j['heightCm'],
    gender: j['gender'],
    hairColor: j['hairColor'],
    eyeColor: j['eyeColor'],
    hasTattoo: j['hasTattoo'],
    hasPiercing: j['hasPiercing'],
    interests: List<String>.from(j['interests'] ?? []),
    commonInterests: j['commonInterests'] ?? 0,
  );
}

class LikeResultData {
  final bool matched;
  final MatchData? match;
  final String? myPhoto;
  final String? otherPhoto;
  final String? otherUserName;

  LikeResultData({
    required this.matched,
    this.match,
    this.myPhoto,
    this.otherPhoto,
    this.otherUserName,
  });

  factory LikeResultData.fromJson(Map<String, dynamic> j) => LikeResultData(
    matched: j['matched'] ?? false,
    match: j['match'] != null ? MatchData.fromJson(j['match']) : null,
    myPhoto: j['myPhoto'],
    otherPhoto: j['otherPhoto'],
    otherUserName: j['otherUserName'],
  );
}

class ConversationData {
  final String id;
  final String otherUserName;
  final String? otherUserPhoto;
  final String? lastMessage;
  final String? lastMessageAt;
  final int? lastMessageId;
  final String? lastMessageSenderId;

  ConversationData({
    required this.id,
    required this.otherUserName,
    this.otherUserPhoto,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageId,
    this.lastMessageSenderId,
  });

  factory ConversationData.fromJson(Map<String, dynamic> j) => ConversationData(
    id: j['id'],
    otherUserName: j['otherUserName'] ?? 'Korisnik',
    otherUserPhoto: j['otherUserPhoto'],
    lastMessage: j['lastMessage'],
    lastMessageAt: j['lastMessageAt'],
    lastMessageId: j['lastMessageId'],
    lastMessageSenderId: j['lastMessageSenderId'],
  );
}