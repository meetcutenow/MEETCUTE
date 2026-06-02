package com.meetcute.backend.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ConversationResponse {
    private String id;
    private String otherUserId;
    private String otherUserName;
    private String otherUserPhoto;
    private String lastMessage;
    private String lastMessageAt;
    private Long lastMessageId;
    private String lastMessageSenderId;
    private Long matchId;
}