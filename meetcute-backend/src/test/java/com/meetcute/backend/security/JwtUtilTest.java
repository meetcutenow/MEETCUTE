package com.meetcute.backend.security;

import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.*;

class JwtUtilTest {

    private JwtUtil buildJwtUtil() {
        JwtUtil jwtUtil = new JwtUtil();
        ReflectionTestUtils.setField(jwtUtil, "secret",
                "meetcute-super-secret-key-minimum-32chars-long!!");
        ReflectionTestUtils.setField(jwtUtil, "accessTokenExpiration", 3600000L);
        ReflectionTestUtils.setField(jwtUtil, "refreshTokenExpiration", 2592000000L);
        return jwtUtil;
    }

    @Test
    void generateAccessToken_notNull() {
        JwtUtil jwtUtil = buildJwtUtil();
        String token = jwtUtil.generateAccessToken("user-123", "testuser");
        assertNotNull(token);
        assertFalse(token.isBlank());
    }

    @Test
    void extractUserId_returnsCorrectId() {
        JwtUtil jwtUtil = buildJwtUtil();
        String token = jwtUtil.generateAccessToken("user-123", "testuser");
        assertEquals("user-123", jwtUtil.extractUserId(token));
    }

    @Test
    void isTokenValid_validToken_returnsTrue() {
        JwtUtil jwtUtil = buildJwtUtil();
        String token = jwtUtil.generateAccessToken("user-123", "testuser");
        assertTrue(jwtUtil.isTokenValid(token));
    }

    @Test
    void isTokenValid_invalidToken_returnsFalse() {
        JwtUtil jwtUtil = buildJwtUtil();
        assertFalse(jwtUtil.isTokenValid("ovo.nije.validan.token"));
    }

    @Test
    void isTokenExpired_freshToken_returnsFalse() {
        JwtUtil jwtUtil = buildJwtUtil();
        String token = jwtUtil.generateAccessToken("user-123", "testuser");
        assertFalse(jwtUtil.isTokenExpired(token));
    }

    @Test
    void generateRefreshToken_extractsCorrectUserId() {
        JwtUtil jwtUtil = buildJwtUtil();
        String token = jwtUtil.generateRefreshToken("user-123");
        assertNotNull(token);
        assertEquals("user-123", jwtUtil.extractUserId(token));
    }

    @Test
    void extractRole_defaultUserRole() {
        JwtUtil jwtUtil = buildJwtUtil();
        String token = jwtUtil.generateAccessToken("user-123", "testuser");
        assertEquals("user", jwtUtil.extractRole(token));
    }

    @Test
    void generateAccessTokenWithRole_companyRole() {
        JwtUtil jwtUtil = buildJwtUtil();
        String token = jwtUtil.generateAccessTokenWithRole("comp-456", "mycompany", "company");
        assertEquals("comp-456", jwtUtil.extractUserId(token));
        assertEquals("company", jwtUtil.extractRole(token));
    }
}