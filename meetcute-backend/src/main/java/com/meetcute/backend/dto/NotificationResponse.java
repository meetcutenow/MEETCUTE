package com.meetcute.backend.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

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

// ── SECRET QUESTIONS ──────────────────────────────────────────

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
