package com.meetcute.backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "interests")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class Interest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false, unique = true, length = 50)
    private String name;

    @Column(length = 10)
    private String emoji;

    @Column(length = 50)
    private String category;
}