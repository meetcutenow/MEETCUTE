package com.meetcute.backend.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class ActiveStatusRequest {
    private boolean active;
    private Double latitude;
    private Double longitude;
}
