-- ============================================================================
-- Flight Booking System - Core Reference & Verification Queries
-- Target RDBMS: MySQL 8.0+
-- Reference implementation for Backend integration and database verification.
-- ============================================================================

-- ============================================================================
-- 1. Search Offers by Origin, Destination, and Date
-- Maps to: GET /api/offers?dep=JFK&arr=LHR&date=2026-12-07
-- Returns available offers matching the criteria with full airport and aircraft info.
-- ============================================================================
SELECT
    o.`flightID`,
    o.`date`,
    f.`flightNo`,
    f.`basePrice`,
    ap.`airplaneID`,
    ap.`model`,
    ap.`capacity`,
    dep.`iataCode`    AS `dep_iataCode`,
    dep.`airportName` AS `dep_airportName`,
    dep.`city`        AS `dep_city`,
    dep.`country`     AS `dep_country`,
    arr.`iataCode`    AS `arr_iataCode`,
    arr.`airportName` AS `arr_airportName`,
    arr.`city`        AS `arr_city`,
    arr.`country`     AS `arr_country`
FROM `Offer` o
JOIN `Flight` f    ON o.`flightID` = f.`flightID`
JOIN `Airplane` ap ON f.`airplaneID` = ap.`airplaneID`
JOIN `Airport` dep ON f.`originAirport` = dep.`iataCode`
JOIN `Airport` arr ON f.`destinationAirport` = arr.`iataCode`
WHERE f.`originAirport` = 'JFK'
  AND f.`destinationAirport` = 'LHR'
  AND o.`date` = '2026-12-07';


-- ============================================================================
-- 2. Fetch the 120-Seat Map with Boolean Taken Status and Dynamic Price
-- Maps to: GET /api/offers/:flightID/:date/seats
-- Business Rule: Seat price is calculated dynamically (Flight.basePrice * Class.priceCoeff),
-- never stored.
-- Availability: taken = TRUE if an active ticket (ticketStatus <> 'Cancelled'
-- AND Booking.status <> 'Cancelled') occupies this seat for this offer.
-- ============================================================================
SELECT
    s.`seatNumber`,
    s.`row`,
    s.`column`,
    c.`classID`,
    c.`name` AS `className`,
    c.`priceCoeff`,
    ROUND(f.`basePrice` * c.`priceCoeff`, 2) AS `calculatedPrice`,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM `Ticket` t
            JOIN `Booking` b ON t.`pnr` = b.`pnr`
            WHERE b.`flightID` = f.`flightID`
              AND b.`date` = o.`date`
              AND t.`seatNumber` = s.`seatNumber`
              AND t.`ticketStatus` <> 'Cancelled'
              AND b.`status` <> 'Cancelled'
        ) THEN TRUE
        ELSE FALSE
    END AS `taken`
FROM `Offer` o
JOIN `Flight` f ON o.`flightID` = f.`flightID`
JOIN `Seat` s   ON f.`airplaneID` = s.`airplaneID`
JOIN `Class` c  ON s.`classID` = c.`classID`
WHERE o.`flightID` = 'F690'
  AND o.`date` = '2026-12-07'
ORDER BY s.`row` ASC, s.`column` ASC;


-- ============================================================================
-- 3. Passenger-to-Customer Resolution Pattern (MySQL Upsert with LAST_INSERT_ID)
-- Maps to: POST /api/bookings passenger processing
-- Business Rule: Each passenger must resolve to a Customer row by unique email:
--   - If email is new: Insert new Customer row with role = 'Customer'.
--   - If email exists: Reuse the existing customerID without duplicating.
--
-- The MySQL pattern below guarantees that LAST_INSERT_ID() holds the customerID
-- in both insert and duplicate scenarios.
-- ============================================================================

-- Step A: Upsert passenger into Customer table
INSERT INTO `Customer` (`fullName`, `email`, `role`)
VALUES ('Eleanor Vance', 'eleanor.vance@example.com', 'Customer')
ON DUPLICATE KEY UPDATE
    `customerID` = LAST_INSERT_ID(`customerID`),
    `fullName`   = VALUES(`fullName`);

-- Step B: Fetch the resolved customerID for creating the ticket
-- In application code, read the insertId from the execution result, or query:
SELECT LAST_INSERT_ID() AS `resolvedCustomerID`;


-- ============================================================================
-- 4. Verification & Testing: Double-Booking Trigger Rejection
-- Verifies: trg_prevent_double_booking on Ticket
-- ============================================================================

-- Step 4.1: Create a valid test booking
INSERT INTO `Booking` (`pnr`, `bookingTime`, `status`, `userID`, `flightID`, `date`)
VALUES ('TEST01', NOW(), 'Confirmed', 1, 'F690', '2026-12-07');

-- Step 4.2: First ticket booking for seat '2A' - MUST SUCCEED
INSERT INTO `Ticket` (`ticketNumber`, `passportNo`, `ticketStatus`, `pnr`, `customerID`, `flightID`, `airplaneID`, `seatNumber`)
VALUES ('TK-TEST-001', 'PASS-9871', 'Issued', 'TEST01', 1, 'F690', 'AP-0412', '2A');

