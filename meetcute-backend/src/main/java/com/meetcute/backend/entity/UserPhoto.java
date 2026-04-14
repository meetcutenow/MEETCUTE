package com.meetcute.backend.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/entity/UserPhoto.java
// ============================================================

@Entity
@Table(name = "user_photos")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class UserPhoto {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "photo_url", nullable = false, length = 512)
    private String photoUrl;

    @Column(name = "cloudinary_public_id", length = 200)
    private String cloudinaryPublicId;

    @Column(name = "photo_order")
    private Integer photoOrder;

    @Column(name = "is_primary")
    @Builder.Default
    private Boolean isPrimary = false;

    @Column(name = "uploaded_at")
    private LocalDateTime uploadedAt;

    @PrePersist
    protected void onCreate() {
        uploadedAt = LocalDateTime.now();
    }
}
