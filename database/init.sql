-- =====================================================================
-- Bus Reservation System - database initialization script (MySQL 8.x)
-- Safe to run on a fresh database. Re-running it resets all data.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS bus_reservation;
USE bus_reservation;

DROP TABLE IF EXISTS reservations;
DROP TABLE IF EXISTS routes;
DROP TABLE IF EXISTS passengers;
DROP TABLE IF EXISTS buses;
DROP FUNCTION IF EXISTS calculate_fare;
DROP PROCEDURE IF EXISTS get_reservation_details;
DROP PROCEDURE IF EXISTS get_routes_above_average_bookings;
DROP PROCEDURE IF EXISTS reserve_seat;
DROP PROCEDURE IF EXISTS cancel_reservation;

CREATE TABLE buses (
    bus_id          INT AUTO_INCREMENT PRIMARY KEY,
    bus_number      VARCHAR(20)  NOT NULL UNIQUE,
    bus_name        VARCHAR(100) NOT NULL,
    total_seats     INT          NOT NULL,
    available_seats INT          NOT NULL,
    CONSTRAINT chk_total_seats     CHECK (total_seats > 0),
    CONSTRAINT chk_available_seats CHECK (available_seats >= 0 AND available_seats <= total_seats)
);

CREATE TABLE routes (
    route_id       INT AUTO_INCREMENT PRIMARY KEY,
    source         VARCHAR(60)   NOT NULL,
    destination    VARCHAR(60)   NOT NULL,
    departure_time TIME          NOT NULL,
    arrival_time   TIME          NOT NULL,
    fare           DECIMAL(10,2) NOT NULL,
    bus_id         INT           NOT NULL,
    CONSTRAINT uq_route_bus        UNIQUE (bus_id),
    CONSTRAINT chk_route_fare      CHECK (fare > 0),
    CONSTRAINT chk_route_cities    CHECK (source <> destination),
    CONSTRAINT fk_routes_bus       FOREIGN KEY (bus_id) REFERENCES buses (bus_id)
);

CREATE TABLE passengers (
    passenger_id INT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    email        VARCHAR(120) NOT NULL UNIQUE,
    phone        VARCHAR(15)  NOT NULL UNIQUE
);

-- confirmed_seat is a generated column: equals seat_number while CONFIRMED,
-- NULL when CANCELLED. UNIQUE (route_id, confirmed_seat) makes double-booking
-- impossible while a cancelled seat can be booked again.
CREATE TABLE reservations (
    reservation_id   INT AUTO_INCREMENT PRIMARY KEY,
    passenger_id     INT           NOT NULL,
    route_id         INT           NOT NULL,
    seat_number      INT           NOT NULL,
    reservation_date DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status           ENUM('CONFIRMED','CANCELLED') NOT NULL DEFAULT 'CONFIRMED',
    fare             DECIMAL(10,2) NOT NULL,
    confirmed_seat   INT GENERATED ALWAYS AS (IF(status = 'CONFIRMED', seat_number, NULL)) STORED,
    CONSTRAINT chk_seat_positive      CHECK (seat_number > 0),
    CONSTRAINT uq_route_confirmed_seat UNIQUE (route_id, confirmed_seat),
    CONSTRAINT fk_res_passenger FOREIGN KEY (passenger_id) REFERENCES passengers (passenger_id),
    CONSTRAINT fk_res_route     FOREIGN KEY (route_id)     REFERENCES routes (route_id)
);

INSERT INTO buses (bus_number, bus_name, total_seats, available_seats) VALUES
('TN01AB1234', 'Parveen Travels',    40, 40),
('TN02CD5678', 'SRS Express',        40, 40),
('TN03EF9012', 'KPN Travels',        45, 45),
('TN04GH3456', 'Orange Tours',       36, 36),
('TN05JK7890', 'VRL Travels',        40, 40),
('TN06LM2345', 'SETC Ultra Deluxe',  50, 50),
('TN07NP6789', 'Kallada Travels',    38, 38),
('TN08QR1234', 'National Travels',   42, 42);

