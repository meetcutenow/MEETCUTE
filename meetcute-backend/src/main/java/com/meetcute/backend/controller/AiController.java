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

    private static final String GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";
    private static final String GROQ_MODEL = "llama-3.3-70b-versatile";
    private static final ObjectMapper MAPPER = new ObjectMapper();

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
            
            Ako nešto nije rečeno, stavi null. iceBreaker treba biti kratka, zanimljiva rečenica na ISTOM jeziku kao transkripcija. height mora biti cijeli broj bez teksta (npr. 160, ne "160 cm"). Ako korisnik kaže koliko ima godina (npr. "imam 21 godinu"), izračunaj birthYear = 2025 - taj broj. birthDay i birthMonth postavi na null ako nisu izričito rečeni.
            """;

    @Value("${groq.api-key}")
    private String groqApiKey;

    private final RestTemplate restTemplate;

    @PostMapping("/parse-profile")
    public ResponseEntity<ApiResponse<Map>> parseProfile(@RequestBody Map<String, String> req) {
        String transcript = req.get("transcript");
        if (transcript == null || transcript.isBlank()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Transkript je prazan."));
        }

        Map<String, Object> body = Map.of(
                "model", GROQ_MODEL,
                "max_tokens", 1000,
                "messages", List.of(Map.of(
                        "role", "user",
                        "content", SYSTEM_PROMPT + "\n\nTranskripcija korisnika: \"" + transcript + "\""
                ))
        );

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("Authorization", "Bearer " + groqApiKey);

        try {
            ResponseEntity<Map> response = restTemplate.exchange(
                    GROQ_URL, HttpMethod.POST, new HttpEntity<>(body, headers), Map.class
            );

            String text = extractContent(response.getBody());
            Map parsed = MAPPER.readValue(text, Map.class);
            return ResponseEntity.ok(ApiResponse.ok(parsed));

        } catch (Exception e) {
            System.err.printf("=== GROQ GREŠKA ===%nMessage: %s%n", e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Greška pri pozivu Groq AI: " + e.getMessage()));
        }
    }

    @SuppressWarnings("unchecked")
    private String extractContent(Map<?, ?> responseBody) {
        var first = (Map<?, ?>) ((List<?>) responseBody.get("choices")).get(0);
        return ((Map<?, ?>) first.get("message"))
                .get("content").toString()
                .replaceAll("```json|```", "").trim();
    }
}