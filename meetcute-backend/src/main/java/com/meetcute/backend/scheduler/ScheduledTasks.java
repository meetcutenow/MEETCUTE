package com.meetcute.backend.scheduler;

import com.meetcute.backend.entity.*;
import com.meetcute.backend.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class ScheduledTasks {

    private final MatchRepository matchRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final ConversationRepository conversationRepository;

    @Scheduled(fixedDelay = 60_000)
    @Transactional
    public void sendChatConsentRequests() {
        System.out.println(">>> SCHEDULER RUNNING");
        List<Match> matches = matchRepository
                .findByMatchedAtBeforeAndStatus(
                        LocalDateTime.now().minusMinutes(30),
                        "pending_meetup");
        System.out.println(">>> FOUND MATCHES: " + matches.size());
        for (Match match : matches) {
            System.out.println(">>> PROCESSING MATCH: " + match.getId());
            boolean alreadySent = notificationRepository.existsByUserIdAndTypeAndMatchId(
                    match.getUserA().getId(), "chat_consent_request", match.getId());
            System.out.println(">>> ALREADY SENT: " + alreadySent);
            if (alreadySent) continue;

            String msg = "Pronašli ste se! Želite li otvoriti razgovor?";
            String title = "Otvoriti razgovor?";

            sendNotification(match.getUserA().getId(), "chat_consent_request", title, msg, match.getId());
            sendNotification(match.getUserB().getId(), "chat_consent_request", title, msg, match.getId());

            match.setStatus("pending_consent");
            matchRepository.save(match);

            log.info("Chat consent zahtjev poslan za match {}", match.getId());
        }
    }

    @Scheduled(fixedDelay = 3_600_000)
    @Transactional
    public void expireOldMatches() {
        List<Match> expired = matchRepository.findByExpiresAtBeforeAndStatusNotIn(
                LocalDateTime.now(), List.of("chat_unlocked", "expired", "unmatched"));

        expired.forEach(match -> {
            match.setStatus("expired");
            matchRepository.save(match);
            log.info("Match {} označen kao expired", match.getId());
        });

        log.info("Expired {} matcheva", expired.size());
    }

    @Scheduled(cron = "0 0 0 * * *")
    @Transactional
    public void cleanupExpiredTokens() {
        refreshTokenRepository.deleteByExpiresAtBeforeOrIsRevokedTrue(LocalDateTime.now());
        log.info("Stari refresh tokeni obrisani");
    }

    private void sendNotification(String userId, String type, String title, String body, Long matchId) {
        boolean exists = notificationRepository.existsByUserIdAndTypeAndMatchId(userId, type, matchId);
        if (exists) return;

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