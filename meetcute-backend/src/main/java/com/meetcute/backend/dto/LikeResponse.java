package com.meetcute.backend.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class LikeResponse {
    /** true = mutual like → match stvoren */
    private boolean matched;
    private MatchResponse match;
    /** Primarni foto trenutnog korisnika (za match screen) */
    private String myPhoto;
    /** Primarni foto druge osobe (za match screen) */
    private String otherPhoto;
    private String otherUserName;
}
