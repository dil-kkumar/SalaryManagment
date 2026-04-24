# Architecture & Design Decisions

## System Architecture

```
┌──────────────────────────────────────────────┐
│              Browser (HR Manager)             │
│           Next.js 14  –  Port 3000            │
│  ┌─────────────────┐  ┌────────────────────┐  │
│  │ /  Employees    │  │ /insights Dashboard│  │
│  │  Table + CRUD   │  │  Charts + Tables   │  │
│  └────────┬────────┘  └────────┬───────────┘  │
│           └──── TanStack Query ┘              │
└──────────────────┬───────────────────────────┘
                   │ REST / JSON
┌──────────────────▼───────────────────────────┐
│      Rails 7.1 API-only  –  Port 3001        │
│  ┌─────────────────┐  ┌────────────────────┐ │
│  │ /api/v1/        │  │ /api/v1/insights/  │ │
│  │  employees      │  │  salary_stats etc. │ │
│  └─────────────────┘  └────────────────────┘ │
│            ActiveRecord  +  SQLite            │
└──────────────────┬───────────────────────────┘
                   │
         SQLite file (salary.db)
         (persisted in Docker volume)
```

---

## Key Design Decisions

### 1. Rails API-only mode
- Removes view / asset pipeline layers → leaner image, faster boot
- Auto-generated routes via `resources` keep the controller surface minimal
- `rescue_from` in `ApplicationController` gives uniform error JSON without repetition

### 2. SQLite as the default database
- Zero-infra for local / Docker runs; single file, easy to back up
- Swappable: change `DATABASE_URL` + swap the adapter gem to move to PostgreSQL
- WAL mode enabled in `entrypoint.sh` → better concurrent read performance
- Composite indexes on `(country, job_title)` keep analytics queries fast

### 3. Next.js App Router
- Server Components handle layout / metadata (no JS shipped for static shells)
- Client Components used only where interactivity is needed (tables, modals, charts)
- `output: 'standalone'` produces a self-contained Node.js server for Docker

### 4. TanStack Query for data fetching
- `placeholderData: (prev) => prev` keeps the old table visible while new page loads (no flicker)
- `staleTime: 30s` reduces redundant requests for the same page
- Mutations call `invalidateQueries` → table auto-refreshes after add / edit / delete

### 5. Seed script performance
- Uses Rails `insert_all` (single SQL `INSERT` per batch of 500 rows)
- No ORM object allocation → O(n / batch_size) round-trips instead of O(n)
- Deterministic email ensures idempotent re-runs (`insert_all` skips duplicates)
- Typical time: **~1-2 seconds** for 10,000 rows on Apple M-series

### 6. Insights – SQL aggregation, not application-layer
- `MIN`, `MAX`, `AVG`, `COUNT` computed in SQLite → no 10k-row fetch to Ruby
- Single indexed query per insight endpoint

### 7. Security by Design
- **SQL injection prevention**: sort parameters validated against field allowlist; query objects use parameterized queries
- **Input sanitization**: text inputs trimmed and normalized in model layer; custom field validation enforces country scope
- **Email safety**: normalized to lowercase, unique constraint at DB layer, validated format in model
- **SSRF**: no outbound HTTP clients in current request flow; future integrations should use allowlisted endpoints
- **No hard-coded secrets**: database credentials via environment variables

---

## Employee Data Model

| Field | Type | Notes |
|-------|------|-------|
| id | INTEGER PK | Auto-increment |
| first_name | VARCHAR(100) | |
| last_name | VARCHAR(100) | |
| email | VARCHAR(255) UNIQUE | |
| job_title | VARCHAR(100) | Indexed |
| department | VARCHAR(100) | Indexed |
| country | VARCHAR(100) | Indexed |
| salary | DECIMAL(12,2) | Annual, USD |
| employment_type | VARCHAR(50) | full-time / part-time / contractor |
| hire_date | DATE | |
| status | VARCHAR(20) | active / inactive. Indexed |
| created_at / updated_at | TIMESTAMP | Rails-managed |

Composite index on `(country, job_title)` accelerates the `title_salary` insight query.

---

## Trade-offs

| Decision | Chosen | Alternative | Reason |
|----------|--------|-------------|--------|
| DB | SQLite | PostgreSQL | Zero-infra demo; prod swap trivial |
| Auth | None | JWT/OAuth | Out of scope |
| Realtime | None | WebSockets | Request/response sufficient for HR tool |
| Charts | Recharts | D3 / Victory | Works out of the box in React; no canvas complexity |
| Pagination | Offset-based | Keyset | Sufficient for ≤10k rows; simpler UI state |

---

## Scalability Path

1. **PostgreSQL** – swap `DATABASE_URL` + `pg` gem
2. **Read replica** – route insight queries to replica via multi-DB setup
3. **Keyset pagination** – consistent perf beyond 1M rows
4. **Redis cache** – TTL on `/insights/*` endpoints (read-heavy, infrequently changing)
5. **Background jobs** – heavy exports via Sidekiq/GoodJob

---

## Bulk Operations & Audit Trail

### CSV Import Service
- Parses CSV with strict header validation (required: first_name, last_name, email, job_title, department, country, salary, employment_type, hire_date, status)
- **Custom fields ignored**: Country-specific fields must be added manually after import
- Line-by-line validation with detailed error messages
- Automatic sanitization and type coercion (dates, salary numbers)
- Returns summary: successful imports + per-line errors

### File Export Service
- Generates CSV or XLSX with all employee fields + timestamps
- Respects query filters (country, department, status, search)
- XLSX formatting: header styling, column widths, auto-adjustment
- Timestamped filename for traceability

### Audit Logging
- Automatic tracking of create/update/delete operations on Employee and CountryCustomField
- Records: action type, attribute changes (before/after), timestamp, user context (future: auth integration)
- Audit logs indexed on auditable_type, action, created_at for fast queries
- JSON-serialized changes for flexible diff/forensics
