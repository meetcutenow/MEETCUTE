package com.meetcute.backend.service;

import com.meetcute.backend.dto.*;
import com.meetcute.backend.entity.*;
import com.meetcute.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.Year;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

public class UserService {

    private final UserRepository userRepository;
    private final UserProfileRepository profileRepository;
    private final UserPhotoRepository photoRepository;
    private final UserInterestRepository interestRepository;
    private final UserLocationRepository locationRepository;
    private final SecretQuestionRepository questionRepository;

    public UserResponse getMyProfile(String userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Korisnik nije pronađen."));
        return toResponse(user);
    }

    public UserResponse getUserProfile(String targetUserId) {
        User user = userRepository.findById(targetUserId)
                .orElseThrow(() -> new RuntimeException("Korisnik nije pronađen."));
        if (user.getIsBanned() || !user.getIsActive()) {
            throw new RuntimeException("Profil nije dostupan.");
        }
        return toResponse(user);
    }

    @Transactional
    public UserResponse updateProfile(String userId, UpdateProfileRequest req) {
        UserProfile profile = profileRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Profil nije pronađen."));

        if (req.getIceBreaker() != null) profile.setIceBreaker(req.getIceBreaker());
        if (req.getSeekingGender() != null) {
            try {
                profile.setSeekingGender(UserProfile.SeekingGender.valueOf(req.getSeekingGender()));
            } catch (IllegalArgumentException ignored) { }
        }
        if (req.getMaxDistancePrefM() != null) profile.setMaxDistancePrefM(req.getMaxDistancePrefM());
        if (req.getIsVisible() != null) profile.setIsVisible(req.getIsVisible());

        profileRepository.save(profile);
        User user = userRepository.findById(userId).orElseThrow();
        return toResponse(user);
    }

    @Transactional
    public void updateLocation(String userId, UpdateLocationRequest req) {
        User user = userRepository.getReferenceById(userId);
        UserLocation location = locationRepository.findById(userId)
                .orElse(UserLocation.builder().user(user).build());

        location.setLatitude(req.getLatitude());
        location.setLongitude(req.getLongitude());
        location.setCity(req.getCity());
        locationRepository.save(location);
    }

    @Transactional
    public Boolean toggleVisibility(String userId) {
        UserProfile profile = profileRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Profil nije pronađen."));
        profile.setIsVisible(!profile.getIsVisible());
        profileRepository.save(profile);
        return profile.getIsVisible();
    }

    public List<SecretQuestionResponse> getSecretQuestions() {
        return questionRepository.findByIsActiveTrue()
                .stream()
                .map(q -> SecretQuestionResponse.builder()
                        .id(q.getId())
                        .questionText(q.getQuestionText())
                        .category(q.getCategory())
                        .build())
                .collect(Collectors.toList());
    }

    private UserResponse toResponse(User user) {
        List<String> photos = photoRepository
                .findByUserIdOrderByPhotoOrder(user.getId())
                .stream()
                .map(UserPhoto::getPhotoUrl)
                .collect(Collectors.toList());

        List<String> interests = interestRepository
                .findByUserId(user.getId())
                .stream()
                .map(ui -> ui.getInterest().getName())
                .collect(Collectors.toList());

        ProfileResponse profileResp = null;
        if (user.getProfile() != null) {
            UserProfile p = user.getProfile();
            int age = p.getBirthYear() != null
                    ? Year.now().getValue() - p.getBirthYear() : 0;
            profileResp = ProfileResponse.builder()
                    .birthYear(p.getBirthYear())
                    .age(age)
                    .gender(p.getGender() != null ? p.getGender().name() : null)
                    .seekingGender(p.getSeekingGender() != null ? p.getSeekingGender().name() : null)
                    .heightCm(p.getHeightCm())
                    .hairColor(p.getHairColor() != null ? p.getHairColor().name() : null)
                    .eyeColor(p.getEyeColor() != null ? p.getEyeColor().name() : null)
                    .hasPiercing(p.getHasPiercing())
                    .hasTattoo(p.getHasTattoo())
                    .iceBreaker(p.getIceBreaker())
                    .isVisible(p.getIsVisible())
                    .secretQuestion(p.getSecretQuestion() != null
                            ? p.getSecretQuestion().getQuestionText() : null)
                    .build();
        }

        return UserResponse.builder()
                .id(user.getId())
                .username(user.getUsername())
                .displayName(user.getDisplayName())
                .isPremium(user.getIsPremium())
                .profile(profileResp)
                .photoUrls(photos)
                .interests(interests)
                .build();
    }
}


// ── MATCH SERVICE ─────────────────────────────────────────────

