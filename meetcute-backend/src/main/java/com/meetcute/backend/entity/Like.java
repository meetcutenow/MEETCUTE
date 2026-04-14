package com.meetcute.backend.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/entity/Like.java
// ============================================================

@Entity
@Table(name = "likes")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class Like {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "liker_id", nullable = false, length = 36)
    private String likerId;

    @Column(name = "liked_id", nullable = false, length = 36)
    private String likedId;

    @Column(name = "context_type",
            columnDefinition = "ENUM('proximity','event','map')")
    @Builder.Default
    private String contextType = "proximity";

    @Column(name = "context_event_id", length = 36)
    private String contextEventId;

    @Column(name = "liked_at")
    private LocalDateTime likedAt;

    @PrePersist
    protected void onCreate() {
        likedAt = LocalDateTime.now();
    }
}
