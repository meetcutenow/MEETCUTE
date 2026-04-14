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
import java.util.List;

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/service/AuthService.java
// ============================================================

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final UserProfileRepository profileRepository;
    private final UserInterestRepository interestRepository;
    private final InterestRepository interestLookup;
    private final SecretQuestionRepository questionRepository;
    private final RefreshTokenRepository tokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    // ── REGISTRACIJA ──────────────────────────────────────────

    @Transactional
    public AuthResponse register(RegisterRequest req) {

        // Provjeri username
        if (userRepository.existsByUsername(req.getUsername())) {
            throw new RuntimeException("Korisničko ime već postoji.");
        }

        // Provjeri dob (min 16 god)
        int age = LocalDateTime.now().getYear() - req.getBirthYear();
        if (age < 16) {
            throw new RuntimeException("Moraš imati najmanje 16 godina.");
        }

        // Provjeri broj fotografija — fotografije se uploadaju zasebno
        // pa ovdje samo kreiramo korisnika bez slika

        // Pronađi tajno pitanje
        SecretQuestion question = questionRepository.findById(req.getSecretQuestionId())
                .orElseThrow(() -> new RuntimeException("Tajno pitanje nije pronađeno."));

        // Kreiraj korisnika
        User user = User.builder()
                .username(req.getUsername().trim().toLowerCase())
                .displayName(req.getDisplayName().trim())
                .passwordHash(passwordEncoder.encode(req.getPassword()))
                .build();

        user = userRepository.save(user);

        // Kreiraj profil
        UserProfile profile = UserProfile.builder()
                .user(user)
                .birthDay(req.getBirthDay())
                .birthMonth(req.getBirthMonth())
                .birthYear(req.getBirthYear())
                .heightCm(req.getHeightCm())
                .gender(UserProfile.Gender.valueOf(req.getGender()))
                .hairColor(UserProfile.HairColor.valueOf(req.getHairColor()))
                .eyeColor(UserProfile.EyeColor.valueOf(req.getEyeColor()))
                .hasPiercing(req.getHasPiercing())
                .hasTattoo(req.getHasTattoo())
                .iceBreaker(req.getIceBreaker())
                .secretQuestion(question)
                .secretAnswer(passwordEncoder.encode(
                        req.getSecretAnswer().trim().toLowerCase()))
                .build();

        profileRepository.save(profile);

        // Spremi interese
        String finalUserId = user.getId();
        req.getInterestIds().forEach(interestId -> {
            interestLookup.findById(interestId).ifPresent(interest -> {
                UserInterest ui = UserInterest.builder()
                        .id(new UserInterest.UserInterestId(finalUserId, interestId))
                        .user(userRepository.getReferenceById(finalUserId))
                        .interest(interest)
                        .build();
                interestRepository.save(ui);
            });
        });

        // Generiraj tokene
        return buildAuthResponse(user);
    }

    // ── LOGIN ─────────────────────────────────────────────────

    @Transactional
    public AuthResponse login(LoginRequest req) {
        User user = userRepository.findByUsername(req.getUsername().trim().toLowerCase())
                .orElseThrow(() -> new RuntimeException("Pogrešno korisničko ime ili lozinka."));

        if (user.getIsBanned()) {
            throw new RuntimeException("Račun je suspendiran.");
        }

        if (!user.getIsActive()) {
            throw new RuntimeException("Račun nije aktivan.");
        }

        if (!passwordEncoder.matches(req.getPassword(), user.getPasswordHash())) {
            throw new RuntimeException("Pogrešno korisničko ime ili lozinka.");
        }

        // Ažuriraj last_seen_at
        userRepository.updateLastSeen(user.getId());

        return buildAuthResponse(user);
    }

    // ── REFRESH TOKEN ─────────────────────────────────────────

    @Transactional
    public AuthResponse refresh(String refreshToken) {
        if (!jwtUtil.isTokenValid(refreshToken)) {
            throw new RuntimeException("Neispravan refresh token.");
        }

        String userId = jwtUtil.extractUserId(refreshToken);
        String tokenHash = hashToken(refreshToken);

        RefreshToken stored = tokenRepository.findByTokenHash(tokenHash)
                .orElseThrow(() -> new RuntimeException("Refresh token nije pronađen."));

        if (stored.getIsRevoked() || stored.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new RuntimeException("Refresh token je istekao.");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Korisnik nije pronađen."));

        // Opozovi stari token
        stored.setIsRevoked(true);
        tokenRepository.save(stored);

        return buildAuthResponse(user);
    }

    // ── LOGOUT ───────────────────────────────────────────────

    @Transactional
    public void logout(String refreshToken) {
        String tokenHash = hashToken(refreshToken);
        tokenRepository.findByTokenHash(tokenHash).ifPresent(t -> {
            t.setIsRevoked(true);
            tokenRepository.save(t);
        });
    }

    // ── HELPER ───────────────────────────────────────────────

    private AuthResponse buildAuthResponse(User user) {
        String accessToken  = jwtUtil.generateAccessToken(user.getId(), user.getUsername());
        String refreshToken = jwtUtil.generateRefreshToken(user.getId());

        // Spremi refresh token u bazu
        RefreshToken tokenEntity = RefreshToken.builder()
                .user(user)
                .tokenHash(hashToken(refreshToken))
                .expiresAt(LocalDateTime.now().plusDays(30))
                .build();
        tokenRepository.save(tokenEntity);

        UserResponse userResponse = UserResponse.builder()
                .id(user.getId())
                .username(user.getUsername())
                .displayName(user.getDisplayName())
                .isPremium(user.getIsPremium())
                .build();

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .user(userResponse)
                .build();
    }

    private String hashToken(String token) {
        // Jednostavan hash za storage (ne bcrypt — preskup za tokene)
        return Integer.toHexString(token.hashCode()) + token.substring(token.length() - 8);
    }
}
