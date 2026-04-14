package com.meetcute.backend.controller;

import com.meetcute.backend.dto.*;
import com.meetcute.backend.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserResponse>> getMyProfile(
            @AuthenticationPrincipal UserDetails userDetails) {
        UserResponse response = userService.getMyProfile(userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PutMapping("/me")
    public ResponseEntity<ApiResponse<UserResponse>> updateProfile(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody UpdateProfileRequest req) {
        UserResponse response = userService.updateProfile(userDetails.getUsername(), req);
        return ResponseEntity.ok(ApiResponse.ok("Profil ažuriran.", response));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<UserResponse>> getUserProfile(@PathVariable String id) {
        UserResponse response = userService.getUserProfile(id);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PutMapping("/me/location")
    public ResponseEntity<ApiResponse<Void>> updateLocation(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody UpdateLocationRequest req) {
        userService.updateLocation(userDetails.getUsername(), req);
        return ResponseEntity.ok(ApiResponse.ok("Lokacija ažurirana.", null));
    }

    @PostMapping("/me/visibility")
    public ResponseEntity<ApiResponse<Map<String, Boolean>>> toggleVisibility(
            @AuthenticationPrincipal UserDetails userDetails) {
        boolean visible = userService.toggleVisibility(userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok(Map.of("isVisible", visible)));
    }
}
