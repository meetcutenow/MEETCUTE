package com.meetcute.backend.service;

import com.meetcute.backend.dto.NearbyUserResponse;
import com.meetcute.backend.entity.*;
import com.meetcute.backend.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ProximityMatchService {

    private final RedisPresenceService presence;
    private final UserRepository userRepository;
    private final UserInterestRepository interestRepository;
    private final UserPhotoRepository photoRepository;
    private final UserProfileRepository profileRepository;
    private final MatchRepository matchRepository;

    public List<NearbyUserResponse> findCandidates(String userId, double lat, double lng) {
        presence.setActive(userId, lat, lng);

        UserProfile myProfile = profileRepository.findById(userId).orElse(null);
        double myMaxRadius = myProfile != null && myProfile.getMaxDistancePrefM() != null
                ? myProfile.getMaxDistancePrefM() : 300.0;

        List<String> nearbyIds = presence.findNearbyActive(userId, lat, lng, myMaxRadius);
        if (nearbyIds.isEmpty()) return Collections.emptyList();

        List<Integer> myInterestIds = getInterestIds(userId);

        return nearbyIds.stream()
                .filter(candidateId -> !presence.hasDisliked(userId, candidateId))
                .filter(candidateId -> !alreadyMatched(userId, candidateId))
                .filter(candidateId -> isCompatible(userId, myProfile, candidateId))
                .map(candidateId -> buildResponse(candidateId, myInterestIds))
                .filter(Objects::nonNull)
                .sorted(Comparator.comparingInt(NearbyUserResponse::getCommonInterests).reversed())
                .limit(20)
                .collect(Collectors.toList());
    }

    private boolean isCompatible(String myId, UserProfile myProfile, String candidateId) {
        UserProfile candidateProfile = profileRepository.findById(candidateId).orElse(null);

        if (!myPreferencesSatisfied(myProfile, candidateProfile)) return false;

        if (!myPreferencesSatisfied(candidateProfile, myProfile)) return false;

        return true;
    }

    private boolean myPreferencesSatisfied(UserProfile seeker, UserProfile target) {
        if (seeker == null || target == null) return true; // bez profila → ne filtriramo

        String seeking = seeker.getSeekingGender();
        if (seeking != null && !seeking.equalsIgnoreCase("sve") && !seeking.isBlank()) {
            String targetGender = target.getGender();
            if (targetGender == null || !targetGender.equalsIgnoreCase(seeking)) {
                return false;
            }
        }

        Integer targetAge = target.getAge();
        if (targetAge != null) {
            if (seeker.getPrefAgeFrom() != null && targetAge < seeker.getPrefAgeFrom()) return false;
            if (seeker.getPrefAgeTo()   != null && targetAge > seeker.getPrefAgeTo())   return false;
        }

        if (Boolean.FALSE.equals(seeker.getHasTattoo()) &&
                Boolean.TRUE.equals(target.getHasTattoo())) {
            return false;
        }

        if (Boolean.FALSE.equals(seeker.getHasPiercing()) &&
                Boolean.TRUE.equals(target.getHasPiercing())) {
            return false;
        }

        return true;
    }

    private boolean alreadyMatched(String userA, String userB) {
        String a = userA.compareTo(userB) < 0 ? userA : userB;
        String b = userA.compareTo(userB) < 0 ? userB : userA;
        return matchRepository.findByUserAIdAndUserBId(a, b).isPresent();
    }

    private List<Integer> getInterestIds(String userId) {
        return interestRepository.findByUserId(userId)
                .stream()
                .map(ui -> ui.getId().getInterestId())
                .collect(Collectors.toList());
    }

    private NearbyUserResponse buildResponse(String candidateId, List<Integer> myInterestIds) {
        try {
            User user = userRepository.findById(candidateId).orElse(null);
            if (user == null || user.getIsBanned() || !user.getIsActive()) return null;

            UserProfile profile = profileRepository.findById(candidateId).orElse(null);

            List<Integer> theirInterestIds = getInterestIds(candidateId);
            List<Integer> common = new ArrayList<>(myInterestIds);
            common.retainAll(theirInterestIds);

            String primaryPhoto = photoRepository.findByUserIdOrderByPhotoOrder(candidateId)
                    .stream()
                    .filter(UserPhoto::getIsPrimary)
                    .map(UserPhoto::getPhotoUrl)
                    .findFirst()
                    .orElse(null);

            List<String> allPhotos = photoRepository.findByUserIdOrderByPhotoOrder(candidateId)
                    .stream()
                    .map(UserPhoto::getPhotoUrl)
                    .collect(Collectors.toList());

            List<String> interestNames = interestRepository.findByUserId(candidateId)
                    .stream()
                    .map(ui -> ui.getInterest().getName())
                    .collect(Collectors.toList());

            return NearbyUserResponse.builder()
                    .userId(candidateId)
                    .displayName(user.getDisplayName())
                    .primaryPhoto(primaryPhoto)
                    .allPhotos(allPhotos)
                    .iceBreaker(profile != null ? profile.getIceBreaker() : null)
                    .age(profile != null ? profile.getAge() : null)
                    .heightCm(profile != null ? profile.getHeightCm() : null)
                    .gender(profile != null ? profile.getGender() : null)
                    .hairColor(profile != null ? profile.getHairColor() : null)
                    .eyeColor(profile != null ? profile.getEyeColor() : null)
                    .hasTattoo(profile != null ? profile.getHasTattoo() : null)
                    .hasPiercing(profile != null ? profile.getHasPiercing() : null)
                    .interests(interestNames)
                    .commonInterests(common.size())
                    .build();
        } catch (Exception e) {
            log.warn("Greška pri gradnji odgovora za {}: {}", candidateId, e.getMessage());
            return null;
        }
    }
}