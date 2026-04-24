# frozen_string_literal: true
require 'csv'

class FileExportService
  EMPLOYEE_FIELDS = %i[id first_name last_name email job_title department country salary employment_type hire_date status custom_fields created_at].freeze
  DANGEROUS_SPREADSHEET_PREFIX = /\A[\t\r\n ]*[=+\-@]/.freeze

  attr_reader :employees, :format

  def initialize(employees, format = 'csv')
    @employees = employees
    @format = format.downcase
  end

  def call
    case format
    when 'csv'
      generate_csv
    when 'xlsx'
      generate_xlsx
    else
      raise ArgumentError, "Unsupported format: #{format}. Use 'csv' or 'xlsx'"
    end
  end

  private

  def generate_csv
    CSV.generate(headers: true) do |csv|
      csv << csv_headers
      employees.each { |emp| csv << csv_row(emp) }
    end
  end

  def generate_xlsx
    require 'caxlsx'

    package = Axlsx::Package.new
    workbook = package.workbook
    worksheet = workbook.add_worksheet(name: 'Employees')

    # Add headers
    worksheet.add_row csv_headers, style: header_style(workbook)

    # Add data rows
    employees.each do |emp|
      worksheet.add_row csv_row(emp)
    end

    # Set column widths
    set_column_widths(worksheet)

    # Generate and return the binary data
    package.to_stream.read
  end

  def csv_headers
    @csv_headers ||= ['Employee ID', 'First Name', 'Last Name', 'Email', 'Job Title', 'Department', 'Country', 'Salary', 'Employment Type', 'Hire Date', 'Status', 'Custom Fields', 'Created At']
  end

  def csv_row(employee)
    [
      safe_export_value(employee.employee_id),
      safe_export_value(employee.first_name),
      safe_export_value(employee.last_name),
      safe_export_value(employee.email),
      safe_export_value(employee.job_title),
      safe_export_value(employee.department),
      safe_export_value(employee.country),
      employee.salary,
      safe_export_value(employee.employment_type),
      employee.hire_date&.iso8601,
      safe_export_value(employee.status),
      safe_export_value(employee.custom_fields.to_json),
      employee.created_at&.iso8601
    ]
  end

  def safe_export_value(value)
    return value unless value.is_a?(String)
    return value unless value.match?(DANGEROUS_SPREADSHEET_PREFIX)

    "'#{value}"
  end

  def header_style(workbook)
    workbook.styles.add_style(
      bg_color: 'D3D3D3',
      bold: true,
      alignment: { horizontal: :center, vertical: :center },
      border: { style: :thin, color: 'FF000000' }
    )
  end

  def set_column_widths(worksheet)
    worksheet.column_widths 12, 12, 12, 25, 18, 15, 12, 12, 15, 12, 10, 30, 20
  end
end
