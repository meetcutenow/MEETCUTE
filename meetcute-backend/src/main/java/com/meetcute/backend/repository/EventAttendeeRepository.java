package com.meetcute.backend.repository;

import com.meetcute.backend.entity.EventAttendee;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface EventAttendeeRepository extends JpaRepository<EventAttendee, EventAttendee.EventAttendeeId> {

    int countByEventIdAndStatus(String eventId, String status);

    Optional<EventAttendee> findByEventIdAndUserId(String eventId, String userId);

    @Query("SELECT ea FROM EventAttendee ea WHERE ea.user.id = :userId AND ea.status = 'joined'")
    List<EventAttendee> findActiveByUserId(@Param("userId") String userId);

    @Query("SELECT ea FROM EventAttendee ea WHERE ea.event.id = :eventId AND ea.status = 'joined'")
    List<EventAttendee> findActiveByEventId(@Param("eventId") String eventId);
}