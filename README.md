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
