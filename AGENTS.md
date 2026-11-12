# AGENTS.md - Flight Booking System Source of Truth

## 1. Agent Role & Scope of Responsibilities
- **Assigned Role:** Database / SQL Engineer.
- **RDBMS Engine:** MySQL 8.0+.
- **Scope Restriction:** Responsibilities are strictly scoped to the **SQL / Database layer only** (`database/` directory).
- **Prohibited Actions:** Do NOT scaffold, modify, or create files in `backend/` or `frontend/`. Architectural handover to backend and frontend teams is provided via SQL definitions, seed datasets, reference queries, and documentation in `database/`.

---

## 2. Core Architectural Rules

### 2.1 Language Policy
- **100% English:** Every file, SQL identifier, table name, column name, trigger, stored logic, error message, code comment, documentation, and Git commit message must be written strictly in English.

### 2.2 Schema Fidelity & Integrity
- **Exact ER Diagram Fidelity:** All entity and attribute names must strictly match the ER diagram and `INTEGRATION_GUIDE.docx` with zero arbitrary renames.
- **Tables & Primary Keys:**
  1. `Customer` (`customerID` INT AUTO_INCREMENT PRIMARY KEY)
  2. `User` (`customerID` INT PRIMARY KEY, ISA `Customer`)
  3. `Airport` (`iataCode` CHAR(3) PRIMARY KEY)
  4. `Airplane` (`airplaneID` VARCHAR(20) PRIMARY KEY)
  5. `Class` (`classID` VARCHAR(10) PRIMARY KEY)
  6. `Seat` (`airplaneID`, `seatNumber` COMPOSITE PRIMARY KEY, weak entity of `Airplane`)
  7. `Flight` (`flightID` VARCHAR(20) PRIMARY KEY)
  8. `Offer` (`flightID`, `date` COMPOSITE PRIMARY KEY, weak entity of `Flight`)
  9. `Booking` (`pnr` VARCHAR(10) PRIMARY KEY)
  10. `Ticket` (`ticketNumber` VARCHAR(20) PRIMARY KEY)
- **MySQL Reserved Keywords:** All reserved words must always be escaped using MySQL backticks:
  - `` `User` ``
  - `` `row` ``
  - `` `column` ``
  - `` `date` ``
- **DDL Execution Cleanliness:** Always wrap table drops with `SET FOREIGN_KEY_CHECKS = 0;` and `SET FOREIGN_KEY_CHECKS = 1;`.

### 2.3 Passenger-to-Customer Resolution Rule
- `Customer.email` has a `UNIQUE` constraint.
- When booking tickets for passengers:
  - If a passenger's email already exists in `Customer`, reuse their existing `customerID`.
  - If a passenger's email does not exist, insert a new row in `Customer` with `role = 'Customer'`.
- The canonical MySQL upsert pattern must be used:
  ```sql
  INSERT INTO `Customer` (`fullName`, `email`, `role`)
  VALUES (?, ?, 'Customer')
  ON DUPLICATE KEY UPDATE
      `customerID` = LAST_INSERT_ID(`customerID`);
  ```
  Calling `LAST_INSERT_ID()` immediately yields the resolved `customerID` for subsequent `Ticket` inserts.

### 2.4 Double-Booking Prevention Rule
- Enforced at the database level via a MySQL `BEFORE INSERT` trigger (`trg_prevent_double_booking`) on the `Ticket` table.
- A seat is considered occupied/taken if there is any active ticket (`ticketStatus <> 'Cancelled'` and `Booking.status <> 'Cancelled'`) for the same `flightID`, `date`, and `seatNumber`.
- If a collision is detected on insert, the trigger signals `SQLSTATE '45000'` with the message:
  `'Double-booking error: Seat is already booked for this flight and date.'`
- Cancelled tickets or bookings release the seat, allowing re-booking without conflict.

### 2.5 Business Rules
- **Calculated Seat Price:** Seat price is dynamic (`Flight.basePrice * Class.priceCoeff`). It is calculated on demand in queries and must never be stored in the database.
- **Passwords:** Passwords in `` `User` `` must always be stored as secure cryptographic hashes, never plaintext.
- **Seat Map Standard:** Every demo airplane contains 120 seats: Rows 1–20, Columns A–F.
  - Rows 1–3: Business (`C1`, coefficient 2.50)
  - Rows 4–7: Premium Economy (`C2`, coefficient 1.50)
  - Rows 8–20: Economy (`C3`, coefficient 1.00)

---

## 3. Directory Structure & File Ownership
```text
flight-booking-system/
├── AGENTS.md               # Architectural source of truth (this file)
├── README.md               # Repository overview
├── docs/
│   └── INTEGRATION_GUIDE.docx # Upstream specifications and ER diagram
└── database/
    ├── schema.sql          # MySQL 8.0+ DDL and triggers
    ├── seed.sql            # Demo seed data (airports, classes, airplanes, seats, offers, demo user)
    ├── queries.sql         # Reference SQL queries for backend integration
    └── README.md           # Database setup and developer documentation
```
