package com.meetcute.backend.repository;

import com.meetcute.backend.entity.Message;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface MessageRepository extends JpaRepository<Message, Long> {

    @Query("SELECT m FROM Message m WHERE m.conversation.id = :convId " +
            "AND m.isDeleted = false ORDER BY m.sentAt ASC")
    List<Message> findByConversationId(@Param("convId") String convId);
}