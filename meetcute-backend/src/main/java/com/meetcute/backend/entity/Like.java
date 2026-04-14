package com.meetcute.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UuidGenerator;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

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

    @Column(name = "context_type", length = 20)
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

// ── Match ─────────────────────────────────────────────────────────
