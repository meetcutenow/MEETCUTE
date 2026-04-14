package com.meetcute.backend.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class SecretQuestionResponse {
    private Integer id;
    private String questionText;
    private String category;
}

// ── API RESPONSE WRAPPER ──────────────────────────────────────

