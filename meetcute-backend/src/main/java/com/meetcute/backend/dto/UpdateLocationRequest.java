package com.meetcute.backend.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UpdateLocationRequest {
    @NotNull
    private Double latitude;
    @NotNull
    private Double longitude;
    private String city;
}

// ── EVENTS ────────────────────────────────────────────────────

