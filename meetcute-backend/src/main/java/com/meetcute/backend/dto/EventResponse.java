package com.meetcute.backend.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class EventResponse {
    private String id;
    private String title;
    private String city;
    private String specificLocation;
    private String eventDate;
    private String timeStart;
    private String timeEnd;
    private String description;
    private String category;
    private String ageGroup;
    private String genderGroup;
    private Integer maxAttendees;
    private Integer attendeeCount;
    private Boolean isFull;
    private String coverPhotoUrl;
    private String cardColorHex;
    private Boolean isUserEvent;
    private Double latitude;
    private Double longitude;
    private Boolean isAttending;
}

