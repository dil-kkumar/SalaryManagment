# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CsvImportService do
  describe '#call' do
    it 'imports valid employees from CSV' do
      csv_content = <<~CSV
        first_name,last_name,email,job_title,department,country,salary,employment_type,hire_date,status
        John,Doe,john@example.com,Software Engineer,Engineering,USA,95000,full-time,2023-01-15,active
        Jane,Smith,jane@example.com,Product Manager,Product,USA,105000,full-time,2023-02-20,active
      CSV

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')
      result = CsvImportService.new(file).call

      expect(result[:success].size).to eq(2)
      expect(result[:errors].size).to eq(0)
      expect(Employee.count).to eq(2)
    end

    it 'reports errors for invalid data' do
      csv_content = <<~CSV
        first_name,last_name,email,job_title,department,country,salary,employment_type,hire_date,status
        John,Doe,not-an-email,Software Engineer,Engineering,USA,95000,full-time,2023-01-15,active
      CSV

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')
      result = CsvImportService.new(file).call

      expect(result[:success].size).to eq(0)
      expect(result[:errors].size).to eq(1)
      expect(result[:errors].first).to include('not a valid email')
    end

    it 'validates required headers' do
      csv_content = <<~CSV
        first_name,last_name
        John,Doe
      CSV

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')
      result = CsvImportService.new(file).call

      expect(result[:errors].first).to include('Missing required headers')
    end

    it 'handles missing optional fields' do
      csv_content = <<~CSV
        first_name,last_name,email,job_title,department,country,salary,employment_type,hire_date,status
        John,Doe,john@example.com,Software Engineer,Engineering,USA,95000,full-time,2023-01-15,active
      CSV

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')
      result = CsvImportService.new(file).call

      expect(result[:success].size).to eq(1)
      expect(Employee.first.custom_fields).to eq({})
    end

    it 'parses dates in ISO8601 format' do
      csv_content = <<~CSV
        first_name,last_name,email,job_title,department,country,salary,employment_type,hire_date,status
        John,Doe,john@example.com,Software Engineer,Engineering,USA,95000,full-time,2023-01-15,active
      CSV

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')
      result = CsvImportService.new(file).call

      expect(result[:success].size).to eq(1)
      expect(Employee.first.hire_date).to eq(Date.new(2023, 1, 15))
    end

    it 'parses common spreadsheet date format (M/D/YY)' do
      csv_content = <<~CSV
        first_name,last_name,email,job_title,department,country,salary,employment_type,hire_date,status
        John,Doe,john2@example.com,Software Engineer,Engineering,USA,95000,full-time,1/15/24,active
      CSV

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')
      result = CsvImportService.new(file).call

      expect(result[:errors]).to eq([])
      expect(result[:success].size).to eq(1)
      expect(Employee.find_by(email: 'john2@example.com')&.hire_date).to eq(Date.new(2024, 1, 15))
    end

    it 'handles invalid dates with error message' do
      csv_content = <<~CSV
        first_name,last_name,email,job_title,department,country,salary,employment_type,hire_date,status
        John,Doe,john@example.com,Software Engineer,Engineering,USA,95000,full-time,not-a-date,active
      CSV

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')
      result = CsvImportService.new(file).call

      expect(result[:errors].first).to include('hire_date must be in YYYY-MM-DD or M/D/YY')
    end

    it 'sanitizes inputs before creating employees' do
      csv_content = <<~CSV
        first_name,last_name,email,job_title,department,country,salary,employment_type,hire_date,status
        " John ",  Doe  , john@Example.com  ,Software Engineer,Engineering, USA ,95000,full-time,2023-01-15,active
      CSV

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')
      result = CsvImportService.new(file).call

      expect(result[:success].size).to eq(1)
      employee = Employee.first
      expect(employee.first_name).to eq('John')
      expect(employee.email).to eq('john@example.com')
      expect(employee.country).to eq('USA')
    end

    it 'strips html/script payloads from imported text fields' do
      csv_content = <<~CSV
        first_name,last_name,email,job_title,department,country,salary,employment_type,hire_date,status
        "<script>alert('x')</script>John",Doe,john@example.com,<b>Software Engineer</b>,<img src=x onerror=1>Engineering,USA,95000,full-time,2023-01-15,active
      CSV

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')
      result = CsvImportService.new(file).call

      expect(result[:success].size).to eq(1)
      employee = Employee.first
      expect(employee.first_name).to eq("alert('x')John")
      expect(employee.job_title).to eq('Software Engineer')
      expect(employee.department).to eq('Engineering')
    end

    it 'treats sql-like strings as plain data values' do
      csv_content = <<~CSV
        first_name,last_name,email,job_title,department,country,salary,employment_type,hire_date,status
        "Robert'); DROP TABLE employees;--",Doe,robert@example.com,Software Engineer,Engineering,USA,95000,full-time,2023-01-15,active
      CSV

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')
      result = CsvImportService.new(file).call

      expect(result[:errors]).to eq([])
      expect(result[:success].size).to eq(1)
      expect(Employee.first.first_name).to eq("Robert'); DROP TABLE employees;--")
    end

    it 'rejects rows with invalid control characters' do
      csv_content = "first_name,last_name,email,job_title,department,country,salary,employment_type,hire_date,status\n\"John\u0000\",Doe,john@example.com,Software Engineer,Engineering,USA,95000,full-time,2023-01-15,active\n"

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')
      result = CsvImportService.new(file).call

      expect(result[:success]).to eq([])
      expect(result[:errors].first).to include('contains invalid control characters')
    end

    it 'tracks line numbers in error messages' do
      csv_content = <<~CSV
        first_name,last_name,email,job_title,department,country,salary,employment_type,hire_date,status
        John,Doe,john@example.com,Software Engineer,Engineering,USA,95000,full-time,2023-01-15,active
        Jane,Smith,invalid-email,Product Manager,Product,USA,105000,full-time,2023-02-20,active
      CSV

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv')
      result = CsvImportService.new(file).call

      expect(result[:errors].first).to include('Line 3')
    end
  end
end
