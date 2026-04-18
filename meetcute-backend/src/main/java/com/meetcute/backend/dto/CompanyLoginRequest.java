package com.meetcute.backend.dto;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CompanyLoginRequest {

    @NotBlank
    private String username;

    @NotBlank
    private String password;
}