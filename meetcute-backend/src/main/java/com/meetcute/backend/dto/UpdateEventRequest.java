package com.meetcute.backend.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UpdateEventRequest {
    private String  title;
    private String  description;
    private String  city;
    private String  specificLocation;
    private String  eventDate;
    private String  timeStart;
    private String  timeEnd;
    private String  category;
    private String  ageGroup;
    private String  genderGroup;
    private Integer maxAttendees;
    private String  cardColorHex;
    private Double  latitude;
    private Double  longitude;
    private Double  ticketPrice;
    private String  ticketCurrency;
    private String coverPhotoUrl;
}