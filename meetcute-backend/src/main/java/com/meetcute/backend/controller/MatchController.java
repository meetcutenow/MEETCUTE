package com.meetcute.backend.controller;

import com.meetcute.backend.dto.*;
import com.meetcute.backend.service.MatchService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class MatchController {

    private final MatchService matchService;

    @PostMapping("/likes")
    public ResponseEntity<ApiResponse<MatchResponse>> likeUser(
            @Valid @RequestBody LikeRequest req,
            @AuthenticationPrincipal UserDetails userDetails) {
        return matchService.likeUser(userDetails.getUsername(), req)
                .map(match -> ResponseEntity.ok(ApiResponse.ok("💘 Match!", match)))
                .orElseGet(() -> ResponseEntity.ok(ApiResponse.ok("Lajk zabilježen.", null)));
    }

    @GetMapping("/matches")
    public ResponseEntity<ApiResponse<List<MatchResponse>>> getMatches(
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok(matchService.getMyMatches(userDetails.getUsername())));
    }

    @GetMapping("/conversations/{id}/messages")
    public ResponseEntity<ApiResponse<List<MessageResponse>>> getMessages(
            @PathVariable String id,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok(matchService.getMessages(id, userDetails.getUsername())));
    }

    @PostMapping("/conversations/{id}/messages")
    public ResponseEntity<ApiResponse<MessageResponse>> sendMessage(
            @PathVariable String id,
            @RequestBody SendMessageRequest req,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok(matchService.sendMessage(id, userDetails.getUsername(), req)));
    }
}