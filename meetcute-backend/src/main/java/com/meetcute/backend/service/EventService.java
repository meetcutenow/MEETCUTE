package com.meetcute.backend.service;

import com.meetcute.backend.dto.*;
import com.meetcute.backend.entity.*;
import com.meetcute.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.Year;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

public class EventService {

    private final EventRepository eventRepository;
    private final EventAttendeeRepository attendeeRepository;
    private final UserRepository userRepository;

    public List<EventResponse> getAllEvents(String userId) {
        return eventRepository.findByIsActiveTrueOrderByEventDateAsc()
                .stream()
                .map(e -> toResponse(e, userId))
                .collect(Collectors.toList());
    }

    public List<EventResponse> getEventsByCity(String city, String userId) {
        return eventRepository.findByCityAndIsActiveTrueOrderByEventDateAsc(city)
                .stream()
                .map(e -> toResponse(e, userId))
                .collect(Collectors.toList());
    }

    public EventResponse getEvent(String eventId, String userId) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new RuntimeException("Event nije pronađen."));
        return toResponse(event, userId);
    }

    @Transactional
    public EventResponse createEvent(CreateEventRequest req, String userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Korisnik nije pronađen."));

        if (!user.getIsPremium()) {
            throw new RuntimeException("Kreiranje evenata je dostupno samo Premium korisnicima.");
        }

        Event event = Event.builder()
                .creator(user)
                .title(req.getTitle())
                .description(req.getDescription())
                .city(req.getCity())
                .specificLocation(req.getSpecificLocation())
                .eventDate(LocalDate.parse(req.getEventDate()))
                .timeStart(req.getTimeStart() != null ? LocalTime.parse(req.getTimeStart()) : null)
                .timeEnd(req.getTimeEnd() != null ? LocalTime.parse(req.getTimeEnd()) : null)
                .category(req.getCategory())
                .ageGroup(req.getAgeGroup() != null ? req.getAgeGroup() : "all")
                .genderGroup(req.getGenderGroup() != null ? req.getGenderGroup() : "all")
                .maxAttendees(req.getMaxAttendees())
                .cardColorHex(req.getCardColorHex() != null ? req.getCardColorHex() : "#6DD5E8")
                .latitude(req.getLatitude())
                .longitude(req.getLongitude())
                .isUserEvent(true)
                .build();

        event = eventRepository.save(event);
        return toResponse(event, userId);
    }

    @Transactional
    public EventResponse toggleAttendance(String eventId, String userId) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new RuntimeException("Event nije pronađen."));

        EventAttendee.EventAttendeeId id = new EventAttendee.EventAttendeeId(eventId, userId);
        Optional<EventAttendee> existing = attendeeRepository.findByEventIdAndUserId(eventId, userId);

        if (existing.isPresent()) {
            EventAttendee attendee = existing.get();
            if ("joined".equals(attendee.getStatus())) {
                attendee.setStatus("cancelled");
            } else {
                int count = attendeeRepository.countByEventIdAndStatus(eventId, "joined");
                if (event.getMaxAttendees() != null && count >= event.getMaxAttendees()) {
                    throw new RuntimeException("Event je popunjen.");
                }
                attendee.setStatus("joined");
            }
            attendeeRepository.save(attendee);
        } else {
            int count = attendeeRepository.countByEventIdAndStatus(eventId, "joined");
            if (event.getMaxAttendees() != null && count >= event.getMaxAttendees()) {
                throw new RuntimeException("Event je popunjen.");
            }
            User user = userRepository.getReferenceById(userId);
            EventAttendee attendee = EventAttendee.builder()
                    .id(id)
                    .event(event)
                    .user(user)
                    .status("joined")
                    .build();
            attendeeRepository.save(attendee);
        }

        return toResponse(event, userId);
    }

    private EventResponse toResponse(Event e, String userId) {
        int count = attendeeRepository.countByEventIdAndStatus(e.getId(), "joined");
        boolean attending = userId != null &&
                attendeeRepository.findByEventIdAndUserId(e.getId(), userId)
                        .map(a -> "joined".equals(a.getStatus()))
                        .orElse(false);

        return EventResponse.builder()
                .id(e.getId())
                .title(e.getTitle())
                .city(e.getCity())
                .specificLocation(e.getSpecificLocation())
                .eventDate(e.getEventDate() != null ? e.getEventDate().toString() : null)
                .timeStart(e.getTimeStart() != null ? e.getTimeStart().toString() : null)
                .timeEnd(e.getTimeEnd() != null ? e.getTimeEnd().toString() : null)
                .description(e.getDescription())
                .category(e.getCategory())
                .ageGroup(e.getAgeGroup())
                .genderGroup(e.getGenderGroup())
                .maxAttendees(e.getMaxAttendees())
                .attendeeCount(count)
                .isFull(e.getMaxAttendees() != null && count >= e.getMaxAttendees())
                .coverPhotoUrl(e.getCoverPhotoUrl())
                .cardColorHex(e.getCardColorHex())
                .isUserEvent(e.getIsUserEvent())
                .latitude(e.getLatitude())
                .longitude(e.getLongitude())
                .isAttending(attending)
                .build();
    }
}


// ── USER SERVICE ──────────────────────────────────────────────

