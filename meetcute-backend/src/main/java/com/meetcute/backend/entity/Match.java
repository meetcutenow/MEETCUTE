package com.meetcute.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "matches")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class Match {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_a_id", nullable = false)
    private User userA;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_b_id", nullable = false)
    private User userB;

    @Column(name = "common_interests")
    @Builder.Default
    private Integer commonInterests = 0;

    @Column(name = "distance_m")
    private Integer distanceM;

    @Column(length = 30)
    @Builder.Default
    private String status = "pending_meetup";

    @Column(name = "matched_at", updatable = false)
    private LocalDateTime matchedAt;

    @Column(name = "chat_unlocked_at")
    private LocalDateTime chatUnlockedAt;

    @Column(name = "expires_at")
    private LocalDateTime expiresAt;

    @PrePersist
    protected void onCreate() {
        matchedAt = LocalDateTime.now();
    }
}