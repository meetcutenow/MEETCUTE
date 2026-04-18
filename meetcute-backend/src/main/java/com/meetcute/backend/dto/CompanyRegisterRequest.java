package com.meetcute.backend.dto;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CompanyRegisterRequest {

    @NotBlank(message = "Korisničko ime je obavezno")
    @Size(min = 3, max = 50)
    @Pattern(regexp = "^[a-zA-Z0-9_]+$", message = "Samo slova, brojevi i _")
    private String username;

    @NotBlank(message = "Naziv organizacije je obavezan")
    @Size(min = 2, max = 150)
    private String orgName;

    @NotBlank(message = "Email je obavezan")
    @Email(message = "Neispravan email")
    private String email;

    @NotBlank(message = "Lozinka je obavezna")
    @Size(min = 8)
    private String password;
}