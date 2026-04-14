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
        var match = matchService.likeUser(userDetails.getUsername(), req);
        if (match.isPresent()) {
            return ResponseEntity.ok(ApiResponse.ok("💘 Match!", match.get()));
        }
        return ResponseEntity.ok(ApiResponse.ok("Lajk zabilježen.", null));
    }

    @GetMapping("/matches")
    public ResponseEntity<ApiResponse<List<MatchResponse>>> getMatches(
            @AuthenticationPrincipal UserDetails userDetails) {
        List<MatchResponse> matches = matchService.getMyMatches(userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok(matches));
    }

    @PostMapping("/matches/{id}/answer")
    public ResponseEntity<ApiResponse<MatchResponse>> checkAnswer(
            @PathVariable Long id,
            @Valid @RequestBody SecretAnswerRequest req,
            @AuthenticationPrincipal UserDetails userDetails) {
        MatchResponse match = matchService.checkSecretAnswer(id, userDetails.getUsername(), req);
        return ResponseEntity.ok(ApiResponse.ok(match));
    }

    @GetMapping("/conversations/{id}/messages")
    public ResponseEntity<ApiResponse<List<MessageResponse>>> getMessages(
            @PathVariable String id,
            @AuthenticationPrincipal UserDetails userDetails) {
        List<MessageResponse> messages = matchService.getMessages(id, userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok(messages));
    }

    @PostMapping("/conversations/{id}/messages")
    public ResponseEntity<ApiResponse<MessageResponse>> sendMessage(
            @PathVariable String id,
            @RequestBody SendMessageRequest req,
            @AuthenticationPrincipal UserDetails userDetails) {
        MessageResponse message = matchService.sendMessage(id, userDetails.getUsername(), req);
        return ResponseEntity.ok(ApiResponse.ok(message));
    }
}
