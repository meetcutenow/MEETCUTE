package com.meetcute.backend.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/entity/UserProfile.java
// ============================================================

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

    // ProfileStep1 — osobni podaci
    @Column(name = "birth_day")
    private Integer birthDay;

    @Column(name = "birth_month")
    private Integer birthMonth;

    @Column(name = "birth_year")
    private Integer birthYear;

    @Column(name = "height_cm")
    private Integer heightCm;

    @Enumerated(EnumType.STRING)
    @Column(name = "gender", columnDefinition = "ENUM('žensko','muško','ostalo')")
    private Gender gender;

    @Enumerated(EnumType.STRING)
    @Column(name = "hair_color", columnDefinition = "ENUM('plava','smeđa','crna','crvena','sijeda','ostalo')")
    private HairColor hairColor;

    @Enumerated(EnumType.STRING)
    @Column(name = "eye_color", columnDefinition = "ENUM('smeđe','zelene','plave','sive')")
    private EyeColor eyeColor;

    @Column(name = "has_piercing")
    private Boolean hasPiercing;

    @Column(name = "has_tattoo")
    private Boolean hasTattoo;

    // Preferencije
    @Enumerated(EnumType.STRING)
    @Column(name = "seeking_gender", columnDefinition = "ENUM('žensko','muško','oboje')")
    @Builder.Default
    private SeekingGender seekingGender = SeekingGender.oboje;

    @Column(name = "max_distance_pref_m")
    @Builder.Default
    private Integer maxDistancePrefM = 300;

    // ProfileStep3
    @Column(name = "ice_breaker", length = 500)
    private String iceBreaker;

    // Tajno pitanje
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "secret_question_id")
    private SecretQuestion secretQuestion;

    @Column(name = "secret_answer", length = 255)
    private String secretAnswer;

    @Column(name = "is_visible")
    @Builder.Default
    private Boolean isVisible = true;

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

    // Enumi — točno kao u bazi
    public enum Gender { žensko, muško, ostalo }
    public enum HairColor { plava, smeđa, crna, crvena, sijeda, ostalo }
    public enum EyeColor { smeđe, zelene, plave, sive }
    public enum SeekingGender { žensko, muško, oboje }
}
