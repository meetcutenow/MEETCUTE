package com.meetcute.backend.service;

import com.meetcute.backend.dto.*;
import com.meetcute.backend.entity.*;
import com.meetcute.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.Year;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/service/Services.java
// ============================================================


// ── EVENT SERVICE ─────────────────────────────────────────────

@Service
@RequiredArgsConstructor
class EventService {

    private final EventRepository eventRepository;
    private final EventAttendeeRepository attendeeRepository;
    private final UserRepository userRepository;

    // Svi eventi (za home screen)
    public List<EventResponse> getAllEvents(String userId) {
        return eventRepository.findByIsActiveTrueOrderByEventDateAsc()
                .stream()
                .map(e -> toResponse(e, userId))
                .collect(Collectors.toList());
    }

    // Eventi po gradu
    public List<EventResponse> getEventsByCity(String city, String userId) {
        return eventRepository.findByCityAndIsActiveTrueOrderByEventDateAsc(city)
                .stream()
                .map(e -> toResponse(e, userId))
                .collect(Collectors.toList());
    }

    // Jedan event
    public EventResponse getEvent(String eventId, String userId) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new RuntimeException("Event nije pronađen."));
        return toResponse(event, userId);
    }

    // Kreiraj event (samo premium korisnici)
    @Transactional
    public EventResponse createEvent(CreateEventRequest req, String userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Korisnik nije pronađen."));

        if (!user.getIsPremium()) {
            throw new RuntimeException("Kreiranje evenata je dostupno samo Premium korisnicima.");
        }

        Event event = Event.builder()
                .creator(user)
                .title(req.getTitle())
                .description(req.getDescription())
                .city(req.getCity())
                .specificLocation(req.getSpecificLocation())
                .eventDate(LocalDate.parse(req.getEventDate()))
                .timeStart(req.getTimeStart() != null ? LocalTime.parse(req.getTimeStart()) : null)
                .timeEnd(req.getTimeEnd() != null ? LocalTime.parse(req.getTimeEnd()) : null)
                .category(req.getCategory())
                .ageGroup(req.getAgeGroup() != null ? req.getAgeGroup() : "all")
                .genderGroup(req.getGenderGroup() != null ? req.getGenderGroup() : "all")
                .maxAttendees(req.getMaxAttendees())
                .cardColorHex(req.getCardColorHex() != null ? req.getCardColorHex() : "#6DD5E8")
                .latitude(req.getLatitude())
                .longitude(req.getLongitude())
                .isUserEvent(true)
                .build();

        event = eventRepository.save(event);
        return toResponse(event, userId);
    }

    // Prijavi se / otkazi prijavu
    @Transactional
    public EventResponse toggleAttendance(String eventId, String userId) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new RuntimeException("Event nije pronađen."));

        EventAttendee.EventAttendeeId id = new EventAttendee.EventAttendeeId(eventId, userId);
        Optional<EventAttendee> existing = attendeeRepository.findByEventIdAndUserId(eventId, userId);

        if (existing.isPresent()) {
            EventAttendee attendee = existing.get();
            if ("joined".equals(attendee.getStatus())) {
                attendee.setStatus("cancelled");
            } else {
                // Provjeri kapacitet
                int count = attendeeRepository.countByEventIdAndStatus(eventId, "joined");
                if (event.getMaxAttendees() != null && count >= event.getMaxAttendees()) {
                    throw new RuntimeException("Event je popunjen.");
                }
                attendee.setStatus("joined");
            }
            attendeeRepository.save(attendee);
        } else {
            int count = attendeeRepository.countByEventIdAndStatus(eventId, "joined");
            if (event.getMaxAttendees() != null && count >= event.getMaxAttendees()) {
                throw new RuntimeException("Event je popunjen.");
            }
            User user = userRepository.getReferenceById(userId);
            EventAttendee attendee = EventAttendee.builder()
                    .id(id)
                    .event(event)
                    .user(user)
                    .status("joined")
                    .build();
            attendeeRepository.save(attendee);
        }

        return toResponse(event, userId);
    }

    private EventResponse toResponse(Event e, String userId) {
        int count = attendeeRepository.countByEventIdAndStatus(e.getId(), "joined");
        boolean attending = userId != null &&
                attendeeRepository.findByEventIdAndUserId(e.getId(), userId)
                        .map(a -> "joined".equals(a.getStatus()))
                        .orElse(false);

        return EventResponse.builder()
                .id(e.getId())
                .title(e.getTitle())
                .city(e.getCity())
                .specificLocation(e.getSpecificLocation())
                .eventDate(e.getEventDate() != null ? e.getEventDate().toString() : null)
                .timeStart(e.getTimeStart() != null ? e.getTimeStart().toString() : null)
                .timeEnd(e.getTimeEnd() != null ? e.getTimeEnd().toString() : null)
                .description(e.getDescription())
                .category(e.getCategory())
                .ageGroup(e.getAgeGroup())
                .genderGroup(e.getGenderGroup())
                .maxAttendees(e.getMaxAttendees())
                .attendeeCount(count)
                .isFull(e.getMaxAttendees() != null && count >= e.getMaxAttendees())
                .coverPhotoUrl(e.getCoverPhotoUrl())
                .cardColorHex(e.getCardColorHex())
                .isUserEvent(e.getIsUserEvent())
                .latitude(e.getLatitude())
                .longitude(e.getLongitude())
                .isAttending(attending)
                .build();
    }
}


