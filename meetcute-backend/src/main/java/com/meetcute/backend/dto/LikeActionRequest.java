package com.meetcute.backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class LikeActionRequest {
    @NotBlank
    private String targetUserId;
    private boolean liked;
}
