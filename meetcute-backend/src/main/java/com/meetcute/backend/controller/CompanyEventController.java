package com.meetcute.backend.controller;

import com.meetcute.backend.dto.ApiResponse;
import com.meetcute.backend.dto.CompanyEventStatsResponse;
import com.meetcute.backend.dto.CreateCompanyEventRequest;
import com.meetcute.backend.dto.EventResponse;
import com.meetcute.backend.dto.UpdateEventRequest;
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
        EventResponse event = companyEventService.createCompanyEvent(req, userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok("Događaj kreiran!", event));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<EventResponse>>> getMyEvents(
            @AuthenticationPrincipal UserDetails userDetails) {
        List<EventResponse> events = companyEventService.getCompanyEvents(userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok(events));
    }

    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<List<CompanyEventStatsResponse>>> getStats(
            @AuthenticationPrincipal UserDetails userDetails) {
        List<CompanyEventStatsResponse> stats = companyEventService.getEventStats(userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok(stats));
    }

    // ── NOVO: Uredi company event ─────────────────────────────────────────────
    @PutMapping("/{eventId}")
    public ResponseEntity<ApiResponse<EventResponse>> updateEvent(
            @PathVariable String eventId,
            @RequestBody UpdateEventRequest req,
            @AuthenticationPrincipal UserDetails userDetails) {
        EventResponse event = companyEventService.updateCompanyEvent(eventId, userDetails.getUsername(), req);
        return ResponseEntity.ok(ApiResponse.ok("Događaj ažuriran!", event));
    }

    // ── NOVO: Obriši company event ────────────────────────────────────────────
    @DeleteMapping("/{eventId}")
    public ResponseEntity<ApiResponse<Void>> deleteEvent(
            @PathVariable String eventId,
            @AuthenticationPrincipal UserDetails userDetails) {
        companyEventService.deleteCompanyEvent(eventId, userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok("Događaj obrisan.", null));
    }
}