// ── USER SERVICE ──────────────────────────────────────────────

@Service
@RequiredArgsConstructor
class UserService {

    private final UserRepository userRepository;
    private final UserProfileRepository profileRepository;
    private final UserPhotoRepository photoRepository;
    private final UserInterestRepository interestRepository;
    private final UserLocationRepository locationRepository;
    private final SecretQuestionRepository questionRepository;

    // Moj profil
    public UserResponse getMyProfile(String userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Korisnik nije pronađen."));
        return toResponse(user);
    }

    // Tuđi profil (za prikaz nakon proximity push)
    public UserResponse getUserProfile(String targetUserId) {
        User user = userRepository.findById(targetUserId)
                .orElseThrow(() -> new RuntimeException("Korisnik nije pronađen."));
        if (user.getIsBanned() || !user.getIsActive()) {
            throw new RuntimeException("Profil nije dostupan.");
        }
        return toResponse(user);
    }

    // Ažuriraj profil
    @Transactional
    public UserResponse updateProfile(String userId, UpdateProfileRequest req) {
        UserProfile profile = profileRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Profil nije pronađen."));

        if (req.getIceBreaker() != null) profile.setIceBreaker(req.getIceBreaker());
        if (req.getSeekingGender() != null)
            profile.setSeekingGender(UserProfile.SeekingGender.valueOf(req.getSeekingGender()));
        if (req.getMaxDistancePrefM() != null) profile.setMaxDistancePrefM(req.getMaxDistancePrefM());
        if (req.getIsVisible() != null) profile.setIsVisible(req.getIsVisible());

        profileRepository.save(profile);
        User user = userRepository.findById(userId).orElseThrow();
        return toResponse(user);
    }

    // Ažuriraj lokaciju
    @Transactional
    public void updateLocation(String userId, UpdateLocationRequest req) {
        User user = userRepository.getReferenceById(userId);
        UserLocation location = locationRepository.findById(userId)
                .orElse(UserLocation.builder().user(user).build());

        location.setLatitude(req.getLatitude());
        location.setLongitude(req.getLongitude());
        location.setCity(req.getCity());
        locationRepository.save(location);
    }

    // Toggle vidljivosti (lokacija ON/OFF iz home screena)
    @Transactional
    public Boolean toggleVisibility(String userId) {
        UserProfile profile = profileRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Profil nije pronađen."));
        profile.setIsVisible(!profile.getIsVisible());
        profileRepository.save(profile);
        return profile.getIsVisible();
    }

    // Sva pitanja (za registration screen)
    public List<SecretQuestionResponse> getSecretQuestions() {
        return questionRepository.findByIsActiveTrue()
                .stream()
                .map(q -> SecretQuestionResponse.builder()
                        .id(q.getId())
                        .questionText(q.getQuestionText())
                        .category(q.getCategory())
                        .build())
                .collect(Collectors.toList());
    }

