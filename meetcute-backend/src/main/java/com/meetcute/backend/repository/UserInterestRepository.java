package com.meetcute.backend.repository;

import com.meetcute.backend.entity.UserInterest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Repository
public interface UserInterestRepository extends JpaRepository<UserInterest, UserInterest.UserInterestId> {

    List<UserInterest> findByUserId(String userId);

    @Modifying
    @Transactional
    void deleteByUserId(String userId);
}