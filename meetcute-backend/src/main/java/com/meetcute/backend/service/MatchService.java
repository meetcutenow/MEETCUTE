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
import java.util.UUID;
import java.util.stream.Collectors;
@Service
@RequiredArgsConstructor
public class MatchService {

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

    @Transactional
    public Optional<MatchResponse> likeUser(String likerId, LikeRequest req) {
        String likedId = req.getLikedUserId();

        if (likerId.equals(likedId)) {
            throw new RuntimeException("Ne možeš lajkati sam sebe.");
        }

        boolean mutual = likeRepository.existsByLikerIdAndLikedId(likedId, likerId);

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
            Match match = createMatch(likerId, likedId);
            return Optional.of(toMatchResponse(match, likerId));
        }

        return Optional.empty();
    }

    public List<MatchResponse> getMyMatches(String userId) {
        return matchRepository.findActiveByUserId(userId)
                .stream()
                .map(m -> toMatchResponse(m, userId))
                .collect(Collectors.toList());
    }

    @Transactional
    public MatchResponse checkSecretAnswer(Long matchId, String userId, SecretAnswerRequest req) {
        Match match = matchRepository.findById(matchId)
                .orElseThrow(() -> new RuntimeException("Match nije pronađen."));

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
            match.setStatus("chat_unlocked");
            match.setChatUnlockedAt(LocalDateTime.now());
            match.setExpiresAt(null);
            matchRepository.save(match);

            String convId = UUID.randomUUID().toString();
            Conversation conv = Conversation.builder()
                    .id(convId)
                    .match(match)
                    .build();
            conversationRepository.save(conv);

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

    private Match createMatch(String userAId, String userBId) {
        String a = userAId.compareTo(userBId) < 0 ? userAId : userBId;
        String b = userAId.compareTo(userBId) < 0 ? userBId : userAId;

        Optional<Match> existing = matchRepository.findByUserAIdAndUserBId(a, b);
        if (existing.isPresent()) return existing.get();

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

        copySecretQuestion(match, a);

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
