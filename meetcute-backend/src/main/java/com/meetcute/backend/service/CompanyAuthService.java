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
        if (companyRepository.existsByUsername(req.getUsername().trim().toLowerCase())) {
            throw new RuntimeException("Korisničko ime već postoji.");
        }
        if (companyRepository.existsByEmail(req.getEmail().trim().toLowerCase())) {
            throw new RuntimeException("Email već postoji.");
        }

        Company company = Company.builder()
                .username(req.getUsername().trim().toLowerCase())
                .orgName(req.getOrgName().trim())
                .email(req.getEmail().trim().toLowerCase())
                .passwordHash(passwordEncoder.encode(req.getPassword()))
                .logoUrl(req.getLogoUrl())
                .build();

        company = companyRepository.save(company);
        return buildAuthResponse(company);
    }

    @Transactional
    public CompanyAuthResponse login(CompanyLoginRequest req) {
        Company company = companyRepository
                .findByUsername(req.getUsername().trim().toLowerCase())
                .orElseThrow(() -> new RuntimeException("Pogrešno korisničko ime ili lozinka."));

        if (company.getIsBanned()) {
            throw new RuntimeException("Račun je suspendiran.");
        }
        if (!company.getIsActive()) {
            throw new RuntimeException("Račun nije aktivan.");
        }
        if (!passwordEncoder.matches(req.getPassword(), company.getPasswordHash())) {
            throw new RuntimeException("Pogrešno korisničko ime ili lozinka.");
        }

        companyRepository.updateLastSeen(company.getId());
        return buildAuthResponse(company);
    }

    @Transactional
    public CompanyAuthResponse refresh(String refreshToken) {
        if (!jwtUtil.isTokenValid(refreshToken)) {
            throw new RuntimeException("Neispravan refresh token.");
        }

        String tokenHash = hashToken(refreshToken);
        CompanyRefreshToken stored = tokenRepository.findByTokenHash(tokenHash)
                .orElseThrow(() -> new RuntimeException("Token nije pronađen."));

        if (stored.getIsRevoked() || stored.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new RuntimeException("Token je istekao.");
        }

        String companyId = jwtUtil.extractUserId(refreshToken);
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new RuntimeException("Tvrtka nije pronađena."));

        stored.setIsRevoked(true);
        tokenRepository.save(stored);
        return buildAuthResponse(company);
    }

    @Transactional
    public void logout(String refreshToken) {
        String tokenHash = hashToken(refreshToken);
        tokenRepository.findByTokenHash(tokenHash).ifPresent(t -> {
            t.setIsRevoked(true);
            tokenRepository.save(t);
        });
    }

    private CompanyAuthResponse buildAuthResponse(Company company) {
        String accessToken  = jwtUtil.generateAccessTokenWithRole(
                company.getId(), company.getUsername(), "company");
        String refreshToken = jwtUtil.generateRefreshToken(company.getId());

        CompanyRefreshToken tokenEntity = CompanyRefreshToken.builder()
                .company(company)
                .tokenHash(hashToken(refreshToken))
                .expiresAt(LocalDateTime.now().plusDays(30))
                .build();
        tokenRepository.save(tokenEntity);

        CompanyResponse companyResponse = CompanyResponse.builder()
                .id(company.getId())
                .username(company.getUsername())
                .orgName(company.getOrgName())
                .email(company.getEmail())
                .logoUrl(company.getLogoUrl())
                .build();

        return CompanyAuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .company(companyResponse)
                .build();
    }

    private String hashToken(String token) {
        return Integer.toHexString(token.hashCode()) + token.substring(token.length() - 8);
    }
}