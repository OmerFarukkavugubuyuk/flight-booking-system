# Flight Booking System

A full-stack flight reservation system built around a relational database schema (MySQL 8.0+), RESTful API, and vanilla JavaScript SPA front-end. :)

---

## 1. Project Structure

```text
flight-booking-system/
├── AGENTS.md               # Architectural source of truth and SQL layer scoping
├── CONTRIBUTING.md         # Team branching model, commit standards, and PR workflow
├── README.md               # Repository overview and setup guide
├── docs/
│   └── INTEGRATION_GUIDE.docx # Upstream specifications and ER diagram
└── database/
    ├── schema.sql          # MySQL 8.0+ DDL and triggers
    ├── seed.sql            # Demo seed data (airports, classes, airplanes, seats, offers, demo user)
    ├── queries.sql         # Reference SQL queries for backend integration
    └── README.md           # Database setup and developer documentation
```

---

## 2. Database Setup (MySQL 8.0+)

1. Create the MySQL database:
   ```sql
   CREATE DATABASE IF NOT EXISTS `flight_booking`
     CHARACTER SET utf8mb4
     COLLATE utf8mb4_unicode_ci;
   USE `flight_booking`;
   ```
2. Run `database/schema.sql` to create all 10 relational tables, foreign key constraints, and the `trg_prevent_double_booking` trigger.
3. Run `database/seed.sql` to populate initial demo data (10 airports, 3 classes, 3 airplanes with 120 auto-generated seats each, flights, offers, and demo user).
4. See [`database/README.md`](database/README.md) for detailed setup instructions and query references.

---

## 3. Contributing & Team Workflow

All team members must follow our Git branching model, Conventional Commits standard, and code review process before merging code into `main`.

Please review **[`CONTRIBUTING.md`](CONTRIBUTING.md)** before opening pull requests.

---

## 4. Specifications & Architecture

- **Specifications & ER Model:** Refer to [`docs/INTEGRATION_GUIDE.docx`](docs/INTEGRATION_GUIDE.docx).
- **Architectural Rules:** Refer to [`AGENTS.md`](AGENTS.md).
