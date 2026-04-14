package com.meetcute.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UuidGenerator;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Entity
@Table(name = "events")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class Event {

    @Id
    @UuidGenerator
    @Column(length = 36)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "creator_id")
    private User creator;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false, length = 100)
    private String city;

    @Column(name = "specific_location", length = 300)
    private String specificLocation;

    private Double latitude;
    private Double longitude;

    @Column(name = "event_date", nullable = false)
    private LocalDate eventDate;

    @Column(name = "time_start")
    private LocalTime timeStart;

    @Column(name = "time_end")
    private LocalTime timeEnd;

    @Column(nullable = false, length = 50)
    private String category;

    @Column(name = "age_group", length = 20)
    @Builder.Default
    private String ageGroup = "all";

    @Column(name = "gender_group", length = 10)
    @Builder.Default
    private String genderGroup = "all";

    @Column(name = "max_attendees")
    private Integer maxAttendees;

    @Column(name = "cover_photo_url", length = 512)
    private String coverPhotoUrl;

    @Column(name = "card_color_hex", length = 7)
    @Builder.Default
    private String cardColorHex = "#6DD5E8";

    @Column(name = "is_user_event")
    @Builder.Default
    private Boolean isUserEvent = false;

    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}

// ── EventAttendee ───────────────────────────────────────────────

