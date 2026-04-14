package com.meetcute.backend.repository;

import com.meetcute.backend.entity.*;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface EventAttendeeRepository extends JpaRepository<EventAttendee, EventAttendee.EventAttendeeId> {

    int countByEventIdAndStatus(String eventId, String status);

    Optional<EventAttendee> findByEventIdAndUserId(String eventId, String userId);

    @Query("SELECT ea FROM EventAttendee ea WHERE ea.user.id = :userId AND ea.status = 'joined'")
    List<EventAttendee> findActiveByUserId(@Param("userId") String userId);
}

