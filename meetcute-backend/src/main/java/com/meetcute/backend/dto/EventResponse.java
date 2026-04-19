package com.meetcute.backend.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class EventResponse {
    private String  id;
    private String  creatorId;
    private String  title;
    private String  city;
    private String  specificLocation;
    private String  eventDate;
    private String  timeStart;
    private String  timeEnd;
    private String  description;
    private String  category;
    private String  ageGroup;
    private String  genderGroup;
    private Integer maxAttendees;
    private Integer attendeeCount;
    private Boolean isFull;
    private String  coverPhotoUrl;
    private String  cardColorHex;
    private Boolean isUserEvent;
    private Double  latitude;
    private Double  longitude;
    private Boolean isAttending;
    // Company polja
    private Double  ticketPrice;
    private String  ticketCurrency;
    private String  companyName;
    private String  companyLogoUrl;
    private String  companyEmail;
    private Boolean isCompanyEvent;
}