package com.example.busreservation.dto;

import java.math.BigDecimal;

public record FareResponse(Integer routeId, BigDecimal fare) {
}
