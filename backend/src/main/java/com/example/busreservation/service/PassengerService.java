package com.example.busreservation.service;

import com.example.busreservation.dto.PassengerRequest;
import com.example.busreservation.entity.Passenger;
import com.example.busreservation.exception.ConflictException;
import com.example.busreservation.repository.PassengerRepository;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class PassengerService {

    private final PassengerRepository passengerRepository;

    public PassengerService(PassengerRepository passengerRepository) {
        this.passengerRepository = passengerRepository;
    }

    public List<Passenger> getAllPassengers() {
        return passengerRepository.findAll();
    }

    public Passenger createPassenger(PassengerRequest request) {
        String email = request.email().trim();
        String phone = request.phone().trim();

        if (passengerRepository.existsByEmail(email)) {
            throw new ConflictException("A passenger with email " + email + " already exists.");
        }
        if (passengerRepository.existsByPhone(phone)) {
            throw new ConflictException("A passenger with phone " + phone + " already exists.");
        }

        return passengerRepository.save(new Passenger(request.name().trim(), email, phone));
    }
}
