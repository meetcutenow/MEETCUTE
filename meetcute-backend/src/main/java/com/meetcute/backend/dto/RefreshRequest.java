package com.meetcute.backend.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RefreshRequest {
    @NotBlank
    private String refreshToken;
}

// ── USER ──────────────────────────────────────────────────────

