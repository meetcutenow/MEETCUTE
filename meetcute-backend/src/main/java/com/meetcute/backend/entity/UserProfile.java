package com.meetcute.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_profiles")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class UserProfile {

    @Id
    @Column(name = "user_id", length = 36)
    private String userId;

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "birth_day")
    private Integer birthDay;

    @Column(name = "birth_month")
    private Integer birthMonth;

    @Column(name = "birth_year")
    private Integer birthYear;

    @Column(name = "height_cm")
    private Integer heightCm;

    @Column(name = "gender", length = 20)
    private String gender;

    @Column(name = "hair_color", length = 20)
    private String hairColor;

    @Column(name = "eye_color", length = 20)
    private String eyeColor;

    @Column(name = "seeking_gender", length = 20)
    @Builder.Default
    private String seekingGender = "sve";

    @Column(name = "has_piercing")
    private Boolean hasPiercing;

    @Column(name = "has_tattoo")
    private Boolean hasTattoo;

    @Column(name = "max_distance_pref_m")
    @Builder.Default
    private Integer maxDistancePrefM = 300;

    @Column(name = "pref_age_from")
    private Integer prefAgeFrom;

    @Column(name = "pref_age_to")
    private Integer prefAgeTo;

    @Column(name = "ice_breaker", length = 500)
    private String iceBreaker;

    @Column(name = "is_visible")
    @Builder.Default
    private Boolean isVisible = true;

    @Column(name = "created_at", updatable = false)
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