package com.example.busreservation.controller;

import com.example.busreservation.dto.FareResponse;
import com.example.busreservation.dto.RouteAverageDto;
import com.example.busreservation.entity.Route;
import com.example.busreservation.service.RouteService;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/routes")
public class RouteController {

    private final RouteService routeService;

    public RouteController(RouteService routeService) {
        this.routeService = routeService;
    }

    @GetMapping
    public List<Route> getAllRoutes() {
        return routeService.getAllRoutes();
    }

    /** Calls stored procedure get_routes_above_average_bookings() (SUBQUERY). */
    @GetMapping("/above-average")
    public List<RouteAverageDto> getRoutesAboveAverage() {
        return routeService.getRoutesAboveAverage();
    }

    /** Uses MySQL function calculate_fare(). */
    @GetMapping("/{routeId}/fare")
    public FareResponse calculateFare(@PathVariable("routeId") int routeId) {
        return routeService.calculateFare(routeId);
    }
}
