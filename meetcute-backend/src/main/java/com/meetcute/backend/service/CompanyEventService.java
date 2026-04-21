package com.meetcute.backend.service;

import com.meetcute.backend.dto.*;
import com.meetcute.backend.entity.*;
import com.meetcute.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CompanyEventService {

    private final EventRepository            eventRepository;
    private final EventAttendeeRepository    attendeeRepository;
    private final CompanyRepository          companyRepository;
    private final NotificationRepository     notificationRepository;
    private final UserRepository             userRepository;
    private final JdbcTemplate               jdbcTemplate;

    // ── Kreiraj event ─────────────────────────────────────────────────────────
    @Transactional
    public EventResponse createCompanyEvent(CreateCompanyEventRequest req, String companyId) {
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new RuntimeException("Organizacija nije pronađena."));

        String currency  = req.getTicketCurrency() != null ? req.getTicketCurrency() : "EUR";
        String cardColor = req.getCardColorHex()   != null ? req.getCardColorHex()   : "#6DD5E8";
        String eventId   = UUID.randomUUID().toString();

        LocalDate eventDate = LocalDate.parse(req.getEventDate());
        LocalTime timeStart = req.getTimeStart() != null ? LocalTime.parse(req.getTimeStart()) : null;
        LocalTime timeEnd   = req.getTimeEnd()   != null ? LocalTime.parse(req.getTimeEnd())   : null;

        // Postojeći INSERT — zamijeni s ovim:
        jdbcTemplate.update(
                "INSERT INTO events (id, company_id, title, description, city, specific_location, " +
                        "latitude, longitude, event_date, time_start, time_end, category, age_group, " +
                        "gender_group, max_attendees, ticket_price, ticket_currency, card_color_hex, " +
                        "cover_photo_url, is_user_event, is_company_event, is_active, created_at, updated_at) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 1, 1, NOW(), NOW())",
                eventId, companyId,
                req.getTitle(), req.getDescription(), req.getCity(), req.getSpecificLocation(),
                req.getLatitude(), req.getLongitude(),
                eventDate.toString(),
                timeStart != null ? timeStart.toString() : null,
                timeEnd   != null ? timeEnd.toString()   : null,
                req.getCategory(),
                req.getAgeGroup()    != null ? req.getAgeGroup()    : "all",
                req.getGenderGroup() != null ? req.getGenderGroup() : "all",
                req.getMaxAttendees(), req.getTicketPrice(), currency, cardColor,
                req.getCoverPhotoUrl()  // NOVO
        );

        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new RuntimeException("Event nije mogao biti kreiran."));

        return toResponse(event, companyId, req.getTicketPrice(), currency,
                company.getOrgName(), company.getLogoUrl(), company.getEmail(), null);
    }

    // ── Dohvati evente organizacije ───────────────────────────────────────────
    public List<EventResponse> getCompanyEvents(String companyId, String userId) {
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new RuntimeException("Organizacija nije pronađena."));

        List<Event> events = eventRepository.findByCompanyIdAndIsActiveTrueOrderByEventDateAsc(companyId);

        return events.stream().map(event -> {
            Double price = event.getTicketPrice();
            String curr  = event.getTicketCurrency() != null ? event.getTicketCurrency() : "EUR";
            return toResponse(event, companyId, price, curr,
                    company.getOrgName(), company.getLogoUrl(), company.getEmail(), userId);
        }).collect(Collectors.toList());
    }

    // ── Uredi event + obavijesti prijavljene ──────────────────────────────────
    @Transactional
    public EventResponse updateCompanyEvent(String eventId, String companyId, UpdateEventRequest req) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new RuntimeException("Događaj nije pronađen."));

        if (event.getCompanyId() == null || !event.getCompanyId().equals(companyId)) {
            throw new RuntimeException("Nemate pravo uređivati ovaj događaj.");
        }

        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new RuntimeException("Organizacija nije pronađena."));

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
        if (req.getCoverPhotoUrl() != null)    event.setCoverPhotoUrl(req.getCoverPhotoUrl());

        eventRepository.save(event);

        notifyAttendeesSql(eventId,
                "Događaj izmijenjen",
                "\"" + event.getTitle() + "\" je ažuriran od strane organizatora "
                        + company.getOrgName() + ". Provjeri nove detalje.",
                "#FFD166");

        return toResponse(event, companyId, event.getTicketPrice(), event.getTicketCurrency(),
                company.getOrgName(), company.getLogoUrl(), company.getEmail(), null);
    }

    // ── Obriši event + obavijesti prijavljene ─────────────────────────────────
    @Transactional
    public void deleteCompanyEvent(String eventId, String companyId) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new RuntimeException("Događaj nije pronađen."));

        if (event.getCompanyId() == null || !event.getCompanyId().equals(companyId)) {
            throw new RuntimeException("Nemate pravo brisati ovaj događaj.");
        }

        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new RuntimeException("Organizacija nije pronađena."));

        notifyAttendeesSql(eventId,
                "Događaj otkazan",
                "Nažalost, \"" + event.getTitle() + "\" je otkazan od strane organizatora "
                        + company.getOrgName() + ".",
                "#D93025");

        event.setIsActive(false);
        eventRepository.save(event);
    }

    // ── Statistike ────────────────────────────────────────────────────────────
    public List<CompanyEventStatsResponse> getEventStats(String companyId) {
        String sql = "SELECT event_id, title, event_date, total_joined, total_cancelled, " +
                "male_count, female_count, other_count, age_18_25, age_26_35, age_36_45, age_45plus, " +
                "ticket_price, ticket_currency, total_revenue " +
                "FROM v_company_event_stats WHERE company_id = ? ORDER BY event_date DESC";

        return jdbcTemplate.query(sql, (rs, i) -> {
            CompanyEventStatsResponse s = new CompanyEventStatsResponse();
            s.setEventId(rs.getString("event_id"));
            s.setTitle(rs.getString("title"));
            s.setEventDate(rs.getString("event_date"));
            s.setTotalJoined(rs.getInt("total_joined"));
            s.setTotalCancelled(rs.getInt("total_cancelled"));
            s.setMaleCount(rs.getInt("male_count"));
            s.setFemaleCount(rs.getInt("female_count"));
            s.setOtherCount(rs.getInt("other_count"));
            s.setAge18_25(rs.getInt("age_18_25"));
            s.setAge26_35(rs.getInt("age_26_35"));
            s.setAge36_45(rs.getInt("age_36_45"));
            s.setAge45plus(rs.getInt("age_45plus"));
            BigDecimal price = rs.getBigDecimal("ticket_price");
            s.setTicketPrice(price != null ? price.doubleValue() : null);
            s.setTicketCurrency(rs.getString("ticket_currency"));
            s.setTotalRevenue(rs.getDouble("total_revenue"));
            return s;
        }, companyId);
    }


    private void notifyAttendeesSql(String eventId, String title, String body, String accentColor) {
        try {
            List<String> userIds = jdbcTemplate.queryForList(
                    "SELECT user_id FROM event_attendees WHERE event_id = ? AND status = 'joined'",
                    String.class, eventId);

            for (String userId : userIds) {
                try {
                    jdbcTemplate.update(
                            "INSERT INTO notifications " +
                                    "(user_id, type, title, body, event_id, accent_color, is_read, created_at) " +
                                    "VALUES (?, 'new_event', ?, ?, ?, ?, 0, NOW())",
                            userId, title, body, eventId, accentColor);
                } catch (Exception ignored) {}
            }
        } catch (Exception ignored) {}
    }

    // ── Mapper ────────────────────────────────────────────────────────────────
    private EventResponse toResponse(Event e, String companyId, Double ticketPrice,
                                     String currency, String orgName,
                                     String logoUrl, String email, String userId) {
        int count = attendeeRepository.countByEventIdAndStatus(e.getId(), "joined");
        boolean attending = userId != null &&
                attendeeRepository.findByEventIdAndUserId(e.getId(), userId)
                        .map(a -> "joined".equals(a.getStatus()))
                        .orElse(false);
        return EventResponse.builder()
                .id(e.getId())
                .creatorId(companyId)
                .title(e.getTitle())
                .city(e.getCity())
                .specificLocation(e.getSpecificLocation())
                .eventDate(e.getEventDate()  != null ? e.getEventDate().toString()  : null)
                .timeStart(e.getTimeStart()  != null ? e.getTimeStart().toString()  : null)
                .timeEnd(e.getTimeEnd()      != null ? e.getTimeEnd().toString()    : null)
                .description(e.getDescription())
                .category(e.getCategory())
                .ageGroup(e.getAgeGroup())
                .genderGroup(e.getGenderGroup())
                .maxAttendees(e.getMaxAttendees())
                .attendeeCount(count)
                .isFull(e.getMaxAttendees() != null && count >= e.getMaxAttendees())
                .cardColorHex(e.getCardColorHex())
                .isUserEvent(false)
                .isCompanyEvent(true)
                .latitude(e.getLatitude())
                .longitude(e.getLongitude())
                .isAttending(attending)
                .ticketPrice(ticketPrice)
                .ticketCurrency(currency)
                .companyName(orgName)
                .companyLogoUrl(logoUrl)
                .companyEmail(email)
                .build();
    }
}