    private UserResponse toResponse(User user) {
        List<String> photos = photoRepository
                .findByUserIdOrderByPhotoOrder(user.getId())
                .stream()
                .map(UserPhoto::getPhotoUrl)
                .collect(Collectors.toList());

        List<String> interests = interestRepository
                .findByUserId(user.getId())
                .stream()
                .map(ui -> ui.getInterest().getName())
                .collect(Collectors.toList());

        ProfileResponse profileResp = null;
        if (user.getProfile() != null) {
            UserProfile p = user.getProfile();
            int age = p.getBirthYear() != null
                    ? Year.now().getValue() - p.getBirthYear() : 0;
            profileResp = ProfileResponse.builder()
                    .birthYear(p.getBirthYear())
                    .age(age)
                    .gender(p.getGender() != null ? p.getGender().name() : null)
                    .seekingGender(p.getSeekingGender() != null ? p.getSeekingGender().name() : null)
                    .heightCm(p.getHeightCm())
                    .hairColor(p.getHairColor() != null ? p.getHairColor().name() : null)
                    .eyeColor(p.getEyeColor() != null ? p.getEyeColor().name() : null)
                    .hasPiercing(p.getHasPiercing())
                    .hasTattoo(p.getHasTattoo())
                    .iceBreaker(p.getIceBreaker())
                    .isVisible(p.getIsVisible())
                    .secretQuestion(p.getSecretQuestion() != null
                            ? p.getSecretQuestion().getQuestionText() : null)
                    .build();
        }

        return UserResponse.builder()
                .id(user.getId())
                .username(user.getUsername())
                .displayName(user.getDisplayName())
                .isPremium(user.getIsPremium())
                .profile(profileResp)
                .photoUrls(photos)
                .interests(interests)
                .build();
    }
}


// ── MATCH SERVICE ─────────────────────────────────────────────

@Service
@RequiredArgsConstructor
class MatchService {

    private final MatchRepository matchRepository;
    private final MatchSecretQuestionRepository matchQuestionRepository;
    private final ConversationRepository conversationRepository;
    private final ConversationParticipantRepository participantRepository;
    private final MessageRepository messageRepository;
    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final UserInterestRepository interestRepository;
    private final UserPhotoRepository photoRepository;
    private final LikeRepository likeRepository;
    private final PasswordEncoder passwordEncoder;

    // Lajkaj korisnika
    @Transactional
    public Optional<MatchResponse> likeUser(String likerId, LikeRequest req) {
        String likedId = req.getLikedUserId();

        if (likerId.equals(likedId)) {
            throw new RuntimeException("Ne možeš lajkati sam sebe.");
        }

        // Provjeri mutual like (je li B već lajkao A)
        boolean mutual = likeRepository.existsByLikerIdAndLikedId(likedId, likerId);

        // Spremi like
        if (!likeRepository.existsByLikerIdAndLikedId(likerId, likedId)) {
            Like like = Like.builder()
                    .likerId(likerId)
                    .likedId(likedId)
                    .contextType(req.getContextType() != null ? req.getContextType() : "proximity")
                    .contextEventId(req.getContextEventId())
                    .build();
            likeRepository.save(like);
        }
        if (mutual) {
            // Kreiraj match
            Match match = createMatch(likerId, likedId);
            return Optional.of(toMatchResponse(match, likerId));
        }

        return Optional.empty();
    }

    // Svi matchevi korisnika
    public List<MatchResponse> getMyMatches(String userId) {
        return matchRepository.findActiveByUserId(userId)
                .stream()
                .map(m -> toMatchResponse(m, userId))
                .collect(Collectors.toList());
    }

