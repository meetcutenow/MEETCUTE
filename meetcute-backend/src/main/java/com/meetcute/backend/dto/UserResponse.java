package com.meetcute.backend.dto;

import lombok.*;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UserResponse {
    private String id;
    private String username;
    private String displayName;
    private Boolean isPremium;
    private ProfileResponse profile;
    private List<String> photoUrls;
    private List<String> interests;
}