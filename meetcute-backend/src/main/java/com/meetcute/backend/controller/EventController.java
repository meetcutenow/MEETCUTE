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

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<EventResponse>> updateEvent(
            @PathVariable String id,
            @RequestBody UpdateEventRequest req,
            @AuthenticationPrincipal UserDetails userDetails) {
        EventResponse event = eventService.updateEvent(id, userDetails.getUsername(), req);
        return ResponseEntity.ok(ApiResponse.ok("Event ažuriran!", event));
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
        EventResponse event = eventService.toggleAttendance(id, userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok(event));
    }

    @GetMapping("/{id}/attendees")
    public ResponseEntity<ApiResponse<List<AttendeeResponse>>> getAttendees(
            @PathVariable String id,
            @AuthenticationPrincipal UserDetails userDetails) {
        List<AttendeeResponse> attendees = eventService.getEventAttendees(id, userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok(attendees));
    }

}