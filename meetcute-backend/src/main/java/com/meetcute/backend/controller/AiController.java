package com.meetcute.backend.controller;

import com.meetcute.backend.dto.ApiResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
public class AiController {

    @Value("${gemini.api-key}")
    private String geminiApiKey;

    private final RestTemplate restTemplate;

    private static final String SYSTEM_PROMPT = """
            Ti si asistent koji pomaže korisnicima ispuniti profil na MeetCute aplikaciji za upoznavanje.
            
            Korisnik ti daje transkripciju svog glasovnog opisa. Izvuci relevantne podatke i vrati JSON.
            
            VAŽNO - Vrijednosti moraju biti TOČNO ovakve (ili null):
            gender: "musko" | "zensko" | "ostalo"
            hairColor: "plava" | "smeda" | "crna" | "crvena" | "sijeda" | "ostalo"
            eyeColor: "smede" | "zelene" | "plave" | "sive"
            piercing: "da" | "ne"
            tattoo: "da" | "ne"
            seekingGender: "musko" | "zensko" | "sve"
            interests: Lista od ovih vrijednosti: ["Crtanje","Fotografija","Pisanje","Film","Trčanje","Biciklizam","Planinarenje","Teretana","Boks","Tenis","Nogomet","Odbojka","Kuhanje","Putovanja","Gaming","Formula","Glazba"]
            
            Vrati SAMO JSON bez ikakvih komentara ili objašnjenja:
            {
              "birthYear": null,
              "birthMonth": null,
              "birthDay": null,
              "height": null,
              "gender": null,
              "hairColor": null,
              "eyeColor": null,
              "piercing": null,
              "tattoo": null,
              "interests": [],
              "iceBreaker": null,
              "seekingGender": null,
              "prefAgeFrom": null,
              "prefAgeTo": null
            }
            
            Ako nešto nije rečeno, stavi null. iceBreaker treba biti kratka, zanimljiva rečenica na ISTOM jeziku kao transkripcija.
            """;

    @PostMapping("/parse-profile")
    public ResponseEntity<ApiResponse<Map>> parseProfile(
            @RequestBody Map<String, String> req) {

        String transcript = req.get("transcript");
        if (transcript == null || transcript.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Transkript je prazan."));
        }

        String url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=" + geminiApiKey;

        Map<String, Object> body = Map.of(
                "contents", List.of(
                        Map.of("parts", List.of(
                                Map.of("text", SYSTEM_PROMPT + "\n\nTranskripcija korisnika: \"" + transcript + "\"")
                        ))
                ),
                "generationConfig", Map.of(
                        "temperature", 0.1,
                        "maxOutputTokens", 1000
                )
        );

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        try {
            ResponseEntity<Map> response = restTemplate.exchange(
                    url,
                    HttpMethod.POST,
                    new HttpEntity<>(body, headers),
                    Map.class
            );

            var candidates = (List<?>) response.getBody().get("candidates");
            var firstCandidate = (Map<?, ?>) candidates.get(0);
            var content = (Map<?, ?>) firstCandidate.get("content");
            var parts = (List<?>) content.get("parts");
            var firstPart = (Map<?, ?>) parts.get(0);
            String text = firstPart.get("text").toString().trim()
                    .replaceAll("```json|```", "").trim();

            ObjectMapper mapper = new ObjectMapper();
            Map parsed = mapper.readValue(text, Map.class);

            return ResponseEntity.ok(ApiResponse.ok(parsed));

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Greška pri pozivu Gemini AI: " + e.getMessage()));
        }
    }
}