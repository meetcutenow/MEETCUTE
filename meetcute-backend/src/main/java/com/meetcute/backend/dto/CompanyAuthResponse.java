package com.meetcute.backend.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CompanyAuthResponse {
    private String accessToken;
    private String refreshToken;
    private CompanyResponse company;
}