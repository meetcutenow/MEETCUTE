package com.meetcute.backend.service;

import com.meetcute.backend.dto.*;
import com.meetcute.backend.entity.*;
import com.meetcute.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Year;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final UserProfileRepository profileRepository;
    private final UserPhotoRepository photoRepository;
    private final UserInterestRepository interestRepository;
    private final UserLocationRepository locationRepository;
    private final InterestRepository interestLookup;

    public UserResponse getMyProfile(String userId) {
        return toResponse(userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Korisnik nije pronađen.")));
    }

    public UserResponse getUserProfile(String targetUserId) {
        User user = userRepository.findById(targetUserId)
                .orElseThrow(() -> new RuntimeException("Korisnik nije pronađen."));
        if (user.getIsBanned() || !user.getIsActive())
            throw new RuntimeException("Profil nije dostupan.");
        return toResponse(user);
    }

    @Transactional
    public UserResponse updateProfile(String userId, UpdateProfileRequest req) {
        UserProfile profile = profileRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Profil nije pronađen."));

        if (req.getSeekingGender() != null)    profile.setSeekingGender(req.getSeekingGender().trim().toLowerCase());
        if (req.getMaxDistancePrefM() != null) profile.setMaxDistancePrefM(req.getMaxDistancePrefM());
        if (req.getIsVisible() != null)        profile.setIsVisible(req.getIsVisible());
        if (req.getPrefAgeFrom() != null)      profile.setPrefAgeFrom(req.getPrefAgeFrom());
        if (req.getPrefAgeTo() != null)        profile.setPrefAgeTo(req.getPrefAgeTo());
        if (req.getIceBreaker() != null)       profile.setIceBreaker(req.getIceBreaker());
        if (req.getHeightCm() != null)         profile.setHeightCm(req.getHeightCm());
        if (req.getHairColor() != null)        profile.setHairColor(req.getHairColor());
        if (req.getEyeColor() != null)         profile.setEyeColor(req.getEyeColor());
        if (req.getHasPiercing() != null)      profile.setHasPiercing(req.getHasPiercing());
        if (req.getHasTattoo() != null)        profile.setHasTattoo(req.getHasTattoo());
        if (req.getGender() != null)           profile.setGender(req.getGender());
        if (req.getBirthDay() != null)         profile.setBirthDay(req.getBirthDay());
        if (req.getBirthMonth() != null)       profile.setBirthMonth(req.getBirthMonth());
        if (req.getBirthYear() != null)        profile.setBirthYear(req.getBirthYear());

        profileRepository.save(profile);

        if (req.getInterestIds() != null && !req.getInterestIds().isEmpty()) {
            interestRepository.deleteByUserId(userId);
            req.getInterestIds().forEach(interestId ->
                    interestLookup.findById(interestId).ifPresent(interest ->
                            interestRepository.save(UserInterest.builder()
                                    .id(new UserInterest.UserInterestId(userId, interestId))
                                    .user(userRepository.getReferenceById(userId))
                                    .interest(interest)
                                    .build())));
        }

        return toResponse(userRepository.findById(userId).orElseThrow());
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

    private UserResponse toResponse(User user) {
        List<String> photos = photoRepository.findByUserIdOrderByPhotoOrder(user.getId())
                .stream().map(UserPhoto::getPhotoUrl).collect(Collectors.toList());

        List<String> interests = interestRepository.findByUserId(user.getId())
                .stream().map(ui -> ui.getInterest().getName()).collect(Collectors.toList());

        ProfileResponse profileResp = null;
        if (user.getProfile() != null) {
            UserProfile p = user.getProfile();
            profileResp = ProfileResponse.builder()
                    .birthDay(p.getBirthDay())
                    .birthMonth(p.getBirthMonth())
                    .birthYear(p.getBirthYear())
                    .age(p.getBirthYear() != null ? Year.now().getValue() - p.getBirthYear() : 0)
                    .gender(p.getGender())
                    .seekingGender(p.getSeekingGender())
                    .heightCm(p.getHeightCm())
                    .hairColor(p.getHairColor())
                    .eyeColor(p.getEyeColor())
                    .hasPiercing(p.getHasPiercing())
                    .hasTattoo(p.getHasTattoo())
                    .iceBreaker(p.getIceBreaker())
                    .isVisible(p.getIsVisible())
                    .prefAgeFrom(p.getPrefAgeFrom())
                    .prefAgeTo(p.getPrefAgeTo())
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