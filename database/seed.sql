-- ============================================================================
-- Flight Booking System - Initial Seed Data (DML)
-- Target RDBMS: MySQL 8.0+
-- Populates required demo data as specified in Section 5 of Integration Guide.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Insert the 10 required demo airports
-- ----------------------------------------------------------------------------
INSERT INTO `Airport` (`iataCode`, `airportName`, `city`, `country`) VALUES
('JFK', 'John F. Kennedy International Airport', 'New York', 'United States'),
('LAX', 'Los Angeles International Airport', 'Los Angeles', 'United States'),
('ORD', 'O''Hare International Airport', 'Chicago', 'United States'),
('LHR', 'Heathrow Airport', 'London', 'United Kingdom'),
('CDG', 'Charles de Gaulle Airport', 'Paris', 'France'),
('FRA', 'Frankfurt Airport', 'Frankfurt', 'Germany'),
('IST', 'Istanbul Airport', 'Istanbul', 'Turkey'),
('DXB', 'Dubai International Airport', 'Dubai', 'United Arab Emirates'),
('AMM', 'Queen Alia International Airport', 'Amman', 'Jordan'),
('SIN', 'Singapore Changi Airport', 'Singapore', 'Singapore');

-- ----------------------------------------------------------------------------
-- 2. Insert the 3 seat classes with their price coefficients
-- ----------------------------------------------------------------------------
INSERT INTO `Class` (`classID`, `name`, `priceCoeff`) VALUES
('C1', 'Business', 2.50),
('C2', 'Premium Economy', 1.50),
('C3', 'Economy', 1.00);

-- ----------------------------------------------------------------------------
-- 3. Insert airplanes (120 seats capacity each)
-- ----------------------------------------------------------------------------
INSERT INTO `Airplane` (`airplaneID`, `model`, `capacity`) VALUES
('AP-0412', 'Airbus A320neo', 120),
('AP-0518', 'Boeing 737 MAX 8', 120),
('AP-0701', 'Airbus A321neo', 120);

-- ----------------------------------------------------------------------------
-- 4. Automatically generate 120 seats per airplane:
-- Rows 1 to 20, Columns A to F
-- Cabin layout:
--   Rows 1-3: Business (C1, coeff 2.50)
--   Rows 4-7: Premium Economy (C2, coeff 1.50)
--   Rows 8-20: Economy (C3, coeff 1.00)
-- ----------------------------------------------------------------------------
INSERT INTO `Seat` (`airplaneID`, `seatNumber`, `row`, `column`, `classID`)
SELECT
    a.`airplaneID`,
    CONCAT(r.row_num, c.col_char) AS `seatNumber`,
    r.row_num AS `row`,
    c.col_char AS `column`,
    CASE
        WHEN r.row_num BETWEEN 1 AND 3 THEN 'C1'
        WHEN r.row_num BETWEEN 4 AND 7 THEN 'C2'
        ELSE 'C3'
    END AS `classID`
FROM `Airplane` a
CROSS JOIN (
    SELECT 1 AS row_num UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
    SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL
    SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL
    SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
) r
CROSS JOIN (
    SELECT 'A' AS col_char UNION ALL SELECT 'B' UNION ALL SELECT 'C' UNION ALL
    SELECT 'D' UNION ALL SELECT 'E' UNION ALL SELECT 'F'
) c;

-- ----------------------------------------------------------------------------
-- 5. Insert flights
-- ----------------------------------------------------------------------------
INSERT INTO `Flight` (`flightID`, `flightNo`, `basePrice`, `airplaneID`, `originAirport`, `destinationAirport`) VALUES
('F690', 'FB 690', 270.00, 'AP-0412', 'JFK', 'LHR'),
('F214', 'FB 214', 140.00, 'AP-0518', 'JFK', 'ORD'),
('TA01', 'FB 101', 420.00, 'AP-0701', 'IST', 'JFK'),
('F305', 'FB 305', 190.00, 'AP-0412', 'LHR', 'CDG'),
('F812', 'FB 812', 510.00, 'AP-0518', 'DXB', 'SIN');

-- ----------------------------------------------------------------------------
-- 6. Insert flight offers (including default frontend search: JFK -> LHR on 2026-12-07)
-- ----------------------------------------------------------------------------
INSERT INTO `Offer` (`flightID`, `date`) VALUES
('F690', '2026-12-07'),
('F690', '2026-12-08'),
('F214', '2026-11-25'),
('F214', '2026-12-07'),
('TA01', '2026-12-07'),
('F305', '2026-12-07'),
('F812', '2026-12-09');

-- ----------------------------------------------------------------------------
-- 7. Insert default demo Customer and User account (username: mchen)
-- ----------------------------------------------------------------------------
INSERT INTO `Customer` (`customerID`, `fullName`, `email`, `role`) VALUES
(1, 'Maya Chen', 'maya.chen@example.com', 'Customer');

-- Ensure auto-increment starts after explicitly seeded customerID 1
ALTER TABLE `Customer` AUTO_INCREMENT = 2;

INSERT INTO `User` (`customerID`, `name`, `password`) VALUES
(1, 'mchen', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy');

-- ----------------------------------------------------------------------------
-- 8. Insert sample initial booking and ticket (Section 6 Integration Guide)
-- ----------------------------------------------------------------------------
INSERT INTO `Booking` (`pnr`, `bookingTime`, `status`, `userID`, `flightID`, `date`) VALUES
('K7Q2XM', '2026-11-11 16:52:00', 'Confirmed', 1, 'F214', '2026-11-25');

INSERT INTO `Ticket` (`ticketNumber`, `passportNo`, `ticketStatus`, `pnr`, `customerID`, `flightID`, `airplaneID`, `seatNumber`) VALUES
('TK-100482', 'P4829173', 'Issued', 'K7Q2XM', 1, 'F214', 'AP-0518', '12A');
