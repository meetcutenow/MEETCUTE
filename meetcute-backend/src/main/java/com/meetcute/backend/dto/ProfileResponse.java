package com.meetcute.backend.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ProfileResponse {
    private Integer birthYear;
    private Integer age;
    private String gender;
    private String seekingGender;
    private Integer heightCm;
    private String hairColor;
    private String eyeColor;
    private Boolean hasPiercing;
    private Boolean hasTattoo;
    private String iceBreaker;
    private Boolean isVisible;
    private String secretQuestion;
    private Integer prefAgeFrom;
    private Integer prefAgeTo;
}