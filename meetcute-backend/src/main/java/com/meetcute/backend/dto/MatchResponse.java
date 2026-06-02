package com.meetcute.backend.dto;

import lombok.*;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class MatchResponse {
    private Long matchId;
    private String otherUserId;
    private String otherUserName;
    private String otherUserPhoto;
    private Integer commonInterests;
    private Integer distanceM;
    private String status;
    private LocalDateTime matchedAt;
    private String conversationId;
}