package com.meetcute.backend.service;

import com.meetcute.backend.dto.LoginRequest;
import com.meetcute.backend.dto.AuthResponse;
import com.meetcute.backend.entity.User;
import com.meetcute.backend.entity.RefreshToken;
import com.meetcute.backend.repository.*;
import com.meetcute.backend.security.JwtUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock private UserRepository userRepository;
    @Mock private UserProfileRepository profileRepository;
    @Mock private UserInterestRepository interestRepository;
    @Mock private InterestRepository interestLookup;
    @Mock private SecretQuestionRepository questionRepository;
    @Mock private RefreshTokenRepository tokenRepository;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private JwtUtil jwtUtil;

    @InjectMocks
    private AuthService authService;

    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = User.builder()
                .id("user-123")
                .username("testuser")
                .displayName("Test User")
                .passwordHash("$2a$hashedpassword")
                .isPremium(false)
                .isActive(true)
                .isBanned(false)
                .build();
    }

    @Test
    void login_correctCredentials_returnsAuthResponse() {
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(passwordEncoder.matches("Password123", testUser.getPasswordHash())).thenReturn(true);
        when(jwtUtil.generateAccessToken(any(), any())).thenReturn("access-token");
        when(jwtUtil.generateRefreshToken(any())).thenReturn("refresh-token");
        when(tokenRepository.save(any(RefreshToken.class))).thenAnswer(i -> i.getArgument(0));

        LoginRequest req = new LoginRequest("testuser", "Password123");
        AuthResponse response = authService.login(req);

        assertNotNull(response);
        assertEquals("access-token", response.getAccessToken());
        assertEquals("refresh-token", response.getRefreshToken());
        assertEquals("testuser", response.getUser().getUsername());
    }

    @Test
    void login_wrongPassword_throwsException() {
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(passwordEncoder.matches(any(), any())).thenReturn(false);

        LoginRequest req = new LoginRequest("testuser", "WrongPassword");

        RuntimeException ex = assertThrows(RuntimeException.class, () -> authService.login(req));
        assertTrue(ex.getMessage().contains("Pogrešno"));
    }

    @Test
    void login_userNotFound_throwsException() {
        when(userRepository.findByUsername(any())).thenReturn(Optional.empty());

        LoginRequest req = new LoginRequest("nepostojeci", "Password123");

        assertThrows(RuntimeException.class, () -> authService.login(req));
    }

    @Test
    void login_bannedUser_throwsException() {
        testUser.setIsBanned(true);
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));

        LoginRequest req = new LoginRequest("testuser", "Password123");

        RuntimeException ex = assertThrows(RuntimeException.class, () -> authService.login(req));
        assertTrue(ex.getMessage().contains("suspendiran"));
    }

    @Test
    void login_inactiveUser_throwsException() {
        testUser.setIsActive(false);
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));

        LoginRequest req = new LoginRequest("testuser", "Password123");

        RuntimeException ex = assertThrows(RuntimeException.class, () -> authService.login(req));
        assertTrue(ex.getMessage().contains("aktivan"));
    }

    @Test
    void logout_validToken_revokesToken() {
        RefreshToken stored = RefreshToken.builder()
                .isRevoked(false)
                .build();

        when(tokenRepository.findByTokenHash(any())).thenReturn(Optional.of(stored));
        when(tokenRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        authService.logout("some-refresh-token");

        assertTrue(stored.getIsRevoked());
        verify(tokenRepository).save(stored);
    }
}