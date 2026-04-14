package com.meetcute.backend.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class MessageResponse {
    private Long id;
    private String senderId;
    private String senderName;
    private String body;
    private String photoUrl;
    private LocalDateTime sentAt;
    private Boolean isMe;
}

