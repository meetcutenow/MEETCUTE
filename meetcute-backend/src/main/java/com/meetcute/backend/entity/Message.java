package com.meetcute.backend.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/entity/Message.java
// ============================================================

@Entity
@Table(name = "messages")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class Message {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "conversation_id", nullable = false)
    private Conversation conversation;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sender_id", nullable = false)
    private User sender;

    @Column(columnDefinition = "TEXT")
    private String body;

    @Column(name = "photo_url", length = 512)
    private String photoUrl;

    @Column(name = "sent_at")
    private LocalDateTime sentAt;

    @Column(name = "is_deleted")
    @Builder.Default
    private Boolean isDeleted = false;

    @PrePersist
    protected void onCreate() {
        sentAt = LocalDateTime.now();
    }
}
