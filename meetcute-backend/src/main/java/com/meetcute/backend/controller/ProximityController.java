package com.meetcute.backend.controller;

import com.meetcute.backend.dto.*;
import com.meetcute.backend.service.LikeService;
import com.meetcute.backend.service.ProximityMatchService;
import com.meetcute.backend.service.RedisPresenceService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/proximity")
@RequiredArgsConstructor
public class ProximityController {

    private final ProximityMatchService proximityService;
    private final RedisPresenceService presence;
    private final LikeService likeService;

    @PostMapping("/scan")
    public ResponseEntity<ApiResponse<List<NearbyUserResponse>>> scan(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody UpdateLocationRequest req) {
        System.out.println(">>> SCAN called by: " + userDetails.getUsername()
                + " at " + req.getLatitude() + ", " + req.getLongitude());
        List<NearbyUserResponse> candidates = proximityService.findCandidates(
                userDetails.getUsername(), req.getLatitude(), req.getLongitude());
        System.out.println(">>> SCAN found: " + candidates.size() + " candidates");
        return ResponseEntity.ok(ApiResponse.ok(candidates));
    }

    @PostMapping("/active")
    public ResponseEntity<ApiResponse<Map<String, Boolean>>> setActive(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody ActiveStatusRequest req) {
        String userId = userDetails.getUsername();
        if (req.isActive() && req.getLatitude() != null && req.getLongitude() != null) {
            presence.setActive(userId, req.getLatitude(), req.getLongitude());
        } else {
            presence.setInactive(userId);
        }
        return ResponseEntity.ok(ApiResponse.ok(Map.of("active", req.isActive())));
    }

    @GetMapping("/active/status")
    public ResponseEntity<ApiResponse<Map<String, Boolean>>> getActiveStatus(
            @AuthenticationPrincipal UserDetails userDetails) {
        boolean isActive = presence.isActive(userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok(Map.of("active", isActive)));
    }

    @PostMapping("/react")
    public ResponseEntity<ApiResponse<LikeResponse>> react(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody LikeActionRequest req) {
        LikeResponse response = likeService.react(userDetails.getUsername(), req);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }
}