    // Odgovori na tajno pitanje
    @Transactional
    public MatchResponse checkSecretAnswer(Long matchId, String userId, SecretAnswerRequest req) {
        Match match = matchRepository.findById(matchId)
                .orElseThrow(() -> new RuntimeException("Match nije pronađen."));

        // Provjeri da je korisnik user_b
        if (!match.getUserB().getId().equals(userId)) {
            throw new RuntimeException("Samo druga osoba može odgovoriti na pitanje.");
        }

        if (!"chat_locked".equals(match.getStatus())) {
            throw new RuntimeException("Match nije u statusu chat_locked.");
        }

        MatchSecretQuestion question = matchQuestionRepository.findById(matchId)
                .orElseThrow(() -> new RuntimeException("Tajno pitanje nije pronađeno."));

        if (question.getAttemptsLeft() <= 0) {
            throw new RuntimeException("Nema više pokušaja.");
        }

        String normalizedAnswer = req.getAnswer().trim().toLowerCase();
        boolean correct = passwordEncoder.matches(normalizedAnswer, question.getAnswerHash());

        if (correct) {
            // Otključaj match
            match.setStatus("chat_unlocked");
            match.setChatUnlockedAt(LocalDateTime.now());
            match.setExpiresAt(null);
            matchRepository.save(match);

            // Kreiraj konverzaciju
            String convId = java.util.UUID.randomUUID().toString();
            Conversation conv = Conversation.builder()
                    .id(convId)
                    .match(match)
                    .build();
            conversationRepository.save(conv);

            // Dodaj sudionike
            ConversationParticipant cpA = ConversationParticipant.builder()
                    .id(new ConversationParticipant.ConversationParticipantId(
                            convId, match.getUserA().getId()))
                    .conversation(conv)
                    .user(match.getUserA())
                    .build();
            ConversationParticipant cpB = ConversationParticipant.builder()
                    .id(new ConversationParticipant.ConversationParticipantId(
                            convId, match.getUserB().getId()))
                    .conversation(conv)
                    .user(match.getUserB())
                    .build();
            participantRepository.save(cpA);
            participantRepository.save(cpB);

            // Notifikacije
            sendNotification(match.getUserA().getId(), "chat_unlocked",
                    "🎉 Chat otvoren!", "Tvoj match je točno odgovorio!", matchId, "#700D25");
            sendNotification(userId, "answer_correct",
                    "✅ Točan odgovor!", "Chat je otvoren. Počnite se dopisivati!", matchId, "#700D25");
        } else {
            question.setAttemptsLeft(question.getAttemptsLeft() - 1);
            matchQuestionRepository.save(question);

            sendNotification(userId, "answer_wrong", "❌ Netočan odgovor",
                    "Ostalo: " + question.getAttemptsLeft() + " pokušaja.", matchId, "#D93025");
        }

        return toMatchResponse(match, userId);
    }

    // Poruke u konverzaciji
    public List<MessageResponse> getMessages(String conversationId, String userId) {
        return messageRepository.findByConversationId(conversationId)
                .stream()
                .map(m -> MessageResponse.builder()
                        .id(m.getId())
                        .senderId(m.getSender().getId())
                        .senderName(m.getSender().getDisplayName())
                        .body(m.getBody())
                        .photoUrl(m.getPhotoUrl())
                        .sentAt(m.getSentAt())
                        .isMe(m.getSender().getId().equals(userId))
                        .build())
                .collect(Collectors.toList());
    }

    // Pošalji poruku
    @Transactional
    public MessageResponse sendMessage(String conversationId, String userId, SendMessageRequest req) {
        Conversation conv = conversationRepository.findById(conversationId)
                .orElseThrow(() -> new RuntimeException("Razgovor nije pronađen."));

        User sender = userRepository.getReferenceById(userId);

        Message message = Message.builder()
                .conversation(conv)
                .sender(sender)
                .body(req.getBody())
                .photoUrl(req.getPhotoUrl())
                .build();

        message = messageRepository.save(message);

        // Ažuriraj last_message_at
        conv.setLastMessageAt(LocalDateTime.now());
        conversationRepository.save(conv);

        return MessageResponse.builder()
                .id(message.getId())
                .senderId(userId)
                .senderName(sender.getDisplayName())
                .body(message.getBody())
                .photoUrl(message.getPhotoUrl())
                .sentAt(message.getSentAt())
                .isMe(true)
                .build();
    }

