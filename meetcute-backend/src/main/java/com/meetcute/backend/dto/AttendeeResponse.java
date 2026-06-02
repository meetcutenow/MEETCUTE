package com.meetcute.backend.dto;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AttendeeResponse {
    private String userId;
    private String displayName;
    private String photoUrl;
    private String gender;
    private Integer birthYear;
}