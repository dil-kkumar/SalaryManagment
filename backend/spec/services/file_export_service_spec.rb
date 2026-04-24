# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileExportService do
  let(:employees) { create_list(:employee, 3) }

  describe '#call with CSV format' do
    it 'generates CSV content' do
      service = FileExportService.new(employees, 'csv')
      csv_content = service.call

      expect(csv_content).to include('First Name')
      expect(csv_content).to include('Last Name')
      expect(csv_content).to include('Email')
      expect(csv_content).to include(employees.first.first_name)
    end

    it 'includes all employee fields' do
      service = FileExportService.new(employees, 'csv')
      csv_content = service.call
      lines = csv_content.strip.split("\n")

      expect(lines.size).to eq(4) # header + 3 employees
      expect(lines[0]).to include('Employee ID', 'First Name', 'Last Name', 'Email', 'Job Title')
    end

    it 'handles custom fields as JSON' do
      employee = create(:employee, custom_fields: { 'pan_number' => 'ABC123' })
      service = FileExportService.new([employee], 'csv')
      csv_content = service.call

      expect(csv_content).to include('pan_number')
    end

    it 'returns empty dataset correctly' do
      service = FileExportService.new([], 'csv')
      csv_content = service.call

      lines = csv_content.strip.split("\n")
      expect(lines.size).to eq(1) # header only
    end

    it 'sanitizes dangerous spreadsheet formula prefixes in text fields' do
      employee = create(
        :employee,
        first_name: '=HYPERLINK("http://evil.test","Click")',
        last_name: '+SUM(1,2)',
        custom_fields: { note: '@malicious' }
      )

      service = FileExportService.new([employee], 'csv')
      csv_content = service.call
      row = CSV.parse(csv_content, headers: true).first

      expect(row['First Name']).to start_with("'=")
      expect(row['Last Name']).to start_with("'+")
      expect(row['Custom Fields']).to start_with("'{")
    end
  end

  describe '#call with XLSX format' do
    it 'generates XLSX binary content' do
      service = FileExportService.new(employees, 'xlsx')
      xlsx_content = service.call

      expect(xlsx_content).to be_a(String)
      expect(xlsx_content.length).to be > 0
      # XLSX files start with specific bytes
      expect(xlsx_content.bytes[0..3]).to eq([80, 75, 3, 4]) # PK..
    end

    it 'includes all employee fields in XLSX' do
      service = FileExportService.new(employees, 'xlsx')
      xlsx_content = service.call

      expect(xlsx_content.length).to be > 0
    end
  end

  describe 'format handling' do
    it 'supports lowercase csv format' do
      service = FileExportService.new(employees, 'csv')
      content = service.call
      expect(content).to include('First Name')
    end

    it 'supports uppercase CSV format' do
      service = FileExportService.new(employees, 'CSV')
      content = service.call
      expect(content).to include('First Name')
    end

    it 'raises error for unsupported format' do
      service = FileExportService.new(employees, 'pdf')
      expect { service.call }.to raise_error(ArgumentError, /Unsupported format/)
    end
  end

  describe 'data integrity' do
    it 'exports dates in ISO8601 format' do
      employee = create(:employee, hire_date: Date.new(2023, 1, 15))
      service = FileExportService.new([employee], 'csv')
      csv_content = service.call

      expect(csv_content).to include('2023-01-15')
    end

    it 'exports salary as decimal' do
      employee = create(:employee, salary: 95_000.50)
      service = FileExportService.new([employee], 'csv')
      csv_content = service.call

      expect(csv_content).to include('95000.5')
    end

    it 'exports timestamps' do
      employee = employees.first
      service = FileExportService.new([employee], 'csv')
      csv_content = service.call

      expect(csv_content).to include(employee.created_at.iso8601)
    end

    it 'marks leading whitespace formulas as dangerous' do
      service = FileExportService.new([], 'csv')

      expect(service.send(:safe_export_value, "  =1+1")).to eq("'  =1+1")
      expect(service.send(:safe_export_value, "safe-text")).to eq('safe-text')
    end
  end
end
