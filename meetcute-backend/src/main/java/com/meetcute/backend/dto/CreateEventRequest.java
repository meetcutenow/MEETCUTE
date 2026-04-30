package com.meetcute.backend.dto;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class CreateEventRequest {

    @NotBlank
    private String title;
    private String description;

    @NotBlank
    private String city;
    private String specificLocation;

    @NotNull
    private String eventDate;
    private String timeStart;
    private String timeEnd;

    @NotBlank
    private String category;
    private String ageGroup;
    private String genderGroup;
    private Integer maxAttendees;
    private String cardColorHex;
    private Double latitude;
    private Double longitude;
}