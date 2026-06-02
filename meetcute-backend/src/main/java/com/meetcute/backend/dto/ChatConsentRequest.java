package com.meetcute.backend.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class ChatConsentRequest {
    private boolean accepted;
}