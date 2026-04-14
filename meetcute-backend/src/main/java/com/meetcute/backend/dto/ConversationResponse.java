package com.meetcute.backend.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ConversationResponse {
    private String id;
    private Long matchId;
    private String otherUserId;
    private String otherUserName;
    private String otherUserPhoto;
    private String lastMessageText;
    private LocalDateTime lastMessageAt;
    private Integer unreadCount;
}

// ── NOTIFICATIONS ─────────────────────────────────────────────

