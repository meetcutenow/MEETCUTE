package com.meetcute.backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class CompanyLoginRequest {

    @NotBlank
    private String username;

    @NotBlank
    private String password;
}