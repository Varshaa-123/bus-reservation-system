package com.example.busreservation.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record ReservationRequest(
        @NotNull(message = "Passenger ID is required")
        @Positive(message = "Passenger ID must be a positive number")
        Integer passengerId,

        @NotNull(message = "Route ID is required")
        @Positive(message = "Route ID must be a positive number")
        Integer routeId,

        @NotNull(message = "Seat number is required")
        @Positive(message = "Seat number must be a positive number")
        Integer seatNumber) {
}
