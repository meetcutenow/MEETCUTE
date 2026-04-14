package com.meetcute.backend.controller;

import com.meetcute.backend.dto.*;
import com.meetcute.backend.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/questions")
@RequiredArgsConstructor
public class QuestionController {

    private final UserService userService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<SecretQuestionResponse>>> getQuestions() {
        List<SecretQuestionResponse> questions = userService.getSecretQuestions();
        return ResponseEntity.ok(ApiResponse.ok(questions));
    }
}
