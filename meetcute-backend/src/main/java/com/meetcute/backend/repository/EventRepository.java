package com.meetcute.backend.repository;

import com.meetcute.backend.entity.Event;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface EventRepository extends JpaRepository<Event, String> {

    List<Event> findByIsActiveTrueOrderByCreatedAtDesc();
    List<Event> findByCityAndIsActiveTrueOrderByCreatedAtDesc(String city);
    List<Event> findByCompanyIdAndIsActiveTrueOrderByEventDateAsc(String companyId);
}