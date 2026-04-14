package com.meetcute.backend.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/entity/ConversationParticipant.java
// ============================================================

@Entity
@Table(name = "conversation_participants")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class ConversationParticipant {

    @EmbeddedId
    private ConversationParticipantId id;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("conversationId")
    @JoinColumn(name = "conversation_id")
    private Conversation conversation;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("userId")
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "joined_at")
    private LocalDateTime joinedAt;

    @Column(name = "last_read_at")
    private LocalDateTime lastReadAt;

    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;

    @PrePersist
    protected void onCreate() {
        joinedAt = LocalDateTime.now();
    }

    @Embeddable
    @Getter @Setter
    @NoArgsConstructor @AllArgsConstructor
    public static class ConversationParticipantId implements java.io.Serializable {

        @Column(name = "conversation_id")
        private String conversationId;

        @Column(name = "user_id")
        private String userId;
    }
}
