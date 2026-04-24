# Project Planning and Design Notes

## 1. Product Goal
Build an HR salary management platform that supports:
- Employee lifecycle management (create, update, delete, list, filter)
- Salary analytics and insights across country, department, and title
- Country-specific employee data capture via admin-defined custom fields
- Reliable local setup and deployability using Docker

Primary users:
- HR Manager: manages employee records and country custom fields
- Leadership/Analyst: consumes insights dashboard for compensation visibility

## 2. Scope Definition
In scope (current platform):
- Employee CRUD with validation
- Filtering, searching, sorting, pagination
- Insights APIs and dashboard visualizations
- Country-specific custom field definitions
- Dynamic employee form fields based on selected country
- Docker-based development and test execution

Out of scope (future phases):
- Authentication and role-based authorization
- Audit logs and change history
- Payroll processing and integrations
- File upload and document attachments
- Multi-currency compensation normalization
- Rate limiting and request throttling
- HTTPS/TLS enforcement (delegated to infrastructure)

In scope (current) – Security hardening:
- SQL injection prevention via parameterized queries and sort allowlisting
- Input sanitization for text fields and custom field values
- Email normalization and uniqueness enforcement
- SSRF: no outbound requests in current request paths
- Audit logging for sensitive operations (create, update, delete)
- Mass-assignment protection with strong parameters

In scope (current) – Bulk operations:
- CSV import with validation and error reporting
- CSV/XLSX export with filter support
- Custom field support in import/export

## 3. Architecture Overview
Frontend:
- Next.js App Router UI
- React Query for server-state caching and mutation invalidation
- Form handling using react-hook-form and zod

Backend:
- Rails API-only service
- ActiveRecord domain models and request-level JSON APIs
- Query objects for insights/static-data aggregation

Data layer:
- SQLite default for local and containerized operation
- Indexes on key query/filter columns
- JSON-like storage pattern for employee custom field values

Containerization:
- docker-compose orchestrates frontend, backend, and backend-test services
- Backend entrypoint runs migrate-and-seed workflow

## 4. Domain Design
Core entities:
- Employee: canonical HR profile and salary data
- CountryCustomField: HR-defined field metadata per country

Employee custom fields model:
- Field definitions are stored in country_custom_fields table
- Employee values are stored in employees.custom_fields as key-value JSON
- Validation rules:
  - Reject unknown keys for a selected country
  - Enforce required fields per country definition
  - Validate data type for number/date field types

Design intent:
- Keep employee table stable for global attributes
- Avoid schema churn when country-specific requirements evolve
- Let HR configure metadata without developer intervention

## 5. API Design Principles
General:
- Versioned namespace under /api/v1
- Consistent JSON response structure
- ActiveRecord exceptions mapped to standard API errors

Employee APIs:
- Employee payload includes custom_fields object
- Create/update accepts nested custom_fields
- Country-specific validation performed in model layer

Static metadata API:
- Returns countries, departments, job_titles, and grouped country_custom_fields
- Country list merges values from employees and country field definitions

Country custom field APIs:
- CRUD endpoints for HR-driven definition management
- Normalized field keys for safe storage and API use

## 6. Frontend UX Design Notes
Employees table:
- Keep fast scan/readability and inline actions (edit/delete)
- Provide filters and search with low-friction interactions

Employee modal:
- Render core fields first (global employee attributes)
- When country changes, render corresponding dynamic section
- Required country fields should be obvious and validated pre-submit

Country field management:
- Dedicated modal for add/list/delete country field definitions
- Keep HR workflow simple: country, label, type, placeholder, required

UX principle:
- Progressive disclosure. Advanced country-specific data appears only when relevant.

## 7. Quality and Testing Strategy
Backend:
- Request specs for API contracts and error cases
- Model specs for validation and domain rules
- FactoryBot data setup for reproducible tests

Frontend:
- Lint and type-check in Docker runtime
- Add component tests for dynamic field rendering and submit payloads
- Add integration tests for employee-create flow with custom fields

Test focus areas for next cycles:
- Country switching behavior while editing existing records
- Unknown-key rejection and required-field failures
- Delete behavior for field definitions in active use

## 8. Performance and Scalability Considerations
Current profile:
- Supports 10k+ employee records with indexed filters and aggregate queries
- Server-side pagination keeps payloads bounded

Potential pressure points:
- Growing custom_fields payload complexity
- Offset pagination for very large datasets
- Repeated static metadata reads

Planned evolution:
- Move to PostgreSQL for production scale
- Add caching layer for static metadata and insights
- Introduce keyset pagination for high-volume tables
- Add background jobs for heavy exports and long-running reports

## 9. Security and Compliance Notes
Current state:
- No auth and no row-level access controls
- No audit trail for salary or field-definition changes

Priority security roadmap:
1. Add authentication (session or token)
2. Add role-based authorization for HR actions
3. Add audit logging for compensation-impacting changes
4. Add rate limiting and stricter CORS policies
5. Add data retention and privacy controls

## 10. Delivery Roadmap
Phase 1 (complete):
- Employee CRUD, insights, Dockerized stack

Phase 2 (in progress):
- Country-specific custom fields (backend + frontend dynamic form + manager UI)

Phase 3:
- Harden UX for editing field definitions
- Add frontend automated tests
- Improve observability and error instrumentation

Phase 4:
- Auth + roles + audit logs
- Production-ready database and deployment hardening

## 11. Operational Playbook
Development:
- Use docker compose as default execution path
- Keep backend and frontend commands reproducible through containers

Database changes:
- Add migration
- Run migration in Docker backend
- Commit schema and migration together

Release hygiene:
- Run focused backend specs for changed areas
- Run frontend lint/type checks in Docker
- Document feature flags and rollout considerations for high-impact changes

## 12. Open Questions
- Should country custom field definitions allow edit of field_key after creation?
- Should deleting a field definition preserve historical employee values or clear them?
- Do we need per-country validation regex support (for IDs like PAN/SSN)?
- Should custom fields be included in list-table columns or details-only views?
- Should insights include aggregations by custom field values in the future?

## 13. Decision Log Template
Use this format for future architectural decisions:
- Decision:
- Date:
- Context:
- Options considered:
- Chosen option:
- Consequences:
- Follow-up actions:
