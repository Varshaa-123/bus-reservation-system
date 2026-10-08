package com.example.busreservation.repository;

import com.example.busreservation.dto.ReservationDetailsDto;
import com.example.busreservation.dto.ReservationResponse;
import com.example.busreservation.dto.RouteAverageDto;
import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

/**
 * This class does NOT contain business SQL logic.
 * It only CALLS the MySQL stored procedures and the MySQL function.
 */
@Repository
public class ReservationRepository {

    private final JdbcTemplate jdbcTemplate;

    public ReservationRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    /** Calls the stored procedure that contains the JOIN. */
    public List<ReservationDetailsDto> findAllReservationDetails() {
        return jdbcTemplate.query("CALL get_reservation_details()", (rs, rowNum) ->
                new ReservationDetailsDto(
                        rs.getInt("reservation_id"),
                        rs.getString("passenger_name"),
                        rs.getString("phone"),
                        rs.getString("source"),
                        rs.getString("destination"),
                        rs.getString("bus_name"),
                        rs.getString("bus_number"),
                        rs.getInt("seat_number"),
                        rs.getTimestamp("reservation_date").toLocalDateTime(),
                        rs.getBigDecimal("fare"),
                        rs.getString("status")));
    }

    /** Calls the stored procedure that contains the SUBQUERY. */
    public List<RouteAverageDto> findRoutesAboveAverage() {
        return jdbcTemplate.query("CALL get_routes_above_average_bookings()", (rs, rowNum) ->
                new RouteAverageDto(
                        rs.getInt("route_id"),
                        rs.getString("source"),
                        rs.getString("destination"),
                        rs.getString("bus_name"),
                        rs.getLong("booking_count"),
                        rs.getBigDecimal("average_booking_count")));
    }

    /** Calls the reserve_seat stored procedure. */
    public ReservationResponse reserveSeat(int passengerId, int routeId, int seatNumber) {
        List<ReservationResponse> results = jdbcTemplate.query(
                "CALL reserve_seat(?, ?, ?)", this::mapProcedureResult, passengerId, routeId, seatNumber);
        return firstResult(results);
    }

    /** Calls the cancel_reservation stored procedure. */
    public ReservationResponse cancelReservation(int reservationId) {
        List<ReservationResponse> results = jdbcTemplate.query(
                "CALL cancel_reservation(?)", this::mapProcedureResult, reservationId);
        return firstResult(results);
    }

    /** Calls the calculate_fare MySQL function. Returns null if the route does not exist. */
    public BigDecimal calculateFare(int routeId) {
        return jdbcTemplate.queryForObject("SELECT calculate_fare(?)", BigDecimal.class, routeId);
    }

    private ReservationResponse mapProcedureResult(ResultSet rs, int rowNum) throws SQLException {
        int id = rs.getInt("reservation_id");
        Integer reservationId = rs.wasNull() ? null : id;
        return new ReservationResponse(
                rs.getString("status"),
                rs.getString("message"),
                reservationId,
                rs.getBigDecimal("fare"));
    }

    private ReservationResponse firstResult(List<ReservationResponse> results) {
        if (results.isEmpty()) {
            throw new IllegalStateException("The stored procedure returned no result.");
        }
        return results.get(0);
    }
}
