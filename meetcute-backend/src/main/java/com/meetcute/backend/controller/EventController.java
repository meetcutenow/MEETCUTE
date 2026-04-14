package com.meetcute.backend.controller;

import com.meetcute.backend.dto.*;
import com.meetcute.backend.service.EventService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/events")
@RequiredArgsConstructor
public class EventController {

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
