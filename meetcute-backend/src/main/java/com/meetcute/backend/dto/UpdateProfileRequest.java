package com.meetcute.backend.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UpdateProfileRequest {
    private String iceBreaker;
    private String seekingGender;
    private Integer maxDistancePrefM;
    private Boolean isVisible;
}

