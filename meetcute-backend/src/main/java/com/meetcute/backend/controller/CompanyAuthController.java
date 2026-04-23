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
    public ResponseEntity<ApiResponse<CompanyAuthResponse>> register(
            @Valid @RequestBody CompanyRegisterRequest req) {
        return ResponseEntity.ok(
                ApiResponse.ok("Registracija uspješna!", companyAuthService.register(req)));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<CompanyAuthResponse>> login(
            @Valid @RequestBody CompanyLoginRequest req) {
        return ResponseEntity.ok(
                ApiResponse.ok("Prijava uspješna!", companyAuthService.login(req)));
    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<CompanyAuthResponse>> refresh(
            @Valid @RequestBody RefreshRequest req) {
        return ResponseEntity.ok(
                ApiResponse.ok(companyAuthService.refresh(req.getRefreshToken())));
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(
            @Valid @RequestBody RefreshRequest req) {
        companyAuthService.logout(req.getRefreshToken());
        return ResponseEntity.ok(ApiResponse.ok("Odjava uspješna!", null));
    }

    /**
     * PUT /api/company/auth/profile
     * Ažurira orgName, email i/ili logoUrl.
     */
    @PutMapping("/profile")
    public ResponseEntity<ApiResponse<CompanyResponse>> updateProfile(
            @RequestBody Map<String, String> req,
            @AuthenticationPrincipal UserDetails userDetails) {

        String companyId = userDetails.getUsername();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new RuntimeException("Organizacija nije pronađena."));

        if (req.containsKey("logoUrl") && req.get("logoUrl") != null
                && !req.get("logoUrl").isBlank()) {
            company.setLogoUrl(req.get("logoUrl"));
        }
        if (req.containsKey("orgName") && req.get("orgName") != null
                && !req.get("orgName").isBlank()) {
            company.setOrgName(req.get("orgName").trim());
        }
        if (req.containsKey("email") && req.get("email") != null
                && !req.get("email").isBlank()) {
            String newEmail = req.get("email").trim().toLowerCase();
            if (!newEmail.equals(company.getEmail())
                    && companyRepository.existsByEmail(newEmail)) {
                throw new RuntimeException("Email je već zauzet.");
            }
            company.setEmail(newEmail);
        }

        companyRepository.save(company);

        CompanyResponse response = CompanyResponse.builder()
                .id(company.getId())
                .username(company.getUsername())
                .orgName(company.getOrgName())
                .email(company.getEmail())
                .logoUrl(company.getLogoUrl())
                .build();

        return ResponseEntity.ok(ApiResponse.ok("Profil ažuriran.", response));
    }

    @PutMapping("/password")
    public ResponseEntity<ApiResponse<Void>> changePassword(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody ChangePasswordRequest req) {

        String companyId = userDetails.getUsername();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new RuntimeException("Organizacija nije pronađena."));

        if (!passwordEncoder.matches(req.getOldPassword(), company.getPasswordHash())) {
            throw new RuntimeException("Stara lozinka nije ispravna.");
        }

        if (req.getNewPassword().equals(req.getOldPassword())) {
            throw new RuntimeException("Nova lozinka mora biti različita od stare.");
        }

        company.setPasswordHash(passwordEncoder.encode(req.getNewPassword()));
        companyRepository.save(company);

        return ResponseEntity.ok(ApiResponse.ok("Lozinka uspješno promijenjena.", null));
    }
}