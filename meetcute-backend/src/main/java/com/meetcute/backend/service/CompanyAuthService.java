package com.meetcute.backend.service;

import com.meetcute.backend.dto.*;
import com.meetcute.backend.entity.*;
import com.meetcute.backend.repository.*;
import com.meetcute.backend.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class CompanyAuthService {

    private final CompanyRepository companyRepository;
    private final CompanyRefreshTokenRepository tokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    @Transactional
    public CompanyAuthResponse register(CompanyRegisterRequest req) {
        if (companyRepository.existsByUsername(req.getUsername().trim().toLowerCase()))
            throw new RuntimeException("Korisničko ime već postoji.");
        if (companyRepository.existsByEmail(req.getEmail().trim().toLowerCase()))
            throw new RuntimeException("Email već postoji.");

        return buildAuthResponse(companyRepository.save(Company.builder()
                .username(req.getUsername().trim().toLowerCase())
                .orgName(req.getOrgName().trim())
                .email(req.getEmail().trim().toLowerCase())
                .passwordHash(passwordEncoder.encode(req.getPassword()))
                .logoUrl(req.getLogoUrl())
                .build()));
    }

    @Transactional
    public CompanyAuthResponse login(CompanyLoginRequest req) {
        Company company = companyRepository.findByUsername(req.getUsername().trim().toLowerCase())
                .orElseThrow(() -> new RuntimeException("Pogrešno korisničko ime ili lozinka."));

        if (company.getIsBanned()) throw new RuntimeException("Račun je suspendiran.");
        if (!company.getIsActive()) throw new RuntimeException("Račun nije aktivan.");
        if (!passwordEncoder.matches(req.getPassword(), company.getPasswordHash()))
            throw new RuntimeException("Pogrešno korisničko ime ili lozinka.");

        companyRepository.updateLastSeen(company.getId());
        return buildAuthResponse(company);
    }

    @Transactional
    public CompanyAuthResponse refresh(String refreshToken) {
        if (!jwtUtil.isTokenValid(refreshToken))
            throw new RuntimeException("Neispravan refresh token.");

        CompanyRefreshToken stored = tokenRepository.findByTokenHash(hashToken(refreshToken))
                .orElseThrow(() -> new RuntimeException("Token nije pronađen."));

        if (stored.getIsRevoked() || stored.getExpiresAt().isBefore(LocalDateTime.now()))
            throw new RuntimeException("Token je istekao.");

        Company company = companyRepository.findById(jwtUtil.extractUserId(refreshToken))
                .orElseThrow(() -> new RuntimeException("Tvrtka nije pronađena."));

        stored.setIsRevoked(true);
        tokenRepository.save(stored);
        return buildAuthResponse(company);
    }

    @Transactional
    public void logout(String refreshToken) {
        tokenRepository.findByTokenHash(hashToken(refreshToken)).ifPresent(t -> {
            t.setIsRevoked(true);
            tokenRepository.save(t);
        });
    }

    private CompanyAuthResponse buildAuthResponse(Company company) {
        String accessToken = jwtUtil.generateAccessTokenWithRole(
                company.getId(), company.getUsername(), "company");
        String refreshToken = jwtUtil.generateRefreshToken(company.getId());

        tokenRepository.save(CompanyRefreshToken.builder()
                .company(company)
                .tokenHash(hashToken(refreshToken))
                .expiresAt(LocalDateTime.now().plusDays(30))
                .build());

        return CompanyAuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .company(CompanyResponse.builder()
                        .id(company.getId())
                        .username(company.getUsername())
                        .orgName(company.getOrgName())
                        .email(company.getEmail())
                        .logoUrl(company.getLogoUrl())
                        .build())
                .build();
    }

    private String hashToken(String token) {
        return Integer.toHexString(token.hashCode()) + token.substring(token.length() - 8);
    }
}