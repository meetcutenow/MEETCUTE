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
public interface UserPhotoRepository extends JpaRepository<UserPhoto, Long> {

    List<UserPhoto> findByUserIdOrderByPhotoOrder(String userId);

    int countByUserId(String userId);

    @Modifying
    @Transactional
    @Query("UPDATE UserPhoto p SET p.isPrimary = false WHERE p.user.id = :userId")
    void resetPrimaryPhoto(@Param("userId") String userId);
}

@Repository
