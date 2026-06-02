package com.meetcute.backend.controller;

import com.meetcute.backend.dto.MessageResponse;
import com.meetcute.backend.dto.SendMessageRequest;
import com.meetcute.backend.entity.*;
import com.meetcute.backend.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.handler.annotation.*;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Controller
@RequiredArgsConstructor
@Slf4j
public class ChatWebSocketController {

    private final SimpMessagingTemplate messaging;
    private final ConversationRepository conversationRepository;
    private final MessageRepository messageRepository;
    private final UserRepository userRepository;

    @MessageMapping("/chat/{conversationId}")
    @Transactional
    public void sendMessage(
            @DestinationVariable String conversationId,
            @Payload SendMessageRequest req,
            @Header("simpUser") java.security.Principal principal) {

        Conversation conv = conversationRepository.findById(conversationId)
                .orElse(null);
        if (conv == null) return;
        if (conv.getMatch() == null ||
                !"chat_unlocked".equals(conv.getMatch().getStatus())) {
            log.warn("WebSocket: chat nije otključan za {}", conversationId);
            return;
        }

        User sender = userRepository.findByUsername(principal.getName())
                .orElse(null);
        if (sender == null) return;
        Message message = messageRepository.save(Message.builder()
                .conversation(conv)
                .sender(sender)
                .body(req.getBody())
                .sentAt(LocalDateTime.now())
                .build());

        conv.setLastMessageAt(LocalDateTime.now());
        conversationRepository.save(conv);
        MessageResponse response = MessageResponse.builder()
                .id(message.getId())
                .conversationId(conversationId)
                .senderId(sender.getId())
                .senderName(sender.getDisplayName())
                .body(message.getBody())
                .sentAt(message.getSentAt())
                .build();

        messaging.convertAndSend("/topic/chat/" + conversationId, response);
        log.debug("Poruka broadcastirana u konverzaciju {}", conversationId);
    }
}