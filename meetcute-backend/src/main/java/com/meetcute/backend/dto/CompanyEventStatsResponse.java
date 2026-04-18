package com.meetcute.backend.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CompanyEventStatsResponse {
    private String eventId;
    private String title;
    private String eventDate;
    private Integer totalJoined;
    private Integer totalCancelled;
    private Integer maleCount;
    private Integer femaleCount;
    private Integer otherCount;
    private Integer age18_25;
    private Integer age26_35;
    private Integer age36_45;
    private Integer age45plus;
    private Double ticketPrice;
    private String ticketCurrency;
    private Double totalRevenue;
}