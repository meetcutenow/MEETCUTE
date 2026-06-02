package com.meetcute.backend.controller;

import com.meetcute.backend.dto.ApiResponse;
import com.meetcute.backend.service.CloudinaryService;
import com.meetcute.backend.entity.*;
import com.meetcute.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/users/me/photos")
@RequiredArgsConstructor
public class UserPhotoController {

    private final CloudinaryService cloudinaryService;
    private final UserPhotoRepository photoRepository;
    private final UserRepository userRepository;

    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, String>>> uploadPhoto(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "isPrimary", defaultValue = "false") boolean isPrimary,
            @AuthenticationPrincipal UserDetails userDetails) {

        String userId = userDetails.getUsername();
        var result = cloudinaryService.upload(file, "meetcute/profiles");
        int order = photoRepository.countByUserId(userId);

        if (isPrimary) photoRepository.resetPrimaryPhoto(userId);

        photoRepository.save(UserPhoto.builder()
                .user(userRepository.getReferenceById(userId))
                .photoUrl(result.url())
                .photoOrder(order)
                .isPrimary(isPrimary || order == 0)
                .build());

        return ResponseEntity.ok(ApiResponse.ok(Map.of("url", result.url(), "publicId", result.publicId())));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<String>>> getPhotos(
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok(
                photoRepository.findByUserIdOrderByPhotoOrder(userDetails.getUsername())
                        .stream()
                        .map(UserPhoto::getPhotoUrl)
                        .collect(Collectors.toList())));
    }

    @DeleteMapping
    public ResponseEntity<ApiResponse<Void>> deleteAllPhotos(
            @AuthenticationPrincipal UserDetails userDetails) {
        photoRepository.deleteAll(
                photoRepository.findByUserIdOrderByPhotoOrder(userDetails.getUsername()));
        return ResponseEntity.ok(ApiResponse.ok("Slike obrisane.", null));
    }
}