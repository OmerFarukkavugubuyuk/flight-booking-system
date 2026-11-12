-- ============================================================================
-- Flight Booking System - Database Schema (DDL)
-- Target RDBMS: MySQL 8.0+
-- Strictly follows the ER Diagram and Integration Guide specifications.
-- ============================================================================

-- Disable foreign key checks for clean teardown of dependent tables
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `Ticket`;
DROP TABLE IF EXISTS `Booking`;
DROP TABLE IF EXISTS `Offer`;
DROP TABLE IF EXISTS `Flight`;
DROP TABLE IF EXISTS `Seat`;
DROP TABLE IF EXISTS `Class`;
DROP TABLE IF EXISTS `Airplane`;
DROP TABLE IF EXISTS `Airport`;
DROP TABLE IF EXISTS `User`;
DROP TABLE IF EXISTS `Customer`;

SET FOREIGN_KEY_CHECKS = 1;

-- ----------------------------------------------------------------------------
-- 1. Customer
-- Base entity for all individuals who purchase or hold tickets.
-- ----------------------------------------------------------------------------
CREATE TABLE `Customer` (
    `customerID` INT AUTO_INCREMENT PRIMARY KEY,
    `fullName`   VARCHAR(100) NOT NULL,
    `email`      VARCHAR(150) NOT NULL UNIQUE,
    `role`       VARCHAR(30)  NOT NULL DEFAULT 'Customer'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 2. User (ISA Customer specialization)
-- Registered user account with login credentials, inherits customerID.
-- ----------------------------------------------------------------------------
CREATE TABLE `User` (
    `customerID` INT PRIMARY KEY,
    `name`       VARCHAR(50)  NOT NULL UNIQUE,
    `password`   VARCHAR(255) NOT NULL, -- Stored as a secure cryptographic hash (e.g., bcrypt)
    CONSTRAINT `fk_user_customer`
        FOREIGN KEY (`customerID`) REFERENCES `Customer`(`customerID`)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 3. Airport
-- Airports identifiable by standard 3-letter IATA code.
-- ----------------------------------------------------------------------------
CREATE TABLE `Airport` (
    `iataCode`    CHAR(3)      PRIMARY KEY,
    `airportName` VARCHAR(150) NOT NULL,
    `city`        VARCHAR(100) NOT NULL,
    `country`     VARCHAR(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 4. Airplane
-- Physical aircraft models and their seat capacities.
-- ----------------------------------------------------------------------------
CREATE TABLE `Airplane` (
    `airplaneID` VARCHAR(20)  PRIMARY KEY,
    `model`      VARCHAR(100) NOT NULL,
    `capacity`   INT          NOT NULL CHECK (`capacity` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 5. Class
-- Cabin seating tiers with pricing multiplier coefficient.
-- ----------------------------------------------------------------------------
CREATE TABLE `Class` (
    `classID`    VARCHAR(10)   PRIMARY KEY,
    `name`       VARCHAR(50)   NOT NULL UNIQUE,
    `priceCoeff` DECIMAL(4, 2) NOT NULL CHECK (`priceCoeff` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 6. Seat (Weak Entity identified by Airplane)
-- Physical seat configuration within an airplane.
-- ----------------------------------------------------------------------------
CREATE TABLE `Seat` (
    `airplaneID` VARCHAR(20) NOT NULL,
    `seatNumber` VARCHAR(5)  NOT NULL,
    `row`        INT         NOT NULL,
    `column`     CHAR(1)     NOT NULL,
    `classID`    VARCHAR(10) NOT NULL,
    PRIMARY KEY (`airplaneID`, `seatNumber`),
    CONSTRAINT `fk_seat_airplane`
        FOREIGN KEY (`airplaneID`) REFERENCES `Airplane`(`airplaneID`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_seat_class`
        FOREIGN KEY (`classID`) REFERENCES `Class`(`classID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 7. Flight
-- Scheduled flight route between two distinct airports with an assigned aircraft.
-- ----------------------------------------------------------------------------
CREATE TABLE `Flight` (
    `flightID`           VARCHAR(20)    PRIMARY KEY,
    `flightNo`           VARCHAR(20)    NOT NULL,
    `basePrice`          DECIMAL(10, 2) NOT NULL CHECK (`basePrice` >= 0),
    `airplaneID`         VARCHAR(20)    NOT NULL,
    `originAirport`      CHAR(3)        NOT NULL,
    `destinationAirport` CHAR(3)        NOT NULL,
    CONSTRAINT `fk_flight_airplane`
        FOREIGN KEY (`airplaneID`) REFERENCES `Airplane`(`airplaneID`),
    CONSTRAINT `fk_flight_origin`
        FOREIGN KEY (`originAirport`) REFERENCES `Airport`(`iataCode`),
    CONSTRAINT `fk_flight_destination`
        FOREIGN KEY (`destinationAirport`) REFERENCES `Airport`(`iataCode`),
    CONSTRAINT `chk_different_airports`
        CHECK (`originAirport` <> `destinationAirport`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 8. Offer (Weak Entity identified by Flight)
-- A specific flight available on a specific calendar date.
-- ----------------------------------------------------------------------------
CREATE TABLE `Offer` (
    `flightID` VARCHAR(20) NOT NULL,
    `date`     DATE        NOT NULL,
    PRIMARY KEY (`flightID`, `date`),
    CONSTRAINT `fk_offer_flight`
        FOREIGN KEY (`flightID`) REFERENCES `Flight`(`flightID`)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 9. Booking
-- Reservation made by a registered User for an Offer.
-- ----------------------------------------------------------------------------
CREATE TABLE `Booking` (
    `pnr`         VARCHAR(10) PRIMARY KEY,
    `bookingTime` TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `status`      VARCHAR(20) NOT NULL DEFAULT 'Confirmed'
                  CHECK (`status` IN ('Confirmed', 'Pending', 'Cancelled')),
    `userID`      INT         NOT NULL,
    `flightID`    VARCHAR(20) NOT NULL,
    `date`        DATE        NOT NULL,
    CONSTRAINT `fk_booking_user`
        FOREIGN KEY (`userID`) REFERENCES `User`(`customerID`),
    CONSTRAINT `fk_booking_offer`
        FOREIGN KEY (`flightID`, `date`) REFERENCES `Offer`(`flightID`, `date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 10. Ticket
-- Individual passenger ticket tied to a booking, a passenger, and a physical seat.
-- ----------------------------------------------------------------------------
CREATE TABLE `Ticket` (
    `ticketNumber` VARCHAR(20) PRIMARY KEY,
    `passportNo`   VARCHAR(30) NOT NULL,
    `ticketStatus` VARCHAR(20) NOT NULL DEFAULT 'Issued'
                   CHECK (`ticketStatus` IN ('Issued', 'Cancelled')),
    `pnr`          VARCHAR(10) NOT NULL,
    `customerID`   INT         NOT NULL,
    `flightID`     VARCHAR(20) NOT NULL,
    `airplaneID`   VARCHAR(20) NOT NULL,
    `seatNumber`   VARCHAR(5)  NOT NULL,
    CONSTRAINT `fk_ticket_booking`
        FOREIGN KEY (`pnr`) REFERENCES `Booking`(`pnr`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_ticket_customer`
        FOREIGN KEY (`customerID`) REFERENCES `Customer`(`customerID`),
    CONSTRAINT `fk_ticket_flight`
        FOREIGN KEY (`flightID`) REFERENCES `Flight`(`flightID`),
    CONSTRAINT `fk_ticket_seat`
        FOREIGN KEY (`airplaneID`, `seatNumber`) REFERENCES `Seat`(`airplaneID`, `seatNumber`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- Trigger: trg_prevent_double_booking
-- Blocks active duplicate bookings for the same flight, date, and seat number.
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS `trg_prevent_double_booking`;

DELIMITER $$

CREATE TRIGGER `trg_prevent_double_booking`
BEFORE INSERT ON `Ticket`
FOR EACH ROW
BEGIN
    DECLARE v_flight_id VARCHAR(20);
    DECLARE v_flight_date DATE;
    DECLARE v_conflict_count INT DEFAULT 0;

    -- Fetch the target flightID and date from the associated Booking
    SELECT `flightID`, `date`
    INTO v_flight_id, v_flight_date
    FROM `Booking`
    WHERE `pnr` = NEW.`pnr`;

    -- Fallback to Ticket attributes if needed
    IF v_flight_id IS NULL THEN
        SET v_flight_id = NEW.`flightID`;
    END IF;

    -- Check if an active ticket already occupies this seat on the same flight and date
    IF NEW.`ticketStatus` <> 'Cancelled' THEN
        SELECT COUNT(*)
        INTO v_conflict_count
        FROM `Ticket` t
        JOIN `Booking` b ON t.`pnr` = b.`pnr`
        WHERE b.`flightID` = v_flight_id
          AND b.`date` = v_flight_date
          AND t.`seatNumber` = NEW.`seatNumber`
          AND t.`ticketStatus` <> 'Cancelled'
          AND b.`status` <> 'Cancelled';

        IF v_conflict_count > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Double-booking error: Seat is already booked for this flight and date.';
        END IF;
    END IF;
END$$

DELIMITER ;
