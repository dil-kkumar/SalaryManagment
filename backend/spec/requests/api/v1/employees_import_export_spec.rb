# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Employees Import/Export', type: :request do
  let(:base_url) { '/api/v1/employees' }
  let(:json) { JSON.parse(response.body) }

  describe 'POST /api/v1/employees/import' do
    it 'imports employees from a valid CSV file' do
      csv_content = <<~CSV
        first_name,last_name,email,job_title,department,country,salary,employment_type,hire_date,status
        John,Doe,john@example.com,Software Engineer,Engineering,USA,95000,full-time,2023-01-15,active
        Jane,Smith,jane@example.com,Product Manager,Product,USA,105000,full-time,2023-02-20,active
      CSV

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv', 'employees.csv')

      expect { post "#{base_url}/import", params: { file: file } }.to change(Employee, :count).by(2)
      expect(response).to have_http_status(:ok)
      expect(json['success'].size).to eq(2)
      expect(json['errors'].size).to eq(0)
    end

    it 'rejects import without a file' do
      post "#{base_url}/import", params: {}
      expect(response).to have_http_status(:bad_request)
      expect(json['error']).to include('No file provided')
    end

    it 'rejects import when file extension is not .csv' do
      csv_content = <<~CSV
        first_name,last_name,email,job_title,department,country,salary,employment_type,hire_date,status
        John,Doe,john@example.com,Software Engineer,Engineering,USA,95000,full-time,2023-01-15,active
      CSV

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv', 'employees.txt')

      post "#{base_url}/import", params: { file: file }
      expect(response).to have_http_status(:bad_request)
      expect(json['error']).to include('Only CSV files are allowed')
    end

    it 'rejects import when MIME type is not CSV-compatible' do
      csv_content = <<~CSV
        first_name,last_name,email,job_title,department,country,salary,employment_type,hire_date,status
        John,Doe,john@example.com,Software Engineer,Engineering,USA,95000,full-time,2023-01-15,active
      CSV

      file = fixture_file_upload(StringIO.new(csv_content), 'application/pdf', 'employees.csv')

      post "#{base_url}/import", params: { file: file }
      expect(response).to have_http_status(:bad_request)
      expect(json['error']).to include('Only CSV files are allowed')
    end

    it 'reports errors for invalid rows' do
      csv_content = <<~CSV
        first_name,last_name,email,job_title,department,country,salary,employment_type,hire_date,status
        John,Doe,invalid-email,Software Engineer,Engineering,USA,95000,full-time,2023-01-15,active
        Jane,Smith,jane@example.com,Invalid Title,Product,USA,105000,full-time,2023-02-20,active
      CSV

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv', 'employees.csv')

      post "#{base_url}/import", params: { file: file }
      expect(response).to have_http_status(:ok)
      expect(json['errors'].size).to be > 0
    end

    it 'accepts spreadsheet-style hire_date format from template edits' do
      csv_content = <<~CSV
        first_name,last_name,email,job_title,department,country,salary,employment_type,hire_date,status
        John,Doe,john.spreadsheet@example.com,Software Engineer,Engineering,USA,95000,full-time,1/15/24,active
      CSV

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv', 'employees.csv')

      post "#{base_url}/import", params: { file: file }
      expect(response).to have_http_status(:ok)
      expect(json['errors']).to eq([])
      expect(json['success'].size).to eq(1)
    end

    it 'returns row errors instead of 500 for invalid hire_date format' do
      csv_content = <<~CSV
        first_name,last_name,email,job_title,department,country,salary,employment_type,hire_date,status
        John,Doe,john.bad-date@example.com,Software Engineer,Engineering,USA,95000,full-time,15-01-2024,active
      CSV

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv', 'employees.csv')

      post "#{base_url}/import", params: { file: file }
      expect(response).to have_http_status(:ok)
      expect(json['errors'].first).to include('hire_date must be in YYYY-MM-DD or M/D/YY')
    end

    it 'validates required headers' do
      csv_content = <<~CSV
        first_name,last_name
        John,Doe
      CSV

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv', 'employees.csv')

      post "#{base_url}/import", params: { file: file }
      expect(response).to have_http_status(:ok)
      expect(json['errors'].first).to include('Missing required headers')
    end

    it 'ignores custom fields column if present in CSV' do
      csv_content = <<~CSV
        first_name,last_name,email,job_title,department,country,salary,employment_type,hire_date,status,custom_fields
        Raj,Kumar,raj@example.com,Developer,Engineering,India,75000,full-time,2023-03-10,active,"{\"pan_number\":\"ABCDE1234F\"}"
      CSV

      file = fixture_file_upload(StringIO.new(csv_content), 'text/csv', 'employees.csv')

      expect { post "#{base_url}/import", params: { file: file } }.to change(Employee, :count).by(1)
      expect(response).to have_http_status(:ok)
      expect(json['success'].size).to eq(1)
      # Verify custom_fields are empty - country-specific fields should be added manually
      expect(Employee.last.custom_fields).to eq({})
    end
  end

  describe 'GET /api/v1/employees/import_template' do
    it 'downloads CSV template with required headers' do
      get "#{base_url}/import_template"

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('text/csv')
      expect(response.headers['Content-Disposition']).to include('attachment')
      expect(response.headers['Content-Disposition']).to include('employees_import_template.csv')

      lines = response.body.strip.split("\n")
      expect(lines.size).to be >= 2

      header_row = lines.first
      CsvImportService::REQUIRED_HEADERS.each do |required_header|
        expect(header_row).to include(required_header)
      end
    end
  end

  describe 'GET /api/v1/employees/export' do
    before { create_list(:employee, 3, country: 'USA') }

    it 'exports employees as CSV' do
      get "#{base_url}/export", params: { format: 'csv' }

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('text/csv')
      expect(response.headers['Content-Disposition']).to include('attachment')
      expect(response.body).to include('first_name')
      expect(response.body).to include('last_name')
    end

    it 'exports employees as XLSX' do
      get "#{base_url}/export", params: { format: 'xlsx' }

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('spreadsheet')
      expect(response.headers['Content-Disposition']).to include('attachment')
      expect(response.body.length).to be > 0
    end

    it 'defaults to CSV format if not specified' do
      get "#{base_url}/export"

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('text/csv')
    end

    it 'rejects invalid format' do
      get "#{base_url}/export", params: { format: 'pdf' }

      expect(response).to have_http_status(:bad_request)
      expect(json['error']).to include('Invalid format')
    end

    it 'respects country filter in export' do
      create_list(:employee, 2, country: 'UK')

      get "#{base_url}/export", params: { format: 'csv', country: 'USA' }

      expect(response).to have_http_status(:ok)
      # Count lines: header + 3 USA employees
      lines = response.body.strip.split("\n")
      expect(lines.size).to eq(4) # header + 3 rows
    end

    it 'respects search filter in export' do
      create(:employee, first_name: 'Alice', country: 'USA')
      create(:employee, first_name: 'Bob', country: 'USA')

      get "#{base_url}/export", params: { format: 'csv', search: 'Alice' }

      expect(response).to have_http_status(:ok)
      lines = response.body.strip.split("\n")
      expect(lines.size).to eq(2) # header + 1 match
    end

    it 'includes timestamp in exported filename' do
      get "#{base_url}/export", params: { format: 'csv' }

      expect(response.headers['Content-Disposition']).to match(/employees_\d{8}_\d{6}\.csv/)
    end
  end
end
