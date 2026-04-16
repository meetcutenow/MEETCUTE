package com.meetcute.backend.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RegisterRequest {
    @NotBlank(message = "Korisničko ime je obavezno")
    @Size(min = 3, max = 50, message = "Korisničko ime mora biti između 3 i 50 znakova")
    @Pattern(regexp = "^[a-zA-Z0-9_]+$", message = "Korisničko ime smije sadržavati samo slova, brojeve i _")
    private String username;

    @NotBlank(message = "Ime je obavezno")
    @Size(min = 2, max = 100, message = "Ime mora biti između 2 i 100 znakova")
    private String displayName;

    @NotBlank(message = "Lozinka je obavezna")
    @Size(min = 8, message = "Lozinka mora imati najmanje 8 znakova")
    private String password;

    @NotNull(message = "Dan rođenja je obavezan")
    @Min(1) @Max(31)
    private Integer birthDay;

    @NotNull(message = "Mjesec rođenja je obavezan")
    @Min(1) @Max(12)
    private Integer birthMonth;

    @NotNull(message = "Godina rođenja je obavezna")
    @Min(1900) @Max(2100)
    private Integer birthYear;

    @NotNull(message = "Visina je obavezna")
    @Min(50) @Max(250)
    private Integer heightCm;

    @NotBlank(message = "Spol je obavezan")
    private String gender;

    @NotBlank(message = "Boja kose je obavezna")
    private String hairColor;

    @NotBlank(message = "Boja očiju je obavezna")
    private String eyeColor;

    @NotNull(message = "Pirsing je obavezan")
    private Boolean hasPiercing;

    @NotNull(message = "Tetovaža je obavezna")
    private Boolean hasTattoo;

    @NotEmpty(message = "Odaberi najmanje jedan interes")
    private List<Integer> interestIds;

    @NotBlank(message = "Ice breaker je obavezan")
    @Size(max = 500)
    private String iceBreaker;

    @NotNull(message = "Tajno pitanje je obavezno")
    private Integer secretQuestionId;

    @NotBlank(message = "Odgovor na tajno pitanje je obavezan")
    private String secretAnswer;

    // Preference — obavezno
    @NotBlank(message = "Tražim spol je obavezan")
    private String seekingGender;

    @NotNull(message = "Minimalna dob preference je obavezna")
    @Min(16) @Max(99)
    private Integer prefAgeFrom;

    @NotNull(message = "Maksimalna dob preference je obavezna")
    @Min(16) @Max(99)
    private Integer prefAgeTo;
}