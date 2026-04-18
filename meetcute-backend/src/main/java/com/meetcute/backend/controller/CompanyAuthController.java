package com.meetcute.backend.controller;

import com.meetcute.backend.dto.*;
import com.meetcute.backend.service.CompanyAuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/company/auth")
@RequiredArgsConstructor
public class CompanyAuthController {

    private final CompanyAuthService companyAuthService;

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
}