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

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/repository/UserRepository.java
// ============================================================

@Repository
public interface UserRepository extends JpaRepository<User, String> {

    Optional<User> findByUsername(String username);

    boolean existsByUsername(String username);

    boolean existsByEmail(String email);

    @Modifying
    @Transactional
    @Query("UPDATE User u SET u.lastSeenAt = CURRENT_TIMESTAMP WHERE u.id = :id")
    void updateLastSeen(@Param("id") String id);
}

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/repository/UserProfileRepository.java
// ============================================================

@Repository
interface UserProfileRepository extends JpaRepository<UserProfile, String> {
}

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/repository/UserPhotoRepository.java
// ============================================================

@Repository
interface UserPhotoRepository extends JpaRepository<UserPhoto, Long> {

    List<UserPhoto> findByUserIdOrderByPhotoOrder(String userId);

    int countByUserId(String userId);

    @Modifying
    @Transactional
    @Query("UPDATE UserPhoto p SET p.isPrimary = false WHERE p.user.id = :userId")
    void resetPrimaryPhoto(@Param("userId") String userId);
}

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/repository/InterestRepository.java
// ============================================================

@Repository
interface InterestRepository extends JpaRepository<Interest, Integer> {
}

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/repository/UserInterestRepository.java
// ============================================================

@Repository
interface UserInterestRepository extends JpaRepository<UserInterest, UserInterest.UserInterestId> {

    List<UserInterest> findByUserId(String userId);

    void deleteByUserId(String userId);
}

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/repository/UserLocationRepository.java
// ============================================================

@Repository
interface UserLocationRepository extends JpaRepository<UserLocation, String> {
}

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/repository/SecretQuestionRepository.java
// ============================================================

@Repository
interface SecretQuestionRepository extends JpaRepository<SecretQuestion, Integer> {

    List<SecretQuestion> findByIsActiveTrue();
}

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/repository/EventRepository.java
// ============================================================

@Repository
interface EventRepository extends JpaRepository<Event, String> {

    List<Event> findByIsActiveTrueOrderByEventDateAsc();

    List<Event> findByCityAndIsActiveTrueOrderByEventDateAsc(String city);

    List<Event> findByCategoryAndIsActiveTrueOrderByEventDateAsc(String category);
}

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/repository/EventAttendeeRepository.java
// ============================================================

@Repository
interface EventAttendeeRepository extends JpaRepository<EventAttendee, EventAttendee.EventAttendeeId> {

    int countByEventIdAndStatus(String eventId, String status);

    Optional<EventAttendee> findByEventIdAndUserId(String eventId, String userId);

    @Query("SELECT ea FROM EventAttendee ea WHERE ea.user.id = :userId AND ea.status = 'joined'")
    List<EventAttendee> findActiveByUserId(@Param("userId") String userId);
}

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/repository/MatchRepository.java
// ============================================================

@Repository
interface MatchRepository extends JpaRepository<Match, Long> {

    @Query("SELECT m FROM Match m WHERE (m.userA.id = :userId OR m.userB.id = :userId) " +
           "AND m.status NOT IN ('expired', 'unmatched')")
    List<Match> findActiveByUserId(@Param("userId") String userId);

    Optional<Match> findByUserAIdAndUserBId(String userAId, String userBId);

    List<Match> findByStatusAndMatchedAtBeforeAndUnlockNotifSentAtIsNull(
            String status, LocalDateTime before);

    List<Match> findByExpiresAtBeforeAndStatusNotIn(
            LocalDateTime expires, List<String> statuses);
}

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/repository/ConversationRepository.java
// ============================================================

@Repository
interface ConversationRepository extends JpaRepository<Conversation, String> {

    Optional<Conversation> findByMatchId(Long matchId);

    @Query("SELECT c FROM Conversation c JOIN ConversationParticipant cp ON cp.conversation.id = c.id " +
           "WHERE cp.user.id = :userId AND cp.isActive = true ORDER BY c.lastMessageAt DESC")
    List<Conversation> findByUserId(@Param("userId") String userId);
}

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/repository/MessageRepository.java
// ============================================================

@Repository
interface MessageRepository extends JpaRepository<Message, Long> {

    @Query("SELECT m FROM Message m WHERE m.conversation.id = :convId " +
           "AND m.isDeleted = false ORDER BY m.sentAt ASC")
    List<Message> findByConversationId(@Param("convId") String convId);
}

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/repository/NotificationRepository.java
// ============================================================

@Repository
interface NotificationRepository extends JpaRepository<Notification, Long> {

    List<Notification> findByUserIdOrderByCreatedAtDesc(String userId);

    int countByUserIdAndIsReadFalse(String userId);

    @Modifying
    @Transactional
    @Query("UPDATE Notification n SET n.isRead = true WHERE n.user.id = :userId AND n.isRead = false")
    void markAllReadByUserId(@Param("userId") String userId);
}

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/repository/RefreshTokenRepository.java
// ============================================================

@Repository
interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {

    Optional<RefreshToken> findByTokenHash(String tokenHash);

    @Modifying
    @Transactional
    @Query("UPDATE RefreshToken t SET t.isRevoked = true WHERE t.user.id = :userId")
    void revokeAllByUserId(@Param("userId") String userId);

    @Modifying
    @Transactional
    void deleteByExpiresAtBeforeOrIsRevokedTrue(LocalDateTime expires);
}


@Repository
interface LikeRepository extends JpaRepository<Like, Long> {

    boolean existsByLikerIdAndLikedId(String likerId, String likedId);

    Optional<Like> findByLikerIdAndLikedId(String likerId, String likedId);
}


@Repository
interface ConversationParticipantRepository
        extends JpaRepository<ConversationParticipant,
                ConversationParticipant.ConversationParticipantId> {

    List<ConversationParticipant> findByUserId(String userId);
}