    // ── HELPER ───────────────────────────────────────────────

    private Match createMatch(String userAId, String userBId) {
        // Normalizacija UUID-a
        String a = userAId.compareTo(userBId) < 0 ? userAId : userBId;
        String b = userAId.compareTo(userBId) < 0 ? userBId : userAId;

        // Provjeri postoji li već
        Optional<Match> existing = matchRepository.findByUserAIdAndUserBId(a, b);
        if (existing.isPresent()) return existing.get();

        // Zajednički interesi
        int common = countCommonInterests(a, b);

        User userA = userRepository.getReferenceById(a);
        User userB = userRepository.getReferenceById(b);

        Match match = Match.builder()
                .userA(userA)
                .userB(userB)
                .commonInterests(common)
                .status("pending_meetup")
                .questionCreatorId(a)
                .expiresAt(LocalDateTime.now().plusHours(48))
                .build();

        match = matchRepository.save(match);

        // Kopiraj tajno pitanje
        copySecretQuestion(match, a);

        // Notifikacije
        Long matchId = match.getId();
        sendNotification(a, "mutual_like", "💘 Match!",
                "Svidjeli ste se međusobno! Pronađite se uživo.", matchId, "#700D25");
        sendNotification(b, "mutual_like", "💘 Match!",
                "Svidjeli ste se međusobno! Pronađite se uživo.", matchId, "#700D25");

        return match;
    }

    private void copySecretQuestion(Match match, String creatorId) {
        userRepository.findById(creatorId).ifPresent(user -> {
            if (user.getProfile() != null && user.getProfile().getSecretQuestion() != null) {
                MatchSecretQuestion msq = MatchSecretQuestion.builder()
                        .match(match)
                        .questionText(user.getProfile().getSecretQuestion().getQuestionText())
                        .answerHash(user.getProfile().getSecretAnswer())
                        .build();
                matchQuestionRepository.save(msq);
            }
        });
    }

    private int countCommonInterests(String userAId, String userBId) {
        List<Integer> aInterests = interestRepository.findByUserId(userAId)
                .stream().map(ui -> ui.getId().getInterestId()).collect(Collectors.toList());
        List<Integer> bInterests = interestRepository.findByUserId(userBId)
                .stream().map(ui -> ui.getId().getInterestId()).collect(Collectors.toList());
        aInterests.retainAll(bInterests);
        return aInterests.size();
    }

    private void sendNotification(String userId, String type, String title,
                                   String body, Long matchId, String color) {
        User user = userRepository.getReferenceById(userId);
        Notification n = Notification.builder()
                .user(user)
                .type(type)
                .title(title)
                .body(body)
                .matchId(matchId)
                .accentColor(color)
                .build();
        notificationRepository.save(n);
    }

    private String getPrimaryPhoto(String userId) {
        return photoRepository.findByUserIdOrderByPhotoOrder(userId)
                .stream()
                .filter(UserPhoto::getIsPrimary)
                .map(UserPhoto::getPhotoUrl)
                .findFirst()
                .orElse(null);
    }

    private MatchResponse toMatchResponse(Match match, String requestingUserId) {
        boolean isA = match.getUserA().getId().equals(requestingUserId);
        User other = isA ? match.getUserB() : match.getUserA();

        MatchSecretQuestion question = matchQuestionRepository.findById(match.getId()).orElse(null);
        Conversation conv = conversationRepository.findByMatchId(match.getId()).orElse(null);

        return MatchResponse.builder()
                .matchId(match.getId())
                .otherUserId(other.getId())
                .otherUserName(other.getDisplayName())
                .otherUserPhoto(getPrimaryPhoto(other.getId()))
                .commonInterests(match.getCommonInterests())
                .distanceM(match.getDistanceM())
                .status(match.getStatus())
                .matchedAt(match.getMatchedAt())
                .conversationId(conv != null ? conv.getId() : null)
                .secretQuestion(question != null ? question.getQuestionText() : null)
                .attemptsLeft(question != null ? question.getAttemptsLeft() : null)
                .build();
    }
}
