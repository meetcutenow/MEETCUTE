package com.meetcute.backend.service;

import com.meetcute.backend.dto.*;
import com.meetcute.backend.entity.*;
import com.meetcute.backend.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class LikeService {

    private final RedisPresenceService presence;
    private final MatchRepository matchRepository;
    private final ConversationRepository conversationRepository;
    private final ConversationParticipantRepository participantRepository;
    private final UserRepository userRepository;
    private final UserPhotoRepository photoRepository;
    private final UserInterestRepository interestRepository;
    private final NotificationRepository notificationRepository;

    @Transactional
    public LikeResponse react(String reactingUserId, LikeActionRequest req) {
        String targetId = req.getTargetUserId();

        if (reactingUserId.equals(targetId))
            throw new RuntimeException("Ne možeš reagirati na vlastiti profil.");

        if (req.isLiked()) {
            return handleLike(reactingUserId, targetId);
        } else {
            return handleDislike(reactingUserId, targetId);
        }
    }

    private LikeResponse handleLike(String userId, String targetId) {
        presence.recordLike(userId, targetId);

        if (presence.hasLiked(targetId, userId)) {
            Match match = createMatch(userId, targetId);

            String myPhoto    = getPrimaryPhoto(userId);
            String otherPhoto = getPrimaryPhoto(targetId);
            String otherName  = userRepository.findById(targetId)
                    .map(User::getDisplayName).orElse("Korisnik");

            MatchResponse matchResp = MatchResponse.builder()
                    .matchId(match.getId())
                    .otherUserId(targetId)
                    .otherUserName(otherName)
                    .otherUserPhoto(otherPhoto)
                    .commonInterests(match.getCommonInterests())
                    .status(match.getStatus())
                    .matchedAt(match.getMatchedAt())
                    .conversationId(null)
                    .build();

            log.info("Match! {} ↔ {}", userId, targetId);

            return LikeResponse.builder()
                    .matched(true)
                    .match(matchResp)
                    .myPhoto(myPhoto)
                    .otherPhoto(otherPhoto)
                    .otherUserName(otherName)
                    .build();
        }

        return LikeResponse.builder().matched(false).build();
    }

    private LikeResponse handleDislike(String userId, String targetId) {
        presence.recordDislike(userId, targetId);
        return LikeResponse.builder().matched(false).build();
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

        sendNotification(a, "mutual_like", "💘 Match!", "Svidjeli ste se međusobno! Pronađite se uživo.", match.getId());
        sendNotification(b, "mutual_like", "💘 Match!", "Svidjeli ste se međusobno! Pronađite se uživo.", match.getId());

        return match;
    }

    private Conversation ensureConversation(Match match) {
        return conversationRepository.findByMatchId(match.getId())
                .orElseGet(() -> {
                    Conversation conv = conversationRepository.save(
                            Conversation.builder().match(match).build());

                    ConversationParticipant partA = new ConversationParticipant();
                    partA.setId(new ConversationParticipant.ConversationParticipantId(
                            conv.getId(), match.getUserA().getId()));
                    partA.setConversation(conv);
                    partA.setUser(match.getUserA());
                    participantRepository.save(partA);

                    ConversationParticipant partB = new ConversationParticipant();
                    partB.setId(new ConversationParticipant.ConversationParticipantId(
                            conv.getId(), match.getUserB().getId()));
                    partB.setConversation(conv);
                    partB.setUser(match.getUserB());
                    participantRepository.save(partB);

                    return conv;
                });
    }

    private int countCommonInterests(String a, String b) {
        List<Integer> aI = interestRepository.findByUserId(a)
                .stream().map(ui -> ui.getId().getInterestId()).collect(Collectors.toList());
        List<Integer> bI = interestRepository.findByUserId(b)
                .stream().map(ui -> ui.getId().getInterestId()).collect(Collectors.toList());
        aI.retainAll(bI);
        return aI.size();
    }

    private String getPrimaryPhoto(String userId) {
        return photoRepository.findByUserIdOrderByPhotoOrder(userId)
                .stream()
                .filter(UserPhoto::getIsPrimary)
                .map(UserPhoto::getPhotoUrl)
                .findFirst()
                .orElse(null);
    }

    private void sendNotification(String userId, String type, String title, String body, Long matchId) {
        notificationRepository.save(Notification.builder()
                .user(userRepository.getReferenceById(userId))
                .type(type)
                .title(title)
                .body(body)
                .matchId(matchId)
                .accentColor("#700D25")
                .build());
    }
}