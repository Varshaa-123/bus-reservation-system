package com.example.busreservation.service;

import com.example.busreservation.entity.Bus;
import com.example.busreservation.repository.BusRepository;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class BusService {

    private final BusRepository busRepository;

    public BusService(BusRepository busRepository) {
        this.busRepository = busRepository;
    }

    public List<Bus> getAllBuses() {
        return busRepository.findAll();
    }
}
