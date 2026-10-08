package com.example.busreservation.dto;

import java.math.BigDecimal;

/**
 * Result row returned by the reserve_seat and cancel_reservation procedures.
 */
public record ReservationResponse(
        String status,
        String message,
        Integer reservationId,
        BigDecimal fare) {
}
