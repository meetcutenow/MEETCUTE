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
    private final MatchSecretQuestionRepository matchQuestionRepository;
    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;

    // Svakih 5 minuta — provjeri matcheve starije od 30 min
    @Scheduled(fixedDelay = 300000)
    @Transactional
    public void processMatchUnlocks() {
        LocalDateTime threshold = LocalDateTime.now().minusMinutes(30);

        List<Match> readyToUnlock = matchRepository
                .findByStatusAndMatchedAtBeforeAndUnlockNotifSentAtIsNull(
                        "pending_meetup", threshold);

        for (Match match : readyToUnlock) {
            try {
                match.setStatus("chat_locked");
                match.setUnlockNotifSentAt(LocalDateTime.now());
                matchRepository.save(match);

                saveNotification(match.getUserA().getId(), "chat_locked",
                        "🔓 Chat se otključava!",
                        "Tvoj match mora odgovoriti na tvoje tajno pitanje.",
                        match.getId(), "#700D25");

                saveNotification(match.getUserB().getId(), "secret_question",
                        "🔒 Odgovori na tajno pitanje!",
                        "Odgovori točno da otključaš chat.",
                        match.getId(), "#700D25");

                log.info("Match {} otključan za chat", match.getId());
            } catch (Exception e) {
                log.error("Greška pri otključavanju matcha {}: {}", match.getId(), e.getMessage());
            }
        }
    }

    // Svakih sat vremena — označi matcheve kao expired
    @Scheduled(fixedDelay = 3600000)
    @Transactional
    public void expireOldMatches() {
        LocalDateTime now = LocalDateTime.now();

        List<Match> expired = matchRepository
                .findByExpiresAtBeforeAndStatusNotIn(
                        now, List.of("chat_unlocked", "expired", "unmatched"));

        for (Match match : expired) {
            match.setStatus("expired");
            matchRepository.save(match);
            log.info("Match {} označen kao expired", match.getId());
        }

        log.info("Expired {} matcheva", expired.size());
    }

    // Jednom dnevno u ponoć — očisti stare refresh tokene
    @Scheduled(cron = "0 0 0 * * *")
    @Transactional
    public void cleanupExpiredTokens() {
        refreshTokenRepository.deleteByExpiresAtBeforeOrIsRevokedTrue(LocalDateTime.now());
        log.info("Stari refresh tokeni obrisani");
    }

    private void saveNotification(String userId, String type, String title,
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
}
