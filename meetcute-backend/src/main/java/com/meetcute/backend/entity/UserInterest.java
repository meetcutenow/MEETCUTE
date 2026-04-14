package com.meetcute.backend.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/entity/UserInterest.java
// ============================================================

@Entity
@Table(name = "user_interests")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class UserInterest {

    @EmbeddedId
    private UserInterestId id;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("userId")
    @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("interestId")
    @JoinColumn(name = "interest_id")
    private Interest interest;

    @Column(name = "added_at")
    private LocalDateTime addedAt;

    @PrePersist
    protected void onCreate() {
        addedAt = LocalDateTime.now();
    }

    @Embeddable
    @Getter @Setter
    @NoArgsConstructor @AllArgsConstructor
    public static class UserInterestId implements java.io.Serializable {

        @Column(name = "user_id")
        private String userId;

        @Column(name = "interest_id")
        private Integer interestId;
    }
}
