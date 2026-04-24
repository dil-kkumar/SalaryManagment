# frozen_string_literal: true
# =============================================================================
# Seed script – generates 10,000 employees using bulk INSERT for performance.
#
# Performance strategy:
#   • Reads name lists once into memory (no I/O inside the loop).
#   • Generates all row hashes in plain Ruby (no ORM instantiation).
#   • Uses Employee.insert_all in batches of BATCH_SIZE rows, each batch
#     translating to a single SQL INSERT statement → O(n/batch) DB round-trips.
#   • On re-runs, skips rows whose email already exists (idempotent).
#
# Typical timing on a MacBook M1: ~1-2 seconds for 10k rows.
# =============================================================================

TARGET     = 10_000
BATCH_SIZE = 500

DEPARTMENTS = %w[
  Engineering Product Design Marketing Sales Finance HR Operations Legal Data
].freeze

JOB_TITLES = Employee::JOB_TITLES

COUNTRIES = %w[
  USA UK Canada Australia Germany France India Singapore Brazil
  Netherlands Sweden Japan UAE Spain Italy Poland Portugal Ireland
  Denmark Finland Mexico South_Korea New_Zealand
].freeze

EMPLOYMENT_TYPES = Employee::EMPLOYMENT_TYPES
STATUSES         = Employee::STATUSES

# Salary ranges loosely correlated with job title index (higher index → higher band)
BASE_SALARIES = Employee::JOB_TITLES.each_with_index.map { |_, i|
  40_000 + (i * 6_500)
}.freeze

puts "Seeding #{TARGET} employees…"
start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

first_names = Rails.root.join('data', 'first_names.txt').readlines(chomp: true).reject(&:empty?)
last_names  = Rails.root.join('data', 'last_names.txt').readlines(chomp: true).reject(&:empty?)

now = Time.now.utc

(TARGET / BATCH_SIZE).times do |batch|
  records = Array.new(BATCH_SIZE) do |i|
    idx        = batch * BATCH_SIZE + i
    first      = first_names[idx % first_names.size]
    last       = last_names[idx % last_names.size]
    title_idx  = idx % JOB_TITLES.size
    # Small salary variance per employee to create realistic distribution
    salary     = BASE_SALARIES[title_idx] + (idx % 20_001)

    {
      first_name:      first,
      last_name:       last,
      # Deterministic email ensures idempotent re-runs via on_duplicate: :skip
      email:           "#{first.downcase}.#{last.downcase}.#{idx}@company.internal",
      job_title:       JOB_TITLES[title_idx],
      department:      DEPARTMENTS[idx % DEPARTMENTS.size],
      country:         COUNTRIES[idx % COUNTRIES.size],
      salary:          salary,
      employment_type: EMPLOYMENT_TYPES[idx % EMPLOYMENT_TYPES.size],
      hire_date:       Date.new(2015, 1, 1) + (idx % (365 * 9)),
      status:          (idx % 10).zero? ? 'inactive' : 'active',
      employee_id:     format('EMP%06d', idx + 1),
      created_at:      now,
      updated_at:      now
    }
  end

  # insert_all skips rows that violate the unique constraint on email
  Employee.insert_all(records)

  print "." if ((batch + 1) % 4).zero?
end

elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
puts "\nDone! #{Employee.count} employees seeded in #{elapsed.round(2)}s"
