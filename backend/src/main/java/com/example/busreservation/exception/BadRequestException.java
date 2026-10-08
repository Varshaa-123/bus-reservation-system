package com.example.busreservation.exception;

/** Thrown when the input is invalid, e.g. a seat number out of range (HTTP 400). */
public class BadRequestException extends RuntimeException {

    public BadRequestException(String message) {
        super(message);
    }
}
