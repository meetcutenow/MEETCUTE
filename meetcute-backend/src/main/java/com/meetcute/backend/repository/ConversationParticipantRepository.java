package com.meetcute.backend.repository;

import com.meetcute.backend.entity.ConversationParticipant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ConversationParticipantRepository
        extends JpaRepository<ConversationParticipant, ConversationParticipant.ConversationParticipantId> {

    List<ConversationParticipant> findByUserId(String userId);
}