package com.meetcute.backend.controller;

import com.meetcute.backend.dto.*;
import com.meetcute.backend.entity.Company;
import com.meetcute.backend.repository.CompanyRepository;
import com.meetcute.backend.service.CompanyAuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/company/auth")
@RequiredArgsConstructor
public class CompanyAuthController {

    private final CompanyAuthService companyAuthService;
    private final CompanyRepository companyRepository;
    private final PasswordEncoder passwordEncoder;

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<CompanyAuthResponse>> register(@Valid @RequestBody CompanyRegisterRequest req) {
        return ResponseEntity.ok(ApiResponse.ok("Registracija uspješna!", companyAuthService.register(req)));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<CompanyAuthResponse>> login(@Valid @RequestBody CompanyLoginRequest req) {
        return ResponseEntity.ok(ApiResponse.ok("Prijava uspješna!", companyAuthService.login(req)));
    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<CompanyAuthResponse>> refresh(@Valid @RequestBody RefreshRequest req) {
        return ResponseEntity.ok(ApiResponse.ok(companyAuthService.refresh(req.getRefreshToken())));
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(@Valid @RequestBody RefreshRequest req) {
        companyAuthService.logout(req.getRefreshToken());
        return ResponseEntity.ok(ApiResponse.ok("Odjava uspješna!", null));
    }

    @PutMapping("/profile")
    public ResponseEntity<ApiResponse<CompanyResponse>> updateProfile(
            @RequestBody Map<String, String> req,
            @AuthenticationPrincipal UserDetails userDetails) {

        Company company = getCompany(userDetails);

        getIfPresent(req, "logoUrl").ifPresent(company::setLogoUrl);
        getIfPresent(req, "orgName").ifPresent(v -> company.setOrgName(v.trim()));
        getIfPresent(req, "email").ifPresent(v -> {
            String newEmail = v.trim().toLowerCase();
            if (!newEmail.equals(company.getEmail()) && companyRepository.existsByEmail(newEmail)) {
                throw new RuntimeException("Email je već zauzet.");
            }
            company.setEmail(newEmail);
        });

        companyRepository.save(company);
        return ResponseEntity.ok(ApiResponse.ok("Profil ažuriran.", toResponse(company)));
    }

    @PutMapping("/password")
    public ResponseEntity<ApiResponse<Void>> changePassword(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody ChangePasswordRequest req) {

        Company company = getCompany(userDetails);

        if (!passwordEncoder.matches(req.getOldPassword(), company.getPasswordHash()))
            throw new RuntimeException("Stara lozinka nije ispravna.");
        if (req.getNewPassword().equals(req.getOldPassword()))
            throw new RuntimeException("Nova lozinka mora biti različita od stare.");

        company.setPasswordHash(passwordEncoder.encode(req.getNewPassword()));
        companyRepository.save(company);
        return ResponseEntity.ok(ApiResponse.ok("Lozinka uspješno promijenjena.", null));
    }

    private Company getCompany(UserDetails userDetails) {
        return companyRepository.findById(userDetails.getUsername())
                .orElseThrow(() -> new RuntimeException("Organizacija nije pronađena."));
    }

    private java.util.Optional<String> getIfPresent(Map<String, String> req, String key) {
        return java.util.Optional.ofNullable(req.get(key)).filter(v -> !v.isBlank());
    }

    private CompanyResponse toResponse(Company company) {
        return CompanyResponse.builder()
                .id(company.getId())
                .username(company.getUsername())
                .orgName(company.getOrgName())
                .email(company.getEmail())
                .logoUrl(company.getLogoUrl())
                .build();
    }
}