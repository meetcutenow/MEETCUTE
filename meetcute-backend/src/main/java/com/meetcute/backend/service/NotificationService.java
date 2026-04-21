package com.meetcute.backend.service;

import com.meetcute.backend.dto.NotificationResponse;
import com.meetcute.backend.entity.Notification;
import com.meetcute.backend.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;

    public List<NotificationResponse> getNotifications(String userId) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }
    @Transactional
    public void deleteNotification(Long id, String userId) {
        notificationRepository.findById(id).ifPresent(n -> {
            if (n.getUser().getId().equals(userId)) {
                notificationRepository.delete(n);
            }
        });
    }

    @Transactional
    public void markAllRead(String userId) {
        notificationRepository.markAllReadByUserId(userId);
    }

    public int getUnreadCount(String userId) {
        return notificationRepository.countByUserIdAndIsReadFalse(userId);
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