INSERT INTO routes (source, destination, departure_time, arrival_time, fare, bus_id) VALUES
('Chennai',    'Madurai',     '21:30:00', '05:30:00', 550.00, 1),
('Chennai',    'Coimbatore',  '22:00:00', '06:00:00', 650.00, 2),
('Madurai',    'Tirunelveli', '07:00:00', '10:30:00', 250.00, 3),
('Coimbatore', 'Salem',       '09:00:00', '12:00:00', 200.00, 4),
('Trichy',     'Thanjavur',   '08:00:00', '09:30:00',  90.00, 5),
('Chennai',    'Pondicherry', '06:30:00', '10:00:00', 180.00, 6),
('Salem',      'Trichy',      '14:00:00', '17:00:00', 220.00, 7),
('Thanjavur',  'Chennai',     '20:30:00', '04:30:00', 480.00, 8);

INSERT INTO passengers (name, email, phone) VALUES
('Arun Kumar',         'arun.kumar@example.com',      '9876543210'),
('Priya Lakshmi',      'priya.lakshmi@example.com',   '9876543211'),
('Karthik Raja',       'karthik.raja@example.com',    '9876543212'),
('Divya Bharathi',     'divya.bharathi@example.com',  '9876543213'),
('Suresh Babu',        'suresh.babu@example.com',     '9876543214'),
('Meena Sundaram',     'meena.sundaram@example.com',  '9876543215'),
('Vignesh Ramesh',     'vignesh.ramesh@example.com',  '9876543216'),
('Anitha Selvam',      'anitha.selvam@example.com',   '9876543217'),
('Mohamed Rafi',       'mohamed.rafi@example.com',    '9876543218'),
('Lakshmi Narayanan',  'lakshmi.n@example.com',       '9876543219'),
('Revathi Devi',       'revathi.devi@example.com',    '9876543220');

DELIMITER $$

