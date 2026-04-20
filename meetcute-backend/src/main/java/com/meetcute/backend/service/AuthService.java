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
public class AuthService {

    private final UserRepository userRepository;
    private final UserProfileRepository profileRepository;
    private final UserInterestRepository interestRepository;
    private final InterestRepository interestLookup;
    private final SecretQuestionRepository questionRepository;
    private final RefreshTokenRepository tokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    @Transactional
    public AuthResponse register(RegisterRequest req) {

        if (userRepository.existsByUsername(req.getUsername())) {
            throw new RuntimeException("Korisničko ime već postoji.");
        }

        int age = LocalDateTime.now().getYear() - req.getBirthYear();
        if (age < 18) {
            throw new RuntimeException("Moraš imati najmanje 18 godina.");
        }

        if (req.getPrefAgeFrom() != null && req.getPrefAgeTo() != null
                && req.getPrefAgeFrom() > req.getPrefAgeTo()) {
            throw new RuntimeException("Gornja granica dobi mora biti veća od donje.");
        }

        SecretQuestion question = questionRepository.findById(req.getSecretQuestionId())
                .orElseThrow(() -> new RuntimeException("Tajno pitanje nije pronađeno."));

        User user = User.builder()
                .username(req.getUsername().trim().toLowerCase())
                .displayName(req.getDisplayName().trim())
                .passwordHash(passwordEncoder.encode(req.getPassword()))
                .build();

        user = userRepository.save(user);

        // Sve kao String — baza koristi VARCHAR ne ENUM
        String gender     = normalizeGender(req.getGender());
        String hairColor  = normalizeHairColor(req.getHairColor());
        String eyeColor   = normalizeEyeColor(req.getEyeColor());
        String seekingGender = req.getSeekingGender() != null
                ? req.getSeekingGender().trim().toLowerCase()
                : "sve";

        UserProfile profile = UserProfile.builder()
                .user(user)
                .birthDay(req.getBirthDay())
                .birthMonth(req.getBirthMonth())
                .birthYear(req.getBirthYear())
                .heightCm(req.getHeightCm())
                .gender(gender)
                .hairColor(hairColor)
                .eyeColor(eyeColor)
                .hasPiercing(req.getHasPiercing())
                .hasTattoo(req.getHasTattoo())
                .iceBreaker(req.getIceBreaker())
                .secretQuestion(question)
                .secretAnswer(passwordEncoder.encode(
                        req.getSecretAnswer().trim().toLowerCase()))
                .seekingGender(seekingGender)
                .prefAgeFrom(req.getPrefAgeFrom())
                .prefAgeTo(req.getPrefAgeTo())
                .build();

        profileRepository.save(profile);

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

        return buildAuthResponse(user);
    }

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

        userRepository.updateLastSeen(user.getId());

        return buildAuthResponse(user);
    }

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

        stored.setIsRevoked(true);
        tokenRepository.save(stored);

        return buildAuthResponse(user);
    }

    @Transactional
    public void logout(String refreshToken) {
        String tokenHash = hashToken(refreshToken);
        tokenRepository.findByTokenHash(tokenHash).ifPresent(t -> {
            t.setIsRevoked(true);
            tokenRepository.save(t);
        });
    }

    private AuthResponse buildAuthResponse(User user) {
        String accessToken  = jwtUtil.generateAccessToken(user.getId(), user.getUsername());
        String refreshToken = jwtUtil.generateRefreshToken(user.getId());

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
        return Integer.toHexString(token.hashCode()) + token.substring(token.length() - 8);
    }

    // Normalizacija na vrijednosti koje baza čuva (VARCHAR)
    private String normalizeGender(String value) {
        if (value == null) return "ostalo";
        final String v = normalize(value);
        if (v.contains("zen") || v.contains("female")) return "zensko";
        if (v.contains("mus") || v.contains("male"))   return "musko";
        return "ostalo";
    }

    private String normalizeHairColor(String value) {
        if (value == null) return "ostalo";
        final String v = normalize(value);
        if (v.contains("plav"))  return "plava";
        if (v.contains("smed"))  return "smeda";
        if (v.contains("crven")) return "crvena";
        if (v.contains("crn"))   return "crna";
        if (v.contains("sijed")) return "sijeda";
        return "ostalo";
    }

    private String normalizeEyeColor(String value) {
        if (value == null) return "smede";
        final String v = normalize(value);
        if (v.contains("smed"))  return "smede";
        if (v.contains("zelen")) return "zelene";
        if (v.contains("plav"))  return "plave";
        if (v.contains("siv"))   return "sive";
        return "smede";
    }

    private String normalize(String s) {
        return s.toLowerCase()
                .replace("đ", "d").replace("š", "s")
                .replace("č", "c").replace("ć", "c")
                .replace("ž", "z");
    }
}