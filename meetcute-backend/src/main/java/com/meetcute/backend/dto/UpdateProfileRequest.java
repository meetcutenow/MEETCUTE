package com.meetcute.backend.dto;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UpdateProfileRequest {
    private String iceBreaker;
    private String seekingGender;
    private Integer maxDistancePrefM;
    private Boolean isVisible;
    private Integer prefAgeFrom;
    private Integer prefAgeTo;
}