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
        String userId = userId(userDetails);
        return ResponseEntity.ok(ApiResponse.ok(
                city != null ? eventService.getEventsByCity(city, userId) : eventService.getAllEvents(userId)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<EventResponse>> getEvent(
            @PathVariable String id,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok(eventService.getEvent(id, userId(userDetails))));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<EventResponse>> createEvent(
            @Valid @RequestBody CreateEventRequest req,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok("Event kreiran!",
                eventService.createEvent(req, userDetails.getUsername())));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<EventResponse>> updateEvent(
            @PathVariable String id,
            @RequestBody UpdateEventRequest req,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok("Event ažuriran!",
                eventService.updateEvent(id, userDetails.getUsername(), req)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteEvent(
            @PathVariable String id,
            @AuthenticationPrincipal UserDetails userDetails) {
        eventService.deleteEvent(id, userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok("Event obrisan.", null));
    }

    @PostMapping("/{id}/attend")
    public ResponseEntity<ApiResponse<EventResponse>> toggleAttendance(
            @PathVariable String id,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok(
                eventService.toggleAttendance(id, userDetails.getUsername())));
    }

    @GetMapping("/{id}/attendees")
    public ResponseEntity<ApiResponse<List<AttendeeResponse>>> getAttendees(
            @PathVariable String id,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok(
                eventService.getEventAttendees(id, userDetails.getUsername())));
    }

    private String userId(UserDetails userDetails) {
        return userDetails != null ? userDetails.getUsername() : null;
    }
}