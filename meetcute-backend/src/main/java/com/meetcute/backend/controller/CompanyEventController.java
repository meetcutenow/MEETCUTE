package com.meetcute.backend.controller;

import com.meetcute.backend.dto.*;
import com.meetcute.backend.service.CompanyEventService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/company/events")
@RequiredArgsConstructor
public class CompanyEventController {

    private final CompanyEventService companyEventService;

    @PostMapping
    public ResponseEntity<ApiResponse<EventResponse>> createEvent(
            @Valid @RequestBody CreateCompanyEventRequest req,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok("Događaj kreiran!",
                companyEventService.createCompanyEvent(req, userDetails.getUsername())));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<EventResponse>>> getMyEvents(
            @AuthenticationPrincipal UserDetails userDetails) {
        String id = userDetails.getUsername();
        return ResponseEntity.ok(ApiResponse.ok(companyEventService.getCompanyEvents(id, id)));
    }

    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<List<CompanyEventStatsResponse>>> getStats(
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok(
                companyEventService.getEventStats(userDetails.getUsername())));
    }

    @PutMapping("/{eventId}")
    public ResponseEntity<ApiResponse<EventResponse>> updateEvent(
            @PathVariable String eventId,
            @RequestBody UpdateEventRequest req,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok("Događaj ažuriran!",
                companyEventService.updateCompanyEvent(eventId, userDetails.getUsername(), req)));
    }

    @DeleteMapping("/{eventId}")
    public ResponseEntity<ApiResponse<Void>> deleteEvent(
            @PathVariable String eventId,
            @AuthenticationPrincipal UserDetails userDetails) {
        companyEventService.deleteCompanyEvent(eventId, userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok("Događaj obrisan.", null));
    }
}