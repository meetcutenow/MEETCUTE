package com.meetcute.backend.scheduler;

import com.meetcute.backend.entity.Match;
import com.meetcute.backend.repository.MatchRepository;
import com.meetcute.backend.repository.RefreshTokenRepository;
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

    @Scheduled(fixedDelay = 3600000)
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
}