-- FUNCTION: base fare + 5% GST. NULL if route missing.
CREATE FUNCTION calculate_fare(p_route_id INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_base_fare DECIMAL(10,2);

    SET v_base_fare = (SELECT fare FROM routes WHERE route_id = p_route_id);

    IF v_base_fare IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN ROUND(v_base_fare + (v_base_fare * 0.05), 2);
END$$

-- TRIGGER 1 (guard): refuse a CONFIRMED reservation if the bus is full
CREATE TRIGGER trg_reservation_before_insert
BEFORE INSERT ON reservations
FOR EACH ROW
BEGIN
    DECLARE v_available INT;

    IF NEW.status = 'CONFIRMED' THEN
        SET v_available = (SELECT b.available_seats
                             FROM routes r
                             JOIN buses b ON b.bus_id = r.bus_id
                            WHERE r.route_id = NEW.route_id);

        IF v_available IS NOT NULL AND v_available <= 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No seats available';
        END IF;
    END IF;
END$$

-- TRIGGER 2 (mandatory): decrease available seats after a reservation
CREATE TRIGGER trg_reservation_after_insert
AFTER INSERT ON reservations
FOR EACH ROW
BEGIN
    IF NEW.status = 'CONFIRMED' THEN
        UPDATE buses
           SET available_seats = available_seats - 1
         WHERE bus_id = (SELECT bus_id FROM routes WHERE route_id = NEW.route_id)
           AND available_seats > 0;
    END IF;
END$$

-- TRIGGER 3 (cancellation): increase available seats when cancelled
CREATE TRIGGER trg_reservation_after_update
AFTER UPDATE ON reservations
FOR EACH ROW
BEGIN
    IF OLD.status = 'CONFIRMED' AND NEW.status = 'CANCELLED' THEN
        UPDATE buses
           SET available_seats = LEAST(total_seats, available_seats + 1)
         WHERE bus_id = (SELECT bus_id FROM routes WHERE route_id = NEW.route_id);
    END IF;
END$$

DELIMITER ;

-- 18 CONFIRMED + 1 CANCELLED. Fare from the function; seats via trigger.
INSERT INTO reservations (passenger_id, route_id, seat_number, fare, status) VALUES
(1,  1, 5,  calculate_fare(1), 'CONFIRMED'),
(2,  1, 6,  calculate_fare(1), 'CONFIRMED'),
(3,  1, 12, calculate_fare(1), 'CONFIRMED'),
(4,  1, 13, calculate_fare(1), 'CONFIRMED'),
(5,  2, 1,  calculate_fare(2), 'CONFIRMED'),
(6,  2, 2,  calculate_fare(2), 'CONFIRMED'),
(7,  2, 10, calculate_fare(2), 'CONFIRMED'),
(8,  2, 11, calculate_fare(2), 'CONFIRMED'),
(9,  3, 3,  calculate_fare(3), 'CONFIRMED'),
(10, 3, 4,  calculate_fare(3), 'CONFIRMED'),
(1,  4, 7,  calculate_fare(4), 'CONFIRMED'),
(2,  5, 8,  calculate_fare(5), 'CONFIRMED'),
(3,  5, 9,  calculate_fare(5), 'CONFIRMED'),
(4,  6, 15, calculate_fare(6), 'CONFIRMED'),
(5,  6, 16, calculate_fare(6), 'CONFIRMED'),
(6,  6, 20, calculate_fare(6), 'CONFIRMED'),
(7,  7, 14, calculate_fare(7), 'CONFIRMED'),
(8,  8, 21, calculate_fare(8), 'CONFIRMED'),
(9,  6, 12, calculate_fare(6), 'CANCELLED');

DELIMITER $$

-- FEATURE 1: JOIN across reservations, passengers, routes, buses
CREATE PROCEDURE get_reservation_details()
BEGIN
    SELECT res.reservation_id,
           p.name  AS passenger_name,
           p.phone AS phone,
           r.source,
           r.destination,
           b.bus_name,
           b.bus_number,
           res.seat_number,
           res.reservation_date,
           res.fare,
           res.status
      FROM reservations res
      JOIN passengers p ON p.passenger_id = res.passenger_id
      JOIN routes r     ON r.route_id     = res.route_id
      JOIN buses b      ON b.bus_id       = r.bus_id
     ORDER BY res.reservation_id;
END$$

-- FEATURE 2: SUBQUERY computes the average; nothing hard-coded
CREATE PROCEDURE get_routes_above_average_bookings()
BEGIN
    SELECT r.route_id,
           r.source,
           r.destination,
           b.bus_name,
           COUNT(res.reservation_id) AS booking_count,
           (SELECT ROUND(AVG(t.cnt), 2)
              FROM (SELECT COUNT(x.reservation_id) AS cnt
                      FROM routes r2
                      LEFT JOIN reservations x
                             ON x.route_id = r2.route_id AND x.status = 'CONFIRMED'
                     GROUP BY r2.route_id) AS t) AS average_booking_count
      FROM routes r
      JOIN buses b ON b.bus_id = r.bus_id
      LEFT JOIN reservations res
             ON res.route_id = r.route_id AND res.status = 'CONFIRMED'
     GROUP BY r.route_id, r.source, r.destination, b.bus_name
    HAVING COUNT(res.reservation_id) >
           (SELECT AVG(t2.cnt)
              FROM (SELECT COUNT(y.reservation_id) AS cnt
                      FROM routes r3
                      LEFT JOIN reservations y
                             ON y.route_id = r3.route_id AND y.status = 'CONFIRMED'
                     GROUP BY r3.route_id) AS t2)
     ORDER BY booking_count DESC, r.route_id;
END$$

-- FEATURE 3: reserve a seat. Always returns ONE row: status, message, reservation_id, fare
CREATE PROCEDURE reserve_seat(
    IN p_passenger_id INT,
    IN p_route_id     INT,
    IN p_seat_number  INT
)
proc: BEGIN
    DECLARE v_count       INT DEFAULT 0;
    DECLARE v_total_seats INT;
    DECLARE v_available   INT;
    DECLARE v_fare        DECIMAL(10,2);
    DECLARE v_new_id      INT;

    DECLARE EXIT HANDLER FOR 1062
    BEGIN
        ROLLBACK;
        SELECT 'SEAT_ALREADY_RESERVED' AS status,
               CONCAT('Seat ', p_seat_number, ' is already reserved for this route.') AS message,
               NULL AS reservation_id, NULL AS fare;
    END;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'ERROR' AS status,
               'Could not reserve the seat. Please try again.' AS message,
               NULL AS reservation_id, NULL AS fare;
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_count FROM passengers WHERE passenger_id = p_passenger_id;
    IF v_count = 0 THEN
        ROLLBACK;
        SELECT 'PASSENGER_NOT_FOUND' AS status,
               CONCAT('Passenger with ID ', p_passenger_id, ' does not exist.') AS message,
               NULL AS reservation_id, NULL AS fare;
        LEAVE proc;
    END IF;

    SELECT COUNT(*) INTO v_count FROM routes WHERE route_id = p_route_id;
    IF v_count = 0 THEN
        ROLLBACK;
        SELECT 'ROUTE_NOT_FOUND' AS status,
               CONCAT('Route with ID ', p_route_id, ' does not exist.') AS message,
               NULL AS reservation_id, NULL AS fare;
        LEAVE proc;
    END IF;

    -- Lock the bus row so two people cannot book at the same time
    SELECT b.total_seats, b.available_seats
      INTO v_total_seats, v_available
      FROM routes r
      JOIN buses b ON b.bus_id = r.bus_id
     WHERE r.route_id = p_route_id
       FOR UPDATE;

    IF p_seat_number IS NULL OR p_seat_number < 1 OR p_seat_number > v_total_seats THEN
        ROLLBACK;
        SELECT 'INVALID_SEAT' AS status,
               CONCAT('Invalid seat number. Seat must be between 1 and ', v_total_seats, '.') AS message,
               NULL AS reservation_id, NULL AS fare;
        LEAVE proc;
    END IF;

    SELECT COUNT(*) INTO v_count
      FROM reservations
     WHERE route_id = p_route_id
       AND seat_number = p_seat_number
       AND status = 'CONFIRMED';
    IF v_count > 0 THEN
        ROLLBACK;
        SELECT 'SEAT_ALREADY_RESERVED' AS status,
               CONCAT('Seat ', p_seat_number, ' is already reserved for this route.') AS message,
               NULL AS reservation_id, NULL AS fare;
        LEAVE proc;
    END IF;

    IF v_available <= 0 THEN
        ROLLBACK;
        SELECT 'NO_SEATS_AVAILABLE' AS status,
               'No seats available.' AS message,
               NULL AS reservation_id, NULL AS fare;
        LEAVE proc;
    END IF;

    SET v_fare = calculate_fare(p_route_id);

    INSERT INTO reservations (passenger_id, route_id, seat_number, fare, status)
    VALUES (p_passenger_id, p_route_id, p_seat_number, v_fare, 'CONFIRMED');

    SET v_new_id = LAST_INSERT_ID();

    COMMIT;

    SELECT 'SUCCESS' AS status,
           CONCAT('Seat ', p_seat_number, ' reserved successfully.') AS message,
           v_new_id AS reservation_id,
           v_fare   AS fare;
END$$

-- Optional: cancel a reservation (AFTER UPDATE trigger gives the seat back)
CREATE PROCEDURE cancel_reservation(IN p_reservation_id INT)
proc: BEGIN
    DECLARE v_count  INT DEFAULT 0;
    DECLARE v_status VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'ERROR' AS status,
               'Could not cancel the reservation. Please try again.' AS message,
               NULL AS reservation_id, NULL AS fare;
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_count FROM reservations WHERE reservation_id = p_reservation_id;
    IF v_count = 0 THEN
        ROLLBACK;
        SELECT 'RESERVATION_NOT_FOUND' AS status,
               CONCAT('Reservation with ID ', p_reservation_id, ' does not exist.') AS message,
               NULL AS reservation_id, NULL AS fare;
        LEAVE proc;
    END IF;

    SELECT status INTO v_status
      FROM reservations
     WHERE reservation_id = p_reservation_id
       FOR UPDATE;

    IF v_status = 'CANCELLED' THEN
        ROLLBACK;
        SELECT 'ALREADY_CANCELLED' AS status,
               CONCAT('Reservation ', p_reservation_id, ' is already cancelled.') AS message,
               NULL AS reservation_id, NULL AS fare;
        LEAVE proc;
    END IF;

    UPDATE reservations SET status = 'CANCELLED' WHERE reservation_id = p_reservation_id;

    COMMIT;

    SELECT 'SUCCESS' AS status,
           CONCAT('Reservation ', p_reservation_id, ' cancelled successfully.') AS message,
           p_reservation_id AS reservation_id,
           NULL AS fare;
END$$

DELIMITER ;
