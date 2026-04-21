package com.meetcute.backend.service;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.*;

@Service
public class CloudinaryService {

    @Value("${cloudinary.cloud-name}")
    private String cloudName;

    @Value("${cloudinary.api-key}")
    private String apiKey;

    @Value("${cloudinary.api-secret}")
    private String apiSecret;

    public record UploadResult(String url, String publicId) {}

    public UploadResult upload(MultipartFile file, String folder) {
        try {
            long timestamp = System.currentTimeMillis() / 1000L;
            String folderParam = folder != null ? folder : "meetcute";

            // Kreiraj potpis
            String toSign = "folder=" + folderParam + "&timestamp=" + timestamp + apiSecret;
            String signature = sha1Hex(toSign);

            // Multipart request
            String boundary = "---" + UUID.randomUUID().toString().replace("-", "");
            URL url = new URL("https://api.cloudinary.com/v1_1/" + cloudName + "/image/upload");
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setDoOutput(true);
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "multipart/form-data; boundary=" + boundary);

            try (OutputStream out = conn.getOutputStream();
                 PrintWriter writer = new PrintWriter(new OutputStreamWriter(out, StandardCharsets.UTF_8), true)) {

                // api_key
                writeField(writer, out, boundary, "api_key", apiKey);
                // timestamp
                writeField(writer, out, boundary, "timestamp", String.valueOf(timestamp));
                // folder
                writeField(writer, out, boundary, "folder", folderParam);
                // signature
                writeField(writer, out, boundary, "signature", signature);
                // file
                writer.append("--").append(boundary).append("\r\n");
                writer.append("Content-Disposition: form-data; name=\"file\"; filename=\"upload.jpg\"").append("\r\n");
                writer.append("Content-Type: image/jpeg").append("\r\n\r\n");
                writer.flush();
                out.write(file.getBytes());
                out.flush();
                writer.append("\r\n");
                writer.append("--").append(boundary).append("--").append("\r\n");
                writer.flush();
            }

            int code = conn.getResponseCode();
            InputStream is = code == 200 ? conn.getInputStream() : conn.getErrorStream();
            String response = new String(is.readAllBytes(), StandardCharsets.UTF_8);

            if (code != 200) {
                throw new RuntimeException("Cloudinary greška: " + response);
            }

            // Parsiranje JSON odgovora (bez vanjskih library-a)
            String secureUrl = extractJson(response, "secure_url");
            String publicId  = extractJson(response, "public_id");

            return new UploadResult(secureUrl, publicId);

        } catch (Exception e) {
            throw new RuntimeException("Upload slike nije uspio: " + e.getMessage(), e);
        }
    }

    private void writeField(PrintWriter writer, OutputStream out, String boundary,
                            String name, String value) {
        writer.append("--").append(boundary).append("\r\n");
        writer.append("Content-Disposition: form-data; name=\"").append(name).append("\"").append("\r\n\r\n");
        writer.append(value).append("\r\n");
        writer.flush();
    }

    private String sha1Hex(String input) throws Exception {
        MessageDigest md = MessageDigest.getInstance("SHA-1");
        byte[] bytes = md.digest(input.getBytes(StandardCharsets.UTF_8));
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) sb.append(String.format("%02x", b));
        return sb.toString();
    }

    private String extractJson(String json, String key) {
        String search = "\"" + key + "\":\"";
        int start = json.indexOf(search);
        if (start == -1) return "";
        start += search.length();
        int end = json.indexOf("\"", start);
        return end == -1 ? "" : json.substring(start, end);
    }
}