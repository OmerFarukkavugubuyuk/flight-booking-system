# Flight Booking System - Database Layer (MySQL 8.0+)

This directory contains the complete SQL DDL, seed data, reference queries, and architectural constraints for the Flight Booking System.

---

## 1. Architectural Scope & Standards

- **Scope:** SQL / Database layer only. Application code (backend/frontend) must consume these scripts and queries without altering the schema or ER diagram attributes.
- **RDBMS Engine:** MySQL 8.0+ (InnoDB engine, UTF-8 `utf8mb4_unicode_ci`).
- **Language Policy:** 100% English across all SQL scripts, comments, error messages, and documentation.
- **ERD Fidelity:** Strict 1:1 adherence to the project ER diagram and `INTEGRATION_GUIDE.docx`. Attribute names (e.g., `passportNo`, `priceCoeff`, `iataCode`) are preserved exactly to guarantee seamless JSON serialization across backend APIs.

---

## 2. File Overview

| File | Purpose |
| :--- | :--- |
| [`schema.sql`](schema.sql) | DDL script defining all 10 tables, foreign key constraints, check constraints, and the `trg_prevent_double_booking` trigger. |
| [`seed.sql`](seed.sql) | DML script providing demo data: 10 airports, 3 seat classes, 3 airplanes with 120 auto-generated seats each, flights, offers (including JFK -> LHR on 2026-12-07), and demo user `mchen`. |
| [`queries.sql`](queries.sql) | Reference queries matching Backend API endpoints, passenger upsert pattern, and trigger verification tests. |
| [`README.md`](README.md) | This documentation and integration guide for the engineering team. |

---

## 3. Database Setup & Execution

### Prerequisites
- MySQL Server 8.0 or higher.
- A database created for the project (e.g., `flight_booking`).

```sql
CREATE DATABASE IF NOT EXISTS `flight_booking`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `flight_booking`;
```

### Method A: MySQL Command-Line Client (CLI)
Run the DDL and DML scripts in sequence:

```bash
# 1. Apply schema and triggers
mysql -u root -p flight_booking < database/schema.sql

# 2. Populate demo seed data
mysql -u root -p flight_booking < database/seed.sql

# 3. (Optional) Run reference queries and verification tests
mysql -u root -p flight_booking < database/queries.sql
```

### Method B: MySQL Workbench / GUI Clients (DBeaver, DataGrip)
1. Open [`database/schema.sql`](schema.sql) in MySQL Workbench.
2. Ensure the active schema is set to `flight_booking`.
3. Execute the entire script (**Ctrl+Shift+Enter**). Verify that all 10 tables and the trigger `trg_prevent_double_booking` are created without errors.
4. Open and execute [`database/seed.sql`](seed.sql).
5. Open [`database/queries.sql`](queries.sql) to run queries interactively.

### Method C: Docker
```bash
docker run --name mysql-flight-booking \
  -e MYSQL_ROOT_PASSWORD=secret \
  -e MYSQL_DATABASE=flight_booking \
  -p 3306:3306 \
  -d mysql:8.0

# Copy and execute schema and seed into container
docker exec -i mysql-flight-booking mysql -uroot -psecret flight_booking < database/schema.sql
docker exec -i mysql-flight-booking mysql -uroot -psecret flight_booking < database/seed.sql
```

---

## 4. Database Schema & Constraints

### 4.1 Table Catalog
1. **`Customer`**: Base entity for passengers and users. Enforces `UNIQUE` on `email`. `customerID` is `AUTO_INCREMENT`.
2. **`User`**: ISA specialization of `Customer`. Inherits `customerID` (foreign key `ON DELETE CASCADE`). Stores unique username and hashed password.
3. **`Airport`**: 3-letter IATA code primary key (e.g., `JFK`, `LHR`).
4. **`Airplane`**: Aircraft fleet records with capacity check (`capacity > 0`).
5. **`Class`**: Cabin tiers (`Business`, `Premium Economy`, `Economy`) and multiplier `priceCoeff`.
6. **`Seat`**: Weak entity identified by `(airplaneID, seatNumber)`. Represents physical seats on aircraft.
7. **`Flight`**: Scheduled flight route between origin and destination airports. Enforces `originAirport <> destinationAirport`.
8. **`Offer`**: Weak entity identified by `(flightID, date)`. Represents flight availability on a calendar date.
9. **`Booking`**: Reservation record with `pnr` primary key, status (`Confirmed`, `Pending`, `Cancelled`), linked to `User` and `Offer`.
10. **`Ticket`**: Individual passenger ticket with `ticketNumber` primary key, `passportNo`, linked to `Booking`, `Customer`, `Flight`, and physical `Seat`.

