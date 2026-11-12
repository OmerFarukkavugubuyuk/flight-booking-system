# Contributing Guidelines - Flight Booking System

Thank you for contributing to the Flight Booking System project. To maintain high code quality, consistent database integrity, and smooth collaboration across teams (SQL/Database, Backend, and Frontend), all contributors must adhere to the workflow and standards outlined below.

---

## 1. Core Principles

- **Language Policy:** 100% English. All code, SQL identifiers, table/column names, comments, error messages, branch names, commit messages, pull requests, and documentation must be written strictly in English.
- **Strict Architectural Scoping:**
  - Database engineers focus strictly on the `database/` layer.
  - Backend and frontend teams integrate using documented SQL contracts, APIs, and schemas without making unauthorized schema modifications.
- **Main Branch Protection:** Never commit directly to `main` after initial repository setup. All changes must go through a dedicated branch and pull request review.

---

## 2. Branching Strategy

All work must be developed on a dedicated branch branched off the latest `main` branch:

```bash
git checkout main
git pull origin main
git checkout -b <branch-type>/<short-description>
```

### Branch Naming Conventions
Use descriptive, lowercase, kebab-case branch names prefixed by category:

| Prefix | Description | Example |
| :--- | :--- | :--- |
| `feat/` | New features, database schemas, or API endpoints | `feat/database-schema`, `feat/api-endpoints`, `feat/frontend-integration` |
| `fix/` | Bug fixes or trigger/constraint corrections | `fix/double-booking-trigger`, `fix/seat-price-calc` |
| `docs/` | Documentation additions or updates | `docs/sql-setup-guide`, `docs/contributing-guidelines` |
| `refactor/` | Code refactoring without changing functionality | `refactor/sql-queries`, `refactor/seed-cleanup` |
| `test/` | Adding or updating verification tests | `test/double-booking-cases` |

---

## 3. Commit Message Standards

We strictly follow the [Conventional Commits](https://www.conventionalcommits.org/) specification in English.

### Format
```text
<type>(<optional-scope>): <description>

[optional body]

[optional footer(s)]
```

### Commit Types
- `feat`: A new feature (e.g., new tables, queries, endpoints).
- `fix`: A bug fix (e.g., correcting a trigger condition or query constraint).
- `docs`: Documentation only changes.
- `chore`: Maintenance, repository setup, configuration updates.
- `refactor`: Code changes that neither fix a bug nor add a feature.
- `test`: Adding or updating verification scripts/tests.

### Examples
- `feat(database): add MySQL 8.0 schema, double-booking trigger, seed data, and queries`
- `fix(sql): correct double-booking check condition for cancelled bookings`
- `docs: update integration checklist in database README`
- `chore: initialize repository structure, agent rules, and contributing guidelines`

---

## 4. Pull Request & Merge Workflow

1. **Keep Branches Up-to-Date:** Regularly rebase or merge `main` into your feature branch to prevent merge conflicts.
2. **Local Verification:**
   - For SQL/Database changes: Verify that `schema.sql` runs cleanly from scratch (`SET FOREIGN_KEY_CHECKS = 0/1`), `seed.sql` populates all data without errors, and test queries in `queries.sql` pass (especially the `trg_prevent_double_booking` trigger test).
3. **Push to Remote:**
   ```bash
   git push -u origin <branch-name>
   ```
4. **Open a Pull Request (PR):**
   - Provide a clear title following Conventional Commits format.
   - Describe the purpose of the changes, verification steps performed, and any impact on other layers (backend/frontend).
5. **Peer Review:**
   - At least one code review approval is required before merging.
   - Address all feedback and push revisions to the same branch.
6. **Squash and Merge:**
   - Squash and merge into `main` with a clean commit message.
   - Delete the remote and local feature branch after merging.
