# Salary Management Tool

A minimal yet production-ready salary management system for organizations with 10,000+ employees.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Ruby on Rails 7.1 (API mode) |
| Database | SQLite 3 (swappable to PostgreSQL) |
| Frontend | Next.js 14 (App Router) + TypeScript |
| UI Library | Tailwind CSS + TanStack Table |
| Charts | Recharts |
| Data Fetching | TanStack Query (React Query) |
| Testing | RSpec + FactoryBot + Shoulda-matchers |
| Deployment | Docker + Docker Compose |

## Project Structure

```
salary-management/
├── backend/                    # Rails 7.1 API
│   ├── app/
│   │   ├── controllers/api/v1/ # employees + insights controllers
│   │   └── models/             # Employee model + validations
│   ├── db/
│   │   ├── migrate/            # Schema migration
│   │   └── seeds.rb            # Bulk-insert seed (10k employees)
│   ├── spec/                   # RSpec tests
│   ├── first_names.txt
│   ├── last_names.txt
│   └── Dockerfile
├── frontend/                   # Next.js 14 app
│   ├── src/
│   │   ├── app/                # App Router pages (employees + insights)
│   │   ├── components/         # EmployeeTable, EmployeeModal, charts…
│   │   ├── lib/api.ts          # Typed API client
│   │   └── types/index.ts      # Shared TypeScript types
│   └── Dockerfile
├── docker-compose.yml
├── ARCHITECTURE.md
└── README.md
```

## Quick Start (Docker – recommended)

```bash
# Build and start both services
docker-compose up --build

# Backend API: http://localhost:3001
# Frontend UI:  http://localhost:3000
# Swagger docs: http://localhost:3001/api-docs  (if added)
```

> The backend automatically runs migrations and seeds 10,000 employees on first start.

## Local Development (without Docker)

### Backend

```bash
cd backend
bundle install
bundle exec rails db:create db:migrate db:seed
bundle exec rails server -p 3001
```

### Frontend

```bash
cd frontend
npm install
NEXT_PUBLIC_API_URL=http://localhost:3001 npm run dev
```

### Running Tests

```bash
cd backend
bundle exec rspec -f documentation
```

## API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/employees` | List with pagination, sort, filter, search |
| POST | `/api/v1/employees` | Create employee |
| GET | `/api/v1/employees/:id` | Get single employee |
| PUT | `/api/v1/employees/:id` | Update employee (partial) |
| DELETE | `/api/v1/employees/:id` | Delete employee |
| GET | `/api/v1/insights/summary` | Org KPIs + filter metadata |
| GET | `/api/v1/insights/salary_stats` | Min/Max/Avg by country |
| GET | `/api/v1/insights/title_salary` | Avg salary by title + country |
| GET | `/api/v1/insights/department_stats` | Headcount & avg salary by department |
| GET | `/api/v1/insights/top_earners` | Top N earners |
| GET | `/api/v1/insights/salary_distribution` | Salary band histogram |
| GET | `/health` | Health check |
| POST | `/api/v1/employees/import` | Bulk import employees from CSV |
| GET | `/api/v1/employees/export` | Export employees as CSV or XLSX (supports filters) |

## Bulk Import/Export

### Import Employees from CSV
- Upload CSV file with employee data (headers: first_name, last_name, email, job_title, department, country, salary, employment_type, hire_date, status)
- **Note**: Country-specific custom fields are ignored during bulk import. Add them manually after import via the "Manage Country Fields" UI.
- Returns success count and detailed error messages for failed rows
- HR Manager can access via "Import" button on Employees table

### Export Employees
- Download employee data as CSV or XLSX
- Export respects all active filters (country, department, status, search)
- Files are timestamped (employees_YYYYMMDD_HHMMSS.csv|xlsx)
- HR Manager can access via "CSV" or "Excel" buttons on Employees table

## Audit Logging

- All sensitive operations (create, update, delete) on employees and country custom fields are logged
- Audit logs include: action type, changed values (before/after), timestamp, and IP address
- Audit logs stored in database for compliance and forensics
- See `audit_logs` table for full history

## Security

### Input Protection
- Query parameters for sorting are validated against an allowlist to prevent SQL injection
- All text inputs (name, email, custom fields) are sanitized to remove leading/trailing whitespace and normalize to safe formats
- Email addresses are normalized to lowercase for case-insensitive uniqueness enforcement
- Mass-assignment protection prevents unauthorized field modification

### Model-Level Validation
- Employee and custom-field create/update operations validate field presence, type, and format
- Custom field values are scoped by country, preventing injection of unknown fields
- Email addresses must be unique and valid format

### Not in Scope (Current)
- Authentication & authorization (out of scope)
- Rate limiting (recommended for production)
- HTTPS enforcement (handle at reverse proxy / load balancer)
