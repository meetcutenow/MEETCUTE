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
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CompanyEventService {

    private final EventRepository eventRepository;
    private final EventAttendeeRepository attendeeRepository;
    private final CompanyRepository companyRepository;
    private final JdbcTemplate jdbcTemplate;

    @Transactional
    public EventResponse createCompanyEvent(CreateCompanyEventRequest req, String companyId) {
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new RuntimeException("Tvrtka nije pronađena."));

        Event event = Event.builder()
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
                .cardColorHex(req.getCardColorHex() != null ? req.getCardColorHex() : "#700D25")
                .latitude(req.getLatitude())
                .longitude(req.getLongitude())
                .isUserEvent(false)
                .isActive(true)
                .build();

        event = eventRepository.save(event);

        String currency = req.getTicketCurrency() != null ? req.getTicketCurrency() : "EUR";
        jdbcTemplate.update(
                "UPDATE events SET company_id = ?, is_company_event = 1, ticket_price = ?, ticket_currency = ? WHERE id = ?",
                companyId,
                req.getTicketPrice(),
                currency,
                event.getId()
        );

        return toResponse(event, companyId, req.getTicketPrice(), currency, company.getOrgName());
    }

    public List<EventResponse> getCompanyEvents(String companyId) {
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new RuntimeException("Tvrtka nije pronađena."));

        String sql = "SELECT * FROM events WHERE company_id = ? AND is_active = 1 ORDER BY event_date ASC";
        List<String> eventIds = jdbcTemplate.query(
                sql,
                (rs, i) -> rs.getString("id"),
                companyId
        );

        return eventIds.stream().map(id -> {
            Event event = eventRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Event nije pronađen."));
            Object[] extra = fetchExtra(id);
            Double price = extra[0] != null ? ((BigDecimal) extra[0]).doubleValue() : null;
            String curr = extra[1] != null ? (String) extra[1] : "EUR";
            return toResponse(event, companyId, price, curr, company.getOrgName());
        }).collect(Collectors.toList());
    }

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

    private Object[] fetchExtra(String eventId) {
        return jdbcTemplate.queryForObject(
                "SELECT ticket_price, ticket_currency FROM events WHERE id = ?",
                (rs, i) -> new Object[]{rs.getObject("ticket_price"), rs.getString("ticket_currency")},
                eventId
        );
    }

    private EventResponse toResponse(Event e, String companyId, Double ticketPrice,
                                     String currency, String orgName) {
        int count = attendeeRepository.countByEventIdAndStatus(e.getId(), "joined");
        return EventResponse.builder()
                .id(e.getId())
                .creatorId(companyId)
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
                .cardColorHex(e.getCardColorHex())
                .isUserEvent(false)
                .latitude(e.getLatitude())
                .longitude(e.getLongitude())
                .isAttending(false)
                .ticketPrice(ticketPrice)
                .ticketCurrency(currency)
                .companyName(orgName)
                .isCompanyEvent(true)
                .build();
    }
}