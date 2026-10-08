package com.example.busreservation.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * One row of the get_reservation_details() stored procedure (the JOIN).
 */
public record ReservationDetailsDto(
        Integer reservationId,
        String passengerName,
        String phone,
        String source,
        String destination,
        String busName,
        String busNumber,
        Integer seatNumber,
        LocalDateTime reservationDate,
        BigDecimal fare,
        String status) {
}
