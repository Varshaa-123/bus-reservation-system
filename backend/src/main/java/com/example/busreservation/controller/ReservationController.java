package com.example.busreservation.controller;

import com.example.busreservation.dto.ReservationDetailsDto;
import com.example.busreservation.dto.ReservationRequest;
import com.example.busreservation.dto.ReservationResponse;
import com.example.busreservation.service.ReservationService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/reservations")
public class ReservationController {

    private final ReservationService reservationService;

    public ReservationController(ReservationService reservationService) {
        this.reservationService = reservationService;
    }

    /** Calls stored procedure get_reservation_details() (JOIN). */
    @GetMapping
    public List<ReservationDetailsDto> getAllReservations() {
        return reservationService.getAllReservations();
    }

    /** Calls stored procedure reserve_seat(). */
    @PostMapping
    public ResponseEntity<ReservationResponse> reserveSeat(@Valid @RequestBody ReservationRequest request) {
        ReservationResponse response = reservationService.reserveSeat(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /** Calls stored procedure cancel_reservation(). */
    @PostMapping("/{id}/cancel")
    public ReservationResponse cancelReservation(@PathVariable("id") int id) {
        return reservationService.cancelReservation(id);
    }
}
