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
        if (age < 16) {
            throw new RuntimeException("Moraš imati najmanje 16 godina.");
        }

        // Validacija pref age raspona
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

        UserProfile.Gender gender = mapGender(req.getGender());
        UserProfile.HairColor hairColor = mapHairColor(req.getHairColor());
        UserProfile.EyeColor eyeColor = mapEyeColor(req.getEyeColor());

        // seekingGender — normaliziramo na 'zensko'/'musko'/'sve'
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

    private UserProfile.Gender mapGender(String value) {
        if (value == null) return UserProfile.Gender.ostalo;
        return switch (value.toLowerCase().replace("ž", "z").replace("š", "s").replace("ć", "c").replace("č", "c")) {
            case "zensko", "žensko", "female" -> UserProfile.Gender.zensko;
            case "musko", "muško", "male"     -> UserProfile.Gender.musko;
            default                            -> UserProfile.Gender.ostalo;
        };
    }

    private UserProfile.HairColor mapHairColor(String value) {
        if (value == null) return UserProfile.HairColor.ostalo;
        return switch (value.toLowerCase()) {
            case "plava"                     -> UserProfile.HairColor.plava;
            case "smeda", "smeđa", "smedja"  -> UserProfile.HairColor.smeda;
            case "crna"                      -> UserProfile.HairColor.crna;
            case "crvena"                    -> UserProfile.HairColor.crvena;
            case "sijeda"                    -> UserProfile.HairColor.sijeda;
            default                          -> UserProfile.HairColor.ostalo;
        };
    }

    private UserProfile.EyeColor mapEyeColor(String value) {
        if (value == null) return UserProfile.EyeColor.smede;
        return switch (value.toLowerCase()) {
            case "smede", "smeđe", "smedje"  -> UserProfile.EyeColor.smede;
            case "zelene"                    -> UserProfile.EyeColor.zelene;
            case "plave"                     -> UserProfile.EyeColor.plave;
            case "sive"                      -> UserProfile.EyeColor.sive;
            default                          -> UserProfile.EyeColor.smede;
        };
    }
}