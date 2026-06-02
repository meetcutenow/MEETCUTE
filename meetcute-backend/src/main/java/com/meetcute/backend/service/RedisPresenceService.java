package com.meetcute.backend.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.geo.Circle;
import org.springframework.data.geo.Distance;
import org.springframework.data.geo.GeoResults;
import org.springframework.data.geo.Point;
import org.springframework.data.redis.connection.RedisGeoCommands;
import org.springframework.data.redis.core.GeoOperations;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class RedisPresenceService {

    private static final String GEO_KEY          = "geo:active";
    private static final String ACTIVE_PREFIX    = "active:";
    private static final String LIKE_PREFIX      = "like:";
    private static final String DISLIKE_PREFIX   = "dislike:";
    private static final Duration ACTIVE_TTL     = Duration.ofMinutes(10);
    private static final Duration REACTION_TTL   = Duration.ofHours(24);

    private final StringRedisTemplate redis;


    public void setActive(String userId, double lat, double lng) {
        redis.opsForValue().set(ACTIVE_PREFIX + userId, "1", ACTIVE_TTL);
        redis.opsForGeo().add(GEO_KEY, new Point(lng, lat), userId);
        log.debug("Korisnik {} aktivan na ({}, {})", userId, lat, lng);
    }

    public void setInactive(String userId) {
        redis.delete(ACTIVE_PREFIX + userId);
        redis.opsForGeo().remove(GEO_KEY, userId);
        log.debug("Korisnik {} neaktivan", userId);
    }

    public boolean isActive(String userId) {
        return Boolean.TRUE.equals(redis.hasKey(ACTIVE_PREFIX + userId));
    }


    public List<String> findNearbyActive(String excludeUserId, double lat, double lng, double radiusMeters) {
        try {
            GeoOperations<String, String> geo = redis.opsForGeo();
            Distance distance = new Distance(radiusMeters / 1000.0,
                    RedisGeoCommands.DistanceUnit.KILOMETERS);
            Circle circle = new Circle(new Point(lng, lat), distance);

            RedisGeoCommands.GeoRadiusCommandArgs args = RedisGeoCommands.GeoRadiusCommandArgs
                    .newGeoRadiusArgs()
                    .includeDistance()
                    .sortAscending()
                    .limit(50);

            GeoResults<RedisGeoCommands.GeoLocation<String>> results =
                    geo.radius(GEO_KEY, circle, args);

            if (results == null) return Collections.emptyList();

            return results.getContent().stream()
                    .map(r -> r.getContent().getName())
                    .filter(uid -> !uid.equals(excludeUserId))
                    .filter(this::isActive)
                    .collect(Collectors.toList());
        } catch (Exception e) {
            log.error("Greška pri geolokacijskoj pretrazi: {}", e.getMessage());
            return Collections.emptyList();
        }
    }


    public void recordLike(String userId, String targetId) {
        redis.opsForValue().set(LIKE_PREFIX + userId + ":" + targetId, "1", REACTION_TTL);
    }

    public void recordDislike(String userId, String targetId) {
        redis.opsForValue().set(DISLIKE_PREFIX + userId + ":" + targetId, "1", REACTION_TTL);
    }

    public boolean hasLiked(String userId, String targetId) {
        return Boolean.TRUE.equals(redis.hasKey(LIKE_PREFIX + userId + ":" + targetId));
    }

    public boolean hasDisliked(String userId, String targetId) {
        return Boolean.TRUE.equals(redis.hasKey(DISLIKE_PREFIX + userId + ":" + targetId));
    }

    public boolean hasReacted(String userId, String targetId) {
        return hasLiked(userId, targetId) || hasDisliked(userId, targetId);
    }

    public boolean isMutualLike(String userA, String userB) {
        return hasLiked(userA, userB) && hasLiked(userB, userA);
    }
}