### 4.2 Reserved Words
MySQL reserved keywords are consistently escaped using backticks:
- `` `User` ``
- `` `row` ``
- `` `column` ``
- `` `date` ``

### 4.3 Safe Re-run Policy
`schema.sql` wraps table drops with:
```sql
SET FOREIGN_KEY_CHECKS = 0;
-- DROP TABLE statements...
SET FOREIGN_KEY_CHECKS = 1;
```
This guarantees clean teardown and reconstruction regardless of foreign key dependencies.

---

## 5. Critical Business Rules & SQL Implementation

### 5.1 Calculated Seat Price Rule
Seat price is **never stored** in the database. It is dynamically computed at query time:
$$\text{Calculated Price} = \text{Flight.basePrice} \times \text{Class.priceCoeff}$$
Example SQL expression:
```sql
ROUND(f.`basePrice` * c.`priceCoeff`, 2) AS `calculatedPrice`
```

### 5.2 Passenger-to-Customer Resolution Rule
When a user books tickets for passengers, each passenger's email must be resolved to a `Customer` record:
- If the email already exists in `Customer`, reuse that `customerID`.
- If the email is new, insert a new `Customer` record with `role = 'Customer'`.

To avoid race conditions and extra roundtrips, use the MySQL upsert pattern:
```sql
INSERT INTO `Customer` (`fullName`, `email`, `role`)
VALUES (?, ?, 'Customer')
ON DUPLICATE KEY UPDATE
    `customerID` = LAST_INSERT_ID(`customerID`),
    `fullName`   = VALUES(`fullName`);
```
Immediately following this execution, calling `LAST_INSERT_ID()` returns the correct `customerID` in both new and existing passenger scenarios.

### 5.3 Double-Booking Prevention Trigger
Enforced at the database level on table `Ticket` via:
```sql
CREATE TRIGGER `trg_prevent_double_booking`
BEFORE INSERT ON `Ticket`
FOR EACH ROW
...
```
- **Validation Logic:** Checks whether an active ticket (`ticketStatus <> 'Cancelled'` and `Booking.status <> 'Cancelled'`) already occupies the requested `seatNumber` on the same `flightID` and `date`.
- **Error Behavior:** If a conflict exists, it aborts the insertion and raises:
  ```text
  SQLSTATE '45000': Double-booking error: Seat is already booked for this flight and date.
  ```
- **Seat Release:** When a ticket or booking is marked as `'Cancelled'`, the trigger allows the seat to be re-booked without errors.

---

## 6. Back-end Integration Checklist

When implementing API routes in the backend service, ensure compliance with these points:

- [ ] **Transaction Demarcation (`POST /api/bookings`):**
  Wrap booking creation in a single ACID transaction (`START TRANSACTION` ... `COMMIT`):
  1. Generate unique 6-character PNR.
  2. Insert into `Booking` (`pnr`, `bookingTime`, `status`, `userID`, `flightID`, `date`).
  3. For each passenger ticket:
     - Execute the passenger upsert on `Customer` and retrieve `LAST_INSERT_ID()`.
     - Insert into `Ticket` (`ticketNumber`, `passportNo`, `ticketStatus`, `pnr`, `customerID`, `flightID`, `airplaneID`, `seatNumber`).
- [ ] **Double-Booking Error Handling:**
  Catch MySQL errors with `SQLSTATE 45000` or error code `1644` and return HTTP status `409 Conflict` with a clear message: `"Selected seat is already booked"`.
- [ ] **Prepared Statements:**
  Use parameterized queries for all inputs to eliminate SQL injection risks.
- [ ] **Password Security:**
  Verify user passwords against `User.password` using a secure hashing algorithm (e.g. bcrypt). Plaintext passwords must never be stored.
