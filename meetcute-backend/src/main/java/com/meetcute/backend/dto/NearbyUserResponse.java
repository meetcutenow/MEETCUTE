package com.meetcute.backend.dto;

import lombok.*;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class NearbyUserResponse {
    private String userId;
    private String displayName;
    private String primaryPhoto;
    private List<String> allPhotos;
    private String iceBreaker;
    private Integer age;
    private Integer heightCm;
    private String gender;
    private String hairColor;
    private String eyeColor;
    private Boolean hasTattoo;
    private Boolean hasPiercing;
    private List<String> interests;
    private int commonInterests;
}
