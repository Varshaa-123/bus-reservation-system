package com.example.busreservation.dto;

import java.math.BigDecimal;

/**
 * One row of the get_routes_above_average_bookings() stored procedure (the SUBQUERY).
 */
public record RouteAverageDto(
        Integer routeId,
        String source,
        String destination,
        String busName,
        Long bookingCount,
        BigDecimal averageBookingCount) {
}
