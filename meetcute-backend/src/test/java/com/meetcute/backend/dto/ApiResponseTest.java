package com.meetcute.backend.dto;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class ApiResponseTest {

    @Test
    void ok_withData_successTrue() {
        ApiResponse<String> response = ApiResponse.ok("hello");

        assertTrue(response.getSuccess());
        assertEquals("hello", response.getData());
        assertNull(response.getMessage());
    }

    @Test
    void ok_withMessageAndData_allFieldsSet() {
        ApiResponse<Integer> response = ApiResponse.ok("Uspješno!", 42);

        assertTrue(response.getSuccess());
        assertEquals("Uspješno!", response.getMessage());
        assertEquals(42, response.getData());
    }

    @Test
    void error_successFalse() {
        ApiResponse<Void> response = ApiResponse.error("Greška!");

        assertFalse(response.getSuccess());
        assertEquals("Greška!", response.getMessage());
        assertNull(response.getData());
    }

    @Test
    void ok_withNullData_stillSuccessful() {
        ApiResponse<Void> response = ApiResponse.ok(null);

        assertTrue(response.getSuccess());
        assertNull(response.getData());
    }
}