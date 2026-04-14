package com.meetcute.backend.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/entity/EventAttendee.java
// ============================================================

@Entity
@Table(name = "event_attendees")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class EventAttendee {

    @EmbeddedId
    private EventAttendeeId id;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("eventId")
    @JoinColumn(name = "event_id")
    private Event event;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("userId")
    @JoinColumn(name = "user_id")
    private User user;

    @Column(length = 20)
    @Builder.Default
    private String status = "joined";

    @Column(name = "joined_at")
    private LocalDateTime joinedAt;

    @PrePersist
    protected void onCreate() {
        joinedAt = LocalDateTime.now();
    }

    @Embeddable
    @Getter @Setter
    @NoArgsConstructor @AllArgsConstructor
    public static class EventAttendeeId implements java.io.Serializable {

        @Column(name = "event_id")
        private String eventId;

        @Column(name = "user_id")
        private String userId;
    }
}
