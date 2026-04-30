package com.meetcute.backend.service;

import com.meetcute.backend.dto.*;
import com.meetcute.backend.entity.*;
import com.meetcute.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MatchService {

    private final MatchRepository matchRepository;
    private final ConversationRepository conversationRepository;
    private final ConversationParticipantRepository participantRepository;
    private final MessageRepository messageRepository;
    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final UserInterestRepository interestRepository;
    private final UserPhotoRepository photoRepository;
    private final LikeRepository likeRepository;

    @Transactional
    public Optional<MatchResponse> likeUser(String likerId, LikeRequest req) {
        String likedId = req.getLikedUserId();

        if (likerId.equals(likedId))
            throw new RuntimeException("Ne možeš lajkati sam sebe.");

        boolean mutual = likeRepository.existsByLikerIdAndLikedId(likedId, likerId);

        if (!likeRepository.existsByLikerIdAndLikedId(likerId, likedId))
            likeRepository.save(Like.builder()
                    .likerId(likerId)
                    .likedId(likedId)
                    .contextType(req.getContextType() != null ? req.getContextType() : "proximity")
                    .contextEventId(req.getContextEventId())
                    .build());

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

        Message message = messageRepository.save(Message.builder()
                .conversation(conv)
                .sender(sender)
                .body(req.getBody())
                .photoUrl(req.getPhotoUrl())
                .build());

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

        Match match = matchRepository.save(Match.builder()
                .userA(userRepository.getReferenceById(a))
                .userB(userRepository.getReferenceById(b))
                .commonInterests(countCommonInterests(a, b))
                .status("pending_meetup")
                .expiresAt(LocalDateTime.now().plusHours(48))
                .build());

        sendNotification(a, "mutual_like", "💘 Match!",
                "Svidjeli ste se međusobno! Pronađite se uživo.", match.getId(), "#700D25");
        sendNotification(b, "mutual_like", "💘 Match!",
                "Svidjeli ste se međusobno! Pronađite se uživo.", match.getId(), "#700D25");

        return match;
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
        notificationRepository.save(Notification.builder()
                .user(userRepository.getReferenceById(userId))
                .type(type)
                .title(title)
                .body(body)
                .matchId(matchId)
                .accentColor(color)
                .build());
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
                .build();
    }
}