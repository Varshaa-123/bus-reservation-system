package com.example.busreservation.service;

import com.example.busreservation.dto.ReservationDetailsDto;
import com.example.busreservation.dto.ReservationRequest;
import com.example.busreservation.dto.ReservationResponse;
import com.example.busreservation.exception.BadRequestException;
import com.example.busreservation.exception.ConflictException;
import com.example.busreservation.exception.ResourceNotFoundException;
import com.example.busreservation.repository.ReservationRepository;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class ReservationService {

    private final ReservationRepository reservationRepository;

    public ReservationService(ReservationRepository reservationRepository) {
        this.reservationRepository = reservationRepository;
    }

    public List<ReservationDetailsDto> getAllReservations() {
        return reservationRepository.findAllReservationDetails();
    }

    /**
     * Calls the reserve_seat procedure and converts its status code into
     * the right HTTP error (or returns the success result).
     */
    public ReservationResponse reserveSeat(ReservationRequest request) {
        ReservationResponse result = reservationRepository.reserveSeat(
                request.passengerId(), request.routeId(), request.seatNumber());

        return switch (result.status()) {
            case "SUCCESS" -> result;
            case "PASSENGER_NOT_FOUND", "ROUTE_NOT_FOUND" -> throw new ResourceNotFoundException(result.message());
            case "INVALID_SEAT" -> throw new BadRequestException(result.message());
            case "SEAT_ALREADY_RESERVED", "NO_SEATS_AVAILABLE" -> throw new ConflictException(result.message());
            default -> throw new IllegalStateException(result.message());
        };
    }

    public ReservationResponse cancelReservation(int reservationId) {
        ReservationResponse result = reservationRepository.cancelReservation(reservationId);

        return switch (result.status()) {
            case "SUCCESS" -> result;
            case "RESERVATION_NOT_FOUND" -> throw new ResourceNotFoundException(result.message());
            case "ALREADY_CANCELLED" -> throw new ConflictException(result.message());
            default -> throw new IllegalStateException(result.message());
        };
    }
}
