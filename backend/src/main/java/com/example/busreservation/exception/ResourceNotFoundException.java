package com.example.busreservation.exception;

/** Thrown when a passenger, route or reservation does not exist (HTTP 404). */
public class ResourceNotFoundException extends RuntimeException {

    public ResourceNotFoundException(String message) {
        super(message);
    }
}
