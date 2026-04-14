package com.meetcute.backend.entity;

import jakarta.persistence.*;
import lombok.*;

// ============================================================
//  Datoteka: SecretQuestion.java
//  Tajna pitanja za matcheve
// ============================================================

@Entity
@Table(name = "secret_questions")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class SecretQuestion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "question_text", nullable = false, length = 300)
    private String questionText;

    @Column(length = 50)
    private String category;

    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;
}
