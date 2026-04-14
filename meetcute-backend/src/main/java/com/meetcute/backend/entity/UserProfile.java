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

    @Enumerated(EnumType.STRING)
    @Column(name = "gender", columnDefinition = "ENUM('zensko','musko','ostalo')")
    private Gender gender;

    @Enumerated(EnumType.STRING)
    @Column(name = "hair_color", columnDefinition = "ENUM('plava','smeda','crna','crvena','sijeda','ostalo')")
    private HairColor hairColor;

    @Enumerated(EnumType.STRING)
    @Column(name = "eye_color", columnDefinition = "ENUM('smede','zelene','plave','sive')")
    private EyeColor eyeColor;

    @Column(name = "has_piercing")
    private Boolean hasPiercing;

    @Column(name = "has_tattoo")
    private Boolean hasTattoo;

    @Enumerated(EnumType.STRING)
    @Column(name = "seeking_gender", columnDefinition = "ENUM('zensko','musko','oboje')")
    @Builder.Default
    private SeekingGender seekingGender = SeekingGender.oboje;

    @Column(name = "max_distance_pref_m")
    @Builder.Default
    private Integer maxDistancePrefM = 300;

    @Column(name = "ice_breaker", length = 500)
    private String iceBreaker;

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

    public enum Gender { zensko, musko, ostalo }
    public enum HairColor { plava, smeda, crna, crvena, sijeda, ostalo }
    public enum EyeColor { smede, zelene, plave, sive }
    public enum SeekingGender { zensko, musko, oboje }
}
