package com.meetcute.backend.service;

import com.meetcute.backend.dto.NotificationResponse;
import com.meetcute.backend.entity.Notification;
import com.meetcute.backend.entity.User;
import com.meetcute.backend.repository.NotificationRepository;
import com.meetcute.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    public List<NotificationResponse> getNotifications(String userId) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public NotificationResponse createNotification(String userId, Map<String, String> req) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Korisnik nije pronađen."));

        String type        = req.getOrDefault("type", "general");
        String title       = req.getOrDefault("title", "Obavijest");
        String body        = req.getOrDefault("body", "");
        String eventId     = req.get("eventId");
        String accentColor = req.getOrDefault("accentColor", "#700D25");

        Notification notification = notificationRepository.save(Notification.builder()
                .user(user)
                .type(type)
                .title(title)
                .body(body)
                .eventId(eventId)
                .accentColor(accentColor)
                .build());

        return toResponse(notification);
    }

    @Transactional
    public void deleteNotification(Long id, String userId) {
        notificationRepository.findById(id).ifPresent(n -> {
            if (n.getUser().getId().equals(userId))
                notificationRepository.delete(n);
        });
    }

    @Transactional
    public void deleteAllNotifications(String userId) {
        notificationRepository.deleteAllByUserId(userId);
    }

    @Transactional
    public void markAllRead(String userId) {
        notificationRepository.markAllReadByUserId(userId);
    }

    private NotificationResponse toResponse(Notification n) {
        return NotificationResponse.builder()
                .id(n.getId())
                .type(n.getType())
                .title(n.getTitle())
                .body(n.getBody())
                .eventId(n.getEventId())
                .matchId(n.getMatchId())
                .nearbyUserId(n.getNearbyUserId())
                .isRead(n.getIsRead())
                .accentColor(n.getAccentColor())
                .createdAt(n.getCreatedAt())
                .build();
    }
}