package com.example.busreservation.service;

import com.example.busreservation.dto.FareResponse;
import com.example.busreservation.dto.RouteAverageDto;
import com.example.busreservation.entity.Route;
import com.example.busreservation.exception.ResourceNotFoundException;
import com.example.busreservation.repository.ReservationRepository;
import com.example.busreservation.repository.RouteRepository;
import java.math.BigDecimal;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class RouteService {

    private final RouteRepository routeRepository;
    private final ReservationRepository reservationRepository;

    public RouteService(RouteRepository routeRepository, ReservationRepository reservationRepository) {
        this.routeRepository = routeRepository;
        this.reservationRepository = reservationRepository;
    }

    public List<Route> getAllRoutes() {
        return routeRepository.findAll();
    }

    public List<RouteAverageDto> getRoutesAboveAverage() {
        return reservationRepository.findRoutesAboveAverage();
    }

    /** Fare is calculated by the MySQL function calculate_fare(). */
    public FareResponse calculateFare(int routeId) {
        BigDecimal fare = reservationRepository.calculateFare(routeId);
        if (fare == null) {
            throw new ResourceNotFoundException("Route with ID " + routeId + " does not exist.");
        }
        return new FareResponse(routeId, fare);
    }
}
