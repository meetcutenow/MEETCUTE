package com.meetcute.backend.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class SendMessageRequest {
    private String body;
    private String photoUrl;
}