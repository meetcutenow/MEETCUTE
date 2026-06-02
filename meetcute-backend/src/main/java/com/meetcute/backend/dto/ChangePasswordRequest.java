package com.meetcute.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class ChangePasswordRequest {

    @NotBlank(message = "Stara lozinka je obavezna")
    private String oldPassword;

    @NotBlank(message = "Nova lozinka je obavezna")
    @Size(min = 8, message = "Nova lozinka mora imati najmanje 8 znakova")
    private String newPassword;
}