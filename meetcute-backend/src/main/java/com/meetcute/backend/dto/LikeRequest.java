package com.meetcute.backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class LikeRequest {

    @NotBlank
    private String likedUserId;
    private String contextType;
    private String contextEventId;
}