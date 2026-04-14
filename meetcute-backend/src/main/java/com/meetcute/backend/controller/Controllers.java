package com.meetcute.backend.controller;

import com.meetcute.backend.dto.*;
import com.meetcute.backend.service.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/controller/Controllers.java
//
//  Svi API endpointi:
//
//  AUTH:
//    POST /api/auth/register       — registracija
//    POST /api/auth/login          — login
//    POST /api/auth/refresh        — refresh access tokena
//    POST /api/auth/logout         — odjava
//
//  USER:
//    GET  /api/users/me            — moj profil
//    PUT  /api/users/me            — ažuriraj profil
//    GET  /api/users/{id}          — tuđi profil
//    PUT  /api/users/me/location   — ažuriraj lokaciju
//    POST /api/users/me/visibility — toggle vidljivosti
//    GET  /api/questions           — sva tajna pitanja
//
//  EVENTS:
//    GET  /api/events              — svi eventi
//    GET  /api/events?city=Zagreb  — eventi po gradu
//    GET  /api/events/{id}         — jedan event
//    POST /api/events              — kreiraj event (premium)
//    POST /api/events/{id}/attend  — prijava/otkaz
//
//  MATCHES:
//    POST /api/likes               — lajkaj korisnika
//    GET  /api/matches             — svi matchevi
//    POST /api/matches/{id}/answer — odgovori na pitanje
//    GET  /api/conversations       — svi razgovori
//    GET  /api/conversations/{id}/messages  — poruke
//    POST /api/conversations/{id}/messages  — pošalji poruku
//
//  NOTIFICATIONS:
//    GET  /api/notifications       — sve notifikacije
//    POST /api/notifications/read  — označi sve pročitanim
// ============================================================


// ── AUTH CONTROLLER ───────────────────────────────────────────

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(
            @Valid @RequestBody RegisterRequest req) {
        AuthResponse response = authService.register(req);
        return ResponseEntity.ok(ApiResponse.ok("Registracija uspješna!", response));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(
            @Valid @RequestBody LoginRequest req) {
        AuthResponse response = authService.login(req);
        return ResponseEntity.ok(ApiResponse.ok("Prijava uspješna!", response));
    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<AuthResponse>> refresh(
            @Valid @RequestBody RefreshRequest req) {
        AuthResponse response = authService.refresh(req.getRefreshToken());
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(
            @Valid @RequestBody RefreshRequest req) {
        authService.logout(req.getRefreshToken());
        return ResponseEntity.ok(ApiResponse.ok("Odjava uspješna!", null));
    }
}


// ── USER CONTROLLER ───────────────────────────────────────────

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
class UserController {

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


// ── QUESTIONS CONTROLLER ──────────────────────────────────────

@RestController
@RequestMapping("/api/questions")
@RequiredArgsConstructor
class QuestionController {

    private final UserService userService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<SecretQuestionResponse>>> getQuestions() {
        List<SecretQuestionResponse> questions = userService.getSecretQuestions();
        return ResponseEntity.ok(ApiResponse.ok(questions));
    }
}


// ── EVENT CONTROLLER ──────────────────────────────────────────

@RestController
@RequestMapping("/api/events")
@RequiredArgsConstructor
class EventController {

    private final EventService eventService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<EventResponse>>> getEvents(
            @RequestParam(required = false) String city,
            @AuthenticationPrincipal UserDetails userDetails) {
        String userId = userDetails != null ? userDetails.getUsername() : null;
        List<EventResponse> events = city != null
                ? eventService.getEventsByCity(city, userId)
                : eventService.getAllEvents(userId);
        return ResponseEntity.ok(ApiResponse.ok(events));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<EventResponse>> getEvent(
            @PathVariable String id,
            @AuthenticationPrincipal UserDetails userDetails) {
        String userId = userDetails != null ? userDetails.getUsername() : null;
        EventResponse event = eventService.getEvent(id, userId);
        return ResponseEntity.ok(ApiResponse.ok(event));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<EventResponse>> createEvent(
            @Valid @RequestBody CreateEventRequest req,
            @AuthenticationPrincipal UserDetails userDetails) {
        EventResponse event = eventService.createEvent(req, userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok("Event kreiran!", event));
    }

    @PostMapping("/{id}/attend")
    public ResponseEntity<ApiResponse<EventResponse>> toggleAttendance(
            @PathVariable String id,
            @AuthenticationPrincipal UserDetails userDetails) {
        EventResponse event = eventService.toggleAttendance(id, userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok(event));
    }
}


// ── MATCH CONTROLLER ──────────────────────────────────────────

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
class MatchController {

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


// ── NOTIFICATION CONTROLLER ───────────────────────────────────

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
class NotificationController {

    private final NotificationService notificationService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<NotificationResponse>>> getNotifications(
            @AuthenticationPrincipal UserDetails userDetails) {
        List<NotificationResponse> notifications =
                notificationService.getNotifications(userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok(notifications));
    }

    @PostMapping("/read")
    public ResponseEntity<ApiResponse<Void>> markAllRead(
            @AuthenticationPrincipal UserDetails userDetails) {
        notificationService.markAllRead(userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok("Sve pročitano.", null));
    }
}
