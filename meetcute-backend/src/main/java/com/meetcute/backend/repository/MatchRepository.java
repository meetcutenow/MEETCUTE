package com.meetcute.backend.repository;

import com.meetcute.backend.entity.Match;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface MatchRepository extends JpaRepository<Match, Long> {

    @Query("SELECT m FROM Match m WHERE (m.userA.id = :userId OR m.userB.id = :userId) " +
            "AND m.status NOT IN ('expired', 'unmatched')")
    List<Match> findActiveByUserId(@Param("userId") String userId);

    Optional<Match> findByUserAIdAndUserBId(String userAId, String userBId);

    List<Match> findByExpiresAtBeforeAndStatusNotIn(LocalDateTime expires, List<String> statuses);
}