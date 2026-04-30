package com.meetcute.backend.dto;

import lombok.*;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class NotificationResponse {
    private Long id;
    private String type;
    private String title;
    private String body;
    private String eventId;
    private Long matchId;
    private String nearbyUserId;
    private Boolean isRead;
    private String accentColor;
    private LocalDateTime createdAt;
}