package com.meetcute.backend.security;

import com.meetcute.backend.repository.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.*;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;

@Component
@RequiredArgsConstructor
class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;
    private final MeetCuteUserDetailsService userDetailsService;



    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        String authHeader = request.getHeader("Authorization");

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = authHeader.substring(7);

        if (jwtUtil.isTokenValid(token) && !jwtUtil.isTokenExpired(token)) {
            String userId = jwtUtil.extractUserId(token);

            // Pokušaj učitati korisnika ili tvrtku
            UserDetails userDetails = null;
            try {
                userDetails = userDetailsService.loadUserByUsername(userId);
            } catch (UsernameNotFoundException e) {
                // Nije korisnik — možda je tvrtka, svejedno nastavi s userId kao principal
                userDetails = new org.springframework.security.core.userdetails.User(
                        userId, "", Collections.emptyList());
            }

            UsernamePasswordAuthenticationToken auth =
                    new UsernamePasswordAuthenticationToken(
                            userDetails, null, userDetails.getAuthorities());

            SecurityContextHolder.getContext().setAuthentication(auth);
        }

        filterChain.doFilter(request, response);
    }
}

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;
    private final MeetCuteUserDetailsService userDetailsService;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        // User auth
                        .requestMatchers(HttpMethod.POST, "/api/auth/register").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/auth/login").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/auth/refresh").permitAll()
                        // Company auth
                        .requestMatchers(HttpMethod.POST, "/api/company/auth/register").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/company/auth/login").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/company/auth/refresh").permitAll()
                        // Public read
                        .requestMatchers(HttpMethod.GET,  "/api/events/**").permitAll()
                        .requestMatchers(HttpMethod.GET,  "/api/questions").permitAll()
                        // Upload i photos — NOVO, mora biti PRIJE anyRequest
                        .requestMatchers(HttpMethod.POST, "/api/upload").authenticated()
                        .requestMatchers(HttpMethod.POST, "/api/users/me/photos").authenticated()
                        .requestMatchers(HttpMethod.GET,  "/api/users/me/photos").authenticated()
                        .requestMatchers(HttpMethod.DELETE, "/api/users/me/photos").authenticated()
                        .requestMatchers(HttpMethod.PUT,  "/api/company/auth/profile").authenticated()
                        // Sve ostalo
                        .anyRequest().authenticated()
                )
                .userDetailsService(userDetailsService)
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}