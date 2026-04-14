package com.meetcute.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

// ============================================================
//  MeetCute Backend — Glavna klasa
//  Datoteka: src/main/java/com/meetcute/backend/BackendApplication.java
// ============================================================

@SpringBootApplication
@EnableScheduling
public class BackendApplication {
    public static void main(String[] args) {
        SpringApplication.run(BackendApplication.class, args);
    }
}
