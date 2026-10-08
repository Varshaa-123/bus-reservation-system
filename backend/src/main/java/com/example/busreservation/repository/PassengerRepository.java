package com.example.busreservation.repository;

import com.example.busreservation.entity.Passenger;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PassengerRepository extends JpaRepository<Passenger, Integer> {

    boolean existsByEmail(String email);

    boolean existsByPhone(String phone);
}
