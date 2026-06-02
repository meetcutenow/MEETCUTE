package com.meetcute.backend.repository;

import com.meetcute.backend.entity.Conversation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface ConversationRepository extends JpaRepository<Conversation, String> {

    Optional<Conversation> findByMatchId(Long matchId);

    @Query("SELECT c FROM Conversation c JOIN ConversationParticipant cp ON cp.conversation.id = c.id " +
            "WHERE cp.user.id = :userId AND cp.isActive = true ORDER BY c.lastMessageAt DESC")
    List<Conversation> findByUserId(@Param("userId") String userId);
}