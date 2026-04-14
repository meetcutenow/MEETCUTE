package com.meetcute.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UuidGenerator;

import java.time.LocalDateTime;

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/entity/MatchSecretQuestion.java
// ============================================================

@Entity
@Table(name = "match_secret_questions")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class MatchSecretQuestion {

    @Id
    @Column(name = "match_id")
    private Long matchId;

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "match_id")
    private Match match;

    @Column(name = "question_text", nullable = false, length = 300)
    private String questionText;

    @Column(name = "answer_hash", nullable = false)
    private String answerHash;

    @Column(name = "attempts_left")
    @Builder.Default
    private Integer attemptsLeft = 3;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
