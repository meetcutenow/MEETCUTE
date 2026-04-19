package com.meetcute.backend.service;

import com.meetcute.backend.dto.*;
import com.meetcute.backend.entity.*;
import com.meetcute.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class EventService {

    private final EventRepository eventRepository;
    private final EventAttendeeRepository attendeeRepository;
    private final UserRepository userRepository;
    private final JdbcTemplate jdbcTemplate;
    private final UserPhotoRepository photoRepository;


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
                .isCompanyEvent(false)
                .build();

        event = eventRepository.save(event);
        return toResponse(event, userId);
    }

    @Transactional
    public EventResponse updateEvent(String eventId, String userId, UpdateEventRequest req) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new RuntimeException("Event nije pronađen."));

        if (event.getCreator() == null || !event.getCreator().getId().equals(userId)) {
            throw new RuntimeException("Nemaš pravo uređivati ovaj event.");
        }

        if (req.getTitle() != null)            event.setTitle(req.getTitle());
        if (req.getDescription() != null)      event.setDescription(req.getDescription());
        if (req.getCity() != null)             event.setCity(req.getCity());
        if (req.getSpecificLocation() != null) event.setSpecificLocation(req.getSpecificLocation());
        if (req.getEventDate() != null)        event.setEventDate(LocalDate.parse(req.getEventDate()));
        if (req.getTimeStart() != null)        event.setTimeStart(LocalTime.parse(req.getTimeStart()));
        if (req.getTimeEnd() != null)          event.setTimeEnd(LocalTime.parse(req.getTimeEnd()));
        if (req.getCategory() != null)         event.setCategory(req.getCategory());
        if (req.getAgeGroup() != null)         event.setAgeGroup(req.getAgeGroup());
        if (req.getGenderGroup() != null)      event.setGenderGroup(req.getGenderGroup());
        if (req.getMaxAttendees() != null)     event.setMaxAttendees(req.getMaxAttendees());
        if (req.getCardColorHex() != null)     event.setCardColorHex(req.getCardColorHex());
        if (req.getLatitude() != null)         event.setLatitude(req.getLatitude());
        if (req.getLongitude() != null)        event.setLongitude(req.getLongitude());

        eventRepository.save(event);
        return toResponse(event, userId);
    }

    @Transactional
    public void deleteEvent(String eventId, String userId) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new RuntimeException("Event nije pronađen."));

        if (event.getCreator() == null || !event.getCreator().getId().equals(userId)) {
            throw new RuntimeException("Nemaš pravo brisati ovaj event.");
        }

        event.setIsActive(false);
        eventRepository.save(event);
    }

    @Transactional
    public EventResponse toggleAttendance(String eventId, String userId) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new RuntimeException("Event nije pronađen."));

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
                    .id(new EventAttendee.EventAttendeeId(eventId, userId))
                    .event(event)
                    .user(user)
                    .status("joined")
                    .build();
            attendeeRepository.save(attendee);
        }

        return toResponse(event, userId);
    }

    public List<AttendeeResponse> getEventAttendees(String eventId, String requestingUserId) {
        // Provjera - samo kreator eventa ili company vlasnik može vidjeti listu
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new RuntimeException("Event nije pronađen."));

        // Ako je company event, provjeri je li tražitelj company vlasnik
        // (Možeš i otvoriti za sve korisnike ako želiš)

        return attendeeRepository.findActiveByEventId(eventId)
                .stream()
                .map(ea -> {
                    User user = ea.getUser();
                    UserProfile profile = user.getProfile();
                    String photoUrl = photoRepository.findByUserIdOrderByPhotoOrder(user.getId())
                            .stream()
                            .filter(UserPhoto::getIsPrimary)
                            .map(UserPhoto::getPhotoUrl)
                            .findFirst().orElse(null);
                    return AttendeeResponse.builder()
                            .userId(user.getId())
                            .displayName(user.getDisplayName())
                            .photoUrl(photoUrl)
                            .gender(profile != null && profile.getGender() != null
                                    ? profile.getGender().name() : null)
                            .birthYear(profile != null ? profile.getBirthYear() : null)
                            .build();
                })
                .collect(java.util.stream.Collectors.toList());
    }

    // ── Dohvati naziv i logo tvrtke za company evente ─────────────────────────
    private String[] getCompanyInfo(String companyId) {
        try {
            return jdbcTemplate.queryForObject(
                    "SELECT org_name, logo_url FROM companies WHERE id = ?",
                    (rs, i) -> new String[]{ rs.getString("org_name"), rs.getString("logo_url") },
                    companyId);
        } catch (Exception e) {
            return new String[]{ null, null };
        }
    }

    private EventResponse toResponse(Event e, String userId) {
        int count = attendeeRepository.countByEventIdAndStatus(e.getId(), "joined");
        boolean attending = userId != null &&
                attendeeRepository.findByEventIdAndUserId(e.getId(), userId)
                        .map(a -> "joined".equals(a.getStatus()))
                        .orElse(false);

        String companyName    = null;
        String companyLogoUrl = null;
        if (Boolean.TRUE.equals(e.getIsCompanyEvent()) && e.getCompanyId() != null) {
            String[] info = getCompanyInfo(e.getCompanyId());
            if (info != null) {
                companyName    = info[0];
                companyLogoUrl = info[1];
            }
        }

        return EventResponse.builder()
                .id(e.getId())
                .creatorId(e.getCreator() != null ? e.getCreator().getId() : e.getCompanyId())
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
                .isUserEvent(Boolean.TRUE.equals(e.getIsUserEvent()))
                .isCompanyEvent(Boolean.TRUE.equals(e.getIsCompanyEvent()))
                .latitude(e.getLatitude())
                .longitude(e.getLongitude())
                .isAttending(attending)
                .ticketPrice(e.getTicketPrice())
                .ticketCurrency(e.getTicketCurrency())
                .companyName(companyName)
                .companyLogoUrl(companyLogoUrl)
                .build();
    }
}