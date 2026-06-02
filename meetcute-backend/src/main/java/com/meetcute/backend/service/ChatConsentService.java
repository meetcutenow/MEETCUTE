package com.meetcute.backend.service;

import com.meetcute.backend.dto.ChatConsentResponse;
import com.meetcute.backend.entity.*;
import com.meetcute.backend.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class ChatConsentService {

    private final MatchRepository matchRepository;
    private final ConversationRepository conversationRepository;
    private final ConversationParticipantRepository participantRepository;
    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    @Transactional
    public ChatConsentResponse recordConsent(String userId, Long matchId, boolean accepted) {
        Match match = matchRepository.findById(matchId)
                .orElseThrow(() -> new RuntimeException("Match nije pronađen"));

        boolean isUserA = match.getUserA().getId().equals(userId);
        boolean isUserB = match.getUserB().getId().equals(userId);
        if (!isUserA && !isUserB)
            throw new RuntimeException("Nisi dio ovog matcha");

        if (isUserA) {
            match.setChatConsentA(accepted);
        } else {
            match.setChatConsentB(accepted);
        }
        matchRepository.save(match);

        boolean myConsent = accepted;
        boolean otherConsent = isUserA
                ? Boolean.TRUE.equals(match.getChatConsentB())
                : Boolean.TRUE.equals(match.getChatConsentA());

        if (!accepted) {
            match.setStatus("chat_declined");
            matchRepository.save(match);

            String otherId = isUserA ? match.getUserB().getId() : match.getUserA().getId();
            sendNotification(otherId, "chat_declined",
                    "Razgovor nije otključan",
                    "Nažalost, nije došlo do dogovora za otvaranje razgovora.",
                    matchId);

            return ChatConsentResponse.builder()
                    .myConsent(false)
                    .otherConsent(otherConsent)
                    .chatUnlocked(false)
                    .build();
        }

        if (Boolean.TRUE.equals(match.getChatConsentA()) &&
                Boolean.TRUE.equals(match.getChatConsentB())) {

            match.setStatus("chat_unlocked");
            match.setChatUnlockedAt(java.time.LocalDateTime.now());
            matchRepository.save(match);

            Conversation conv = ensureConversation(match);

            sendNotification(match.getUserA().getId(), "chat_unlocked",
                    "💬 Chat je otključan!",
                    "Oboje ste pristali — možete se dopisivati!", matchId);
            sendNotification(match.getUserB().getId(), "chat_unlocked",
                    "💬 Chat je otključan!",
                    "Oboje ste pristali — možete se dopisivati!", matchId);

            log.info("Chat otključan za match {}", matchId);

            return ChatConsentResponse.builder()
                    .myConsent(true)
                    .otherConsent(true)
                    .chatUnlocked(true)
                    .conversationId(conv.getId())
                    .build();
        }

        return ChatConsentResponse.builder()
                .myConsent(true)
                .otherConsent(false)
                .chatUnlocked(false)
                .build();
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

    private void sendNotification(String userId, String type,
                                  String title, String body, Long matchId) {
        notificationRepository.save(Notification.builder()
                .user(userRepository.getReferenceById(userId))
                .type(type).title(title).body(body)
                .matchId(matchId).accentColor("#700D25")
                .build());
    }
}