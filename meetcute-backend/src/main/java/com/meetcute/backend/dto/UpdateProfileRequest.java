package com.meetcute.backend.dto;

import lombok.*;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class UpdateProfileRequest {
    private String iceBreaker;
    private String seekingGender;
    private Integer maxDistancePrefM;
    private Boolean isVisible;
    private Integer prefAgeFrom;
    private Integer prefAgeTo;
    private Integer heightCm;
    private String hairColor;
    private String eyeColor;
    private Boolean hasPiercing;
    private Boolean hasTattoo;
    private String gender;
    private List<Integer> interestIds;
    private Integer birthDay;
    private Integer birthMonth;
    private Integer birthYear;
}