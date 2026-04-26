package com.meetcute.backend.repository;

import com.meetcute.backend.entity.*;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface EventRepository extends JpaRepository<Event, String> {

    List<Event> findByIsActiveTrueOrderByCreatedAtDesc();
    List<Event> findByCityAndIsActiveTrueOrderByCreatedAtDesc(String city);
    List<Event> findByCompanyIdAndIsActiveTrueOrderByCreatedAtDesc(String companyId);

    // Za company evente
    List<Event> findByCompanyIdAndIsActiveTrueOrderByEventDateAsc(String companyId);
}