-- Step 4.3: Create a second booking for another user / passenger
INSERT INTO `Booking` (`pnr`, `bookingTime`, `status`, `userID`, `flightID`, `date`)
VALUES ('TEST02', NOW(), 'Confirmed', 1, 'F690', '2026-12-07');

-- Step 4.4: Second ticket attempting to book the SAME seat ('2A') on the SAME flight & date
-- EXPECTED RESULT: FAILS with MySQL Error:
-- "ERROR 1644 (45000): Double-booking error: Seat is already booked for this flight and date."
-- UNCOMMENT TO TEST IN WORKBENCH / CLI:
-- INSERT INTO `Ticket` (`ticketNumber`, `passportNo`, `ticketStatus`, `pnr`, `customerID`, `flightID`, `airplaneID`, `seatNumber`)
-- VALUES ('TK-TEST-002', 'PASS-9999', 'Issued', 'TEST02', 1, 'F690', 'AP-0412', '2A');

-- Step 4.5: Verify cancellation releases the seat
-- If the first ticket is cancelled:
UPDATE `Ticket` SET `ticketStatus` = 'Cancelled' WHERE `ticketNumber` = 'TK-TEST-001';

-- Now booking seat '2A' again will SUCCEED:
INSERT INTO `Ticket` (`ticketNumber`, `passportNo`, `ticketStatus`, `pnr`, `customerID`, `flightID`, `airplaneID`, `seatNumber`)
VALUES ('TK-TEST-002', 'PASS-9999', 'Issued', 'TEST02', 1, 'F690', 'AP-0412', '2A');

-- Cleanup verification test rows
DELETE FROM `Ticket` WHERE `pnr` IN ('TEST01', 'TEST02');
DELETE FROM `Booking` WHERE `pnr` IN ('TEST01', 'TEST02');


-- ============================================================================
-- 5. Additional Reference Queries for Backend Team
-- ============================================================================

-- 5.1 Fetch All Bookings for Logged-In User (GET /api/bookings)
SELECT
    b.`pnr`,
    b.`bookingTime`,
    b.`status` AS `bookingStatus`,
    b.`flightID`,
    b.`date`   AS `flightDate`,
    f.`flightNo`,
    dep.`iataCode` AS `originCode`,
    dep.`city`     AS `originCity`,
    arr.`iataCode` AS `destCode`,
    arr.`city`     AS `destCity`,
    COUNT(t.`ticketNumber`) AS `ticketCount`
FROM `Booking` b
JOIN `Flight` f    ON b.`flightID` = f.`flightID`
JOIN `Airport` dep ON f.`originAirport` = dep.`iataCode`
JOIN `Airport` arr ON f.`destinationAirport` = arr.`iataCode`
LEFT JOIN `Ticket` t ON b.`pnr` = t.`pnr`
WHERE b.`userID` = 1
GROUP BY b.`pnr`, b.`bookingTime`, b.`status`, b.`flightID`, b.`date`,
         f.`flightNo`, dep.`iataCode`, dep.`city`, arr.`iataCode`, arr.`city`
ORDER BY b.`bookingTime` DESC;

-- 5.2 Fetch Detailed Booking with Passenger Tickets (GET /api/bookings/:pnr)
SELECT
    b.`pnr`,
    b.`bookingTime`,
    b.`status` AS `bookingStatus`,
    b.`flightID`,
    b.`date`   AS `flightDate`,
    f.`flightNo`,
    f.`basePrice`,
    dep.`iataCode`    AS `originCode`,
    dep.`airportName` AS `originAirport`,
    dep.`city`        AS `originCity`,
    arr.`iataCode`    AS `destCode`,
    arr.`airportName` AS `destAirport`,
    arr.`city`        AS `destCity`,
    t.`ticketNumber`,
    t.`passportNo`,
    t.`ticketStatus`,
    t.`seatNumber`,
    s.`row`,
    s.`column`,
    c.`name` AS `className`,
    ROUND(f.`basePrice` * c.`priceCoeff`, 2) AS `seatPrice`,
    cust.`fullName` AS `passengerName`,
    cust.`email`    AS `passengerEmail`
FROM `Booking` b
JOIN `Flight` f      ON b.`flightID` = f.`flightID`
JOIN `Airport` dep   ON f.`originAirport` = dep.`iataCode`
JOIN `Airport` arr   ON f.`destinationAirport` = arr.`iataCode`
JOIN `Ticket` t      ON b.`pnr` = t.`pnr`
JOIN `Customer` cust ON t.`customerID` = cust.`customerID`
JOIN `Seat` s        ON t.`airplaneID` = s.`airplaneID` AND t.`seatNumber` = s.`seatNumber`
JOIN `Class` c       ON s.`classID` = c.`classID`
WHERE b.`pnr` = 'K7Q2XM'
  AND b.`userID` = 1;
