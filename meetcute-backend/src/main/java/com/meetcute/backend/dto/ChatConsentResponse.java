package com.meetcute.backend.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ChatConsentResponse {
    private boolean myConsent;
    private boolean otherConsent;
    private boolean chatUnlocked;
    private String conversationId;
}