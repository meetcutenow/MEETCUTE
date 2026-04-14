package com.meetcute.backend.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

// ============================================================
//  Datoteka: src/main/java/com/meetcute/backend/dto/Dtos.java
//  Svi Request i Response objekti
// ============================================================


// ── AUTH ──────────────────────────────────────────────────────

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RegisterRequest {
    @NotBlank(message = "Korisničko ime je obavezno")
    @Size(min = 3, max = 50, message = "Korisničko ime mora biti između 3 i 50 znakova")
    @Pattern(regexp = "^[a-zA-Z0-9_]+$", message = "Korisničko ime smije sadržavati samo slova, brojeve i _")
    private String username;

    @NotBlank(message = "Ime je obavezno")
    @Size(min = 2, max = 100, message = "Ime mora biti između 2 i 100 znakova")
    private String displayName;

    @NotBlank(message = "Lozinka je obavezna")
    @Size(min = 8, message = "Lozinka mora imati najmanje 8 znakova")
    private String password;

    // ProfileStep1
    @NotNull(message = "Dan rođenja je obavezan")
    @Min(1) @Max(31)
    private Integer birthDay;

    @NotNull(message = "Mjesec rođenja je obavezan")
    @Min(1) @Max(12)
    private Integer birthMonth;

    @NotNull(message = "Godina rođenja je obavezna")
    @Min(1900) @Max(2100)
    private Integer birthYear;

    @NotNull(message = "Visina je obavezna")
    @Min(50) @Max(250)
    private Integer heightCm;

    @NotBlank(message = "Spol je obavezan")
    private String gender;

    @NotBlank(message = "Boja kose je obavezna")
    private String hairColor;

    @NotBlank(message = "Boja očiju je obavezna")
    private String eyeColor;

    @NotNull(message = "Pirsing je obavezan")
    private Boolean hasPiercing;

    @NotNull(message = "Tetovaža je obavezna")
    private Boolean hasTattoo;

    // ProfileStep2 — interesi
    @NotEmpty(message = "Odaberi najmanje jedan interes")
    private List<Integer> interestIds;

    // ProfileStep3
    @NotBlank(message = "Ice breaker je obavezan")
    @Size(max = 500)
    private String iceBreaker;

    // Tajno pitanje
    @NotNull(message = "Tajno pitanje je obavezno")
    private Integer secretQuestionId;

    @NotBlank(message = "Odgovor na tajno pitanje je obavezan")
    private String secretAnswer;
}

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
class LoginRequest {
    @NotBlank(message = "Korisničko ime je obavezno")
    private String username;

    @NotBlank(message = "Lozinka je obavezna")
    private String password;
}

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
class AuthResponse {
    private String accessToken;
    private String refreshToken;
    private UserResponse user;
}

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
class RefreshRequest {
    @NotBlank
    private String refreshToken;
}

// ── USER ──────────────────────────────────────────────────────

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
class UserResponse {
    private String id;
    private String username;
    private String displayName;
    private Boolean isPremium;
    private ProfileResponse profile;
    private List<String> photoUrls;
    private List<String> interests;
}

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
class ProfileResponse {
    private Integer birthYear;
    private Integer age;
    private String gender;
    private String seekingGender;
    private Integer heightCm;
    private String hairColor;
    private String eyeColor;
    private Boolean hasPiercing;
    private Boolean hasTattoo;
    private String iceBreaker;
    private Boolean isVisible;
    private String secretQuestion;
}

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
class UpdateProfileRequest {
    private String iceBreaker;
    private String seekingGender;
    private Integer maxDistancePrefM;
    private Boolean isVisible;
}

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
class UpdateLocationRequest {
    @NotNull
    private Double latitude;
    @NotNull
    private Double longitude;
    private String city;
}

// ── EVENTS ────────────────────────────────────────────────────

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
class EventResponse {
    private String id;
    private String title;
    private String city;
    private String specificLocation;
    private String eventDate;
    private String timeStart;
    private String timeEnd;
    private String description;
    private String category;
    private String ageGroup;
    private String genderGroup;
    private Integer maxAttendees;
    private Integer attendeeCount;
    private Boolean isFull;
    private String coverPhotoUrl;
    private String cardColorHex;
    private Boolean isUserEvent;
    private Double latitude;
    private Double longitude;
    private Boolean isAttending;
}

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
class CreateEventRequest {
    @NotBlank
    private String title;
    private String description;
    @NotBlank
    private String city;
    private String specificLocation;
    @NotNull
    private String eventDate;
    private String timeStart;
    private String timeEnd;
    @NotBlank
    private String category;
    private String ageGroup;
    private String genderGroup;
    private Integer maxAttendees;
    private String cardColorHex;
    private Double latitude;
    private Double longitude;
}

// ── MATCHES & CHAT ────────────────────────────────────────────

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
class LikeRequest {
    @NotBlank
    private String likedUserId;
    private String contextType;
    private String contextEventId;
}

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
class MatchResponse {
    private Long matchId;
    private String otherUserId;
    private String otherUserName;
    private String otherUserPhoto;
    private Integer commonInterests;
    private Integer distanceM;
    private String status;
    private LocalDateTime matchedAt;
    private String conversationId;
    private String secretQuestion;
    private Integer attemptsLeft;
}

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
class SecretAnswerRequest {
    @NotBlank
    private String answer;
}

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
class MessageResponse {
    private Long id;
    private String senderId;
    private String senderName;
    private String body;
    private String photoUrl;
    private LocalDateTime sentAt;
    private Boolean isMe;
}

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
class SendMessageRequest {
    private String body;
    private String photoUrl;
}

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
class ConversationResponse {
    private String id;
    private Long matchId;
    private String otherUserId;
    private String otherUserName;
    private String otherUserPhoto;
    private String lastMessageText;
    private LocalDateTime lastMessageAt;
    private Integer unreadCount;
}

// ── NOTIFICATIONS ─────────────────────────────────────────────

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
class NotificationResponse {
    private Long id;
    private String type;
    private String title;
    private String body;
    private String eventId;
    private Long matchId;
    private String nearbyUserId;
    private Boolean isRead;
    private String accentColor;
    private LocalDateTime createdAt;
}

// ── SECRET QUESTIONS ──────────────────────────────────────────

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
class SecretQuestionResponse {
    private Integer id;
    private String questionText;
    private String category;
}

// ── API RESPONSE WRAPPER ──────────────────────────────────────

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
class ApiResponse<T> {
    private Boolean success;
    private String message;
    private T data;

    public static <T> ApiResponse<T> ok(T data) {
        return ApiResponse.<T>builder()
                .success(true)
                .data(data)
                .build();
    }

    public static <T> ApiResponse<T> ok(String message, T data) {
        return ApiResponse.<T>builder()
                .success(true)
                .message(message)
                .data(data)
                .build();
    }

    public static <T> ApiResponse<T> error(String message) {
        return ApiResponse.<T>builder()
                .success(false)
                .message(message)
                .build();
    }
}
