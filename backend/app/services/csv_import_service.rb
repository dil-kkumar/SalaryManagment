# frozen_string_literal: true
require 'csv'

class CsvImportService
  # Expected headers in CSV (case-insensitive)
  # Custom fields are ignored during bulk import - HR can add them manually after import
  REQUIRED_HEADERS = %w[first_name last_name email job_title department country salary employment_type hire_date status].freeze
  TEXT_FIELD_RULES = {
    first_name: { max_length: 100 },
    last_name: { max_length: 100 },
    email: { max_length: 255, downcase: true },
    job_title: { max_length: 100 },
    department: { max_length: 100 },
    country: { max_length: 100 },
    employment_type: { max_length: 50 },
    status: { max_length: 50 }
  }.freeze
  CONTROL_CHAR_REGEX = /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/.freeze

  attr_reader :file, :results

  def initialize(file)
    @file = file
    @results = { success: [], errors: [] }
  end

  def call
    parse_csv
    results
  end

  private

  def parse_csv
    raw_csv = File.read(file.path, encoding: 'bom|utf-8')
    csv_data = CSV.parse(raw_csv, headers: true, header_converters: :symbol)

    if csv_data.headers.nil?
      results[:errors] << 'CSV file is empty'
      return
    end

    validate_headers(csv_data.headers)
    return if results[:errors].any?

    csv_data.each_with_index do |row, index|
      import_employee(row, index + 2) # +2 because index is 0-based and we want to skip header
    end
  end

  def validate_headers(headers)
    required_present = REQUIRED_HEADERS.all? { |h| headers.include?(h.to_sym) }
    return if required_present

    missing = REQUIRED_HEADERS - headers.map(&:to_s)
    results[:errors] << "Missing required headers: #{missing.join(', ')}"
  end

  def import_employee(row, line_number)
    begin
      reject_control_characters!(row, line_number)
      employee_params = build_employee_params(row)
      employee = Employee.create!(employee_params)
      results[:success] << { id: employee.id, email: employee.email, line: line_number }
    rescue ActiveRecord::RecordInvalid => e
      results[:errors] << "Line #{line_number}: #{e.record.errors.full_messages.join(', ')}"
    rescue StandardError => e
      results[:errors] << "Line #{line_number}: #{e.message}"
    end
  end

  def build_employee_params(row)
    # Note: custom_fields are ignored during bulk import
    # HR managers should add country-specific custom fields manually after import
    params = {
      first_name: sanitize_text(row[:first_name], **TEXT_FIELD_RULES[:first_name]),
      last_name: sanitize_text(row[:last_name], **TEXT_FIELD_RULES[:last_name]),
      email: sanitize_text(row[:email], **TEXT_FIELD_RULES[:email]),
      job_title: sanitize_text(row[:job_title], **TEXT_FIELD_RULES[:job_title]),
      department: sanitize_text(row[:department], **TEXT_FIELD_RULES[:department]),
      country: sanitize_text(row[:country], **TEXT_FIELD_RULES[:country]),
      salary: parse_salary(row[:salary]),
      employment_type: sanitize_text(row[:employment_type], **TEXT_FIELD_RULES[:employment_type]),
      hire_date: parse_date(row[:hire_date]),
      status: sanitize_text(row[:status], **TEXT_FIELD_RULES[:status])
    }

    params.compact
  end

  def parse_salary(value)
    return nil if value.blank?

    Float(value)
  rescue ArgumentError, TypeError
    raise ArgumentError, 'salary must be a valid number'
  end

  def parse_date(value)
    return nil if value.blank?

    raw = value.to_s.strip

    return Date.iso8601(raw) if raw.match?(/\A\d{4}-\d{2}-\d{2}\z/)

    if raw.match?(/\A\d{1,2}\/\d{1,2}\/\d{4}\z/)
      return Date.strptime(raw, '%m/%d/%Y')
    end

    if raw.match?(/\A\d{1,2}\/\d{1,2}\/\d{2}\z/)
      parsed = Date.strptime(raw, '%m/%d/%y')
      year = parsed.year
      normalized_year = year < 100 ? year + 2000 : year
      return Date.new(normalized_year, parsed.month, parsed.day)
    end

    raise ArgumentError,
          "hire_date must be in YYYY-MM-DD or M/D/YY (or M/D/YYYY) format, got: #{value}"
  rescue ArgumentError, TypeError
    raise ArgumentError,
          "hire_date must be in YYYY-MM-DD or M/D/YY (or M/D/YYYY) format, got: #{value}"
  end

  def sanitize_text(value, max_length:, downcase: false)
    InputSanitizer.text(value, max_length: max_length, downcase: downcase)
  end

  def reject_control_characters!(row, line_number)
    row.to_h.each do |column, value|
      next if value.nil?

      if value.to_s.match?(CONTROL_CHAR_REGEX)
        raise ArgumentError, "Line #{line_number}: #{column} contains invalid control characters"
      end
    end
  end
end
