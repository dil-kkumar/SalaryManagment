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
