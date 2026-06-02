package com.meetcute.backend.dto;

import jakarta.validation.constraints.NotNull;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class UpdateLocationRequest {

    @NotNull
    private Double latitude;
    @NotNull
    private Double longitude;
    private String city;
}