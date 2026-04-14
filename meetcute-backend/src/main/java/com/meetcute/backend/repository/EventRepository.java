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
public interface EventRepository extends JpaRepository<Event, String> {

    List<Event> findByIsActiveTrueOrderByEventDateAsc();

    List<Event> findByCityAndIsActiveTrueOrderByEventDateAsc(String city);

    List<Event> findByCategoryAndIsActiveTrueOrderByEventDateAsc(String category);
}

