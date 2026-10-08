package com.example.busreservation.exception;

/** Thrown for duplicate seats, full buses, duplicate emails, etc. (HTTP 409). */
public class ConflictException extends RuntimeException {

    public ConflictException(String message) {
        super(message);
    }
}
