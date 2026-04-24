# frozen_string_literal: true
module Api
  module V1
    class EmployeesController < ApplicationController
      before_action :set_employee, only: %i[show update destroy]
      ALLOWED_CSV_MIME_TYPES = %w[text/csv application/csv text/plain application/vnd.ms-excel].freeze

      # GET /api/v1/employees
      def index
        result = EmployeesIndexQuery.new(params).call

        render json: {
          items:       serialize_employees(result[:items]),
          total:       result[:total],
          page:        result[:page],
          page_size:   result[:page_size],
          total_pages: result[:total_pages]
        }
      end

      # GET /api/v1/employees/:id
      def show
        render json: serialize_employee(@employee)
      end

      # POST /api/v1/employees
      def create
        employee = Employee.create!(employee_params)
        render json: serialize_employee(employee), status: :created
      end

      # PUT/PATCH /api/v1/employees/:id
      def update
        @employee.update!(employee_params)
        render json: serialize_employee(@employee)
      end

      # DELETE /api/v1/employees/:id
      def destroy
        @employee.destroy!
        head :no_content
      end

      # POST /api/v1/employees/import
      def import
        unless params[:file].present?
          return render json: { error: 'No file provided' }, status: :bad_request
        end

        unless valid_csv_upload?(params[:file])
          return render json: { error: 'Invalid file type. Only CSV files are allowed.' }, status: :bad_request
        end

        result = CsvImportService.new(params[:file]).call
        render json: result, status: :ok
      end

      # GET /api/v1/employees/import_template
      def import_template
        headers = CsvImportService::REQUIRED_HEADERS
        sample_row = ['John', 'Doe', 'john.doe@example.com', 'Software Engineer', 'Engineering', 'USA', '95000', 'full-time', '2024-01-15', 'active']

        csv_data = CSV.generate(headers: true) do |csv|
          csv << headers
          csv << sample_row
        end

        send_data(
          csv_data,
          filename: 'employees_import_template.csv',
          type: 'text/csv',
          disposition: 'attachment'
        )
      end

      # GET /api/v1/employees/export
      # Query params: format (csv or xlsx), filters (country, department, status, search, etc.)
      def export
        format = params[:format]&.downcase || 'csv'
        
        unless %w[csv xlsx].include?(format)
          return render json: { error: 'Invalid format. Use csv or xlsx' }, status: :bad_request
        end

        Rails.logger.info("=== EXPORT START === Format: #{format}, IP: #{request.remote_ip}")

        # Build filtered employee list - use custom query to bypass pagination limits
        scope = Employee.all
        
        # Apply filters (reuse the same logic as index query)
        EmployeesIndexQuery::FILTERABLE_FIELDS.each do |field|
          value = InputSanitizer.text(params[field], max_length: 100)
          scope = scope.where(field => value) if value.present?
        end
        
        # Apply search (if provided)
        search_term = InputSanitizer.text(params[:search], max_length: 100)
        if search_term.present?
          term = "%#{ActiveRecord::Base.sanitize_sql_like(search_term.downcase)}%"
          scope = scope.where(
            "LOWER(first_name || ' ' || last_name) LIKE :term OR LOWER(email) LIKE :term",
            term: term
          )
        end
        
        # Apply sorting
        sort_col = params[:sort]
        if EmployeesIndexQuery::SORTABLE_COLUMNS.include?(sort_col)
          sort_dir = params[:direction] == 'desc' ? :desc : :asc
          scope = scope.order(sort_col => sort_dir)
        else
          scope = scope.order(last_name: :asc)
        end
        
        employees = scope.to_a

        Rails.logger.info("Exporting #{employees.count} employees as #{format.upcase}")
        
        file_data = FileExportService.new(employees, format).call
        filename = "employees_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.#{format}"
        content_type = format == 'csv' ? 'text/csv' : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

        Rails.logger.info("=== EXPORT SUCCESS === File size: #{file_data.bytesize} bytes, Records: #{employees.count}")
        send_data(file_data, filename: filename, type: content_type, disposition: 'attachment')
      rescue => e
        Rails.logger.error("=== EXPORT FAILED ===")
        Rails.logger.error("Error Class: #{e.class.name}")
        Rails.logger.error("Error Message: #{e.message}")
        Rails.logger.error("Backtrace:\n#{e.backtrace.join("\n")}")
        render json: { error: e.message }, status: :internal_server_error
      end

      private

      def set_employee
        @employee = Employee.find(params[:id])
      end

      def employee_params
        params.require(:employee).permit(
          :first_name, :last_name, :email, :job_title, :department,
          :country, :salary, :employment_type, :hire_date, :status,
          custom_fields: {}
        )
      end

      def valid_csv_upload?(uploaded_file)
        extension = File.extname(uploaded_file.original_filename.to_s).downcase
        mime_type = uploaded_file.content_type.to_s.downcase

        extension == '.csv' && ALLOWED_CSV_MIME_TYPES.include?(mime_type)
      end

      EMPLOYEE_FIELDS = %i[id employee_id first_name last_name email job_title department
                           country salary employment_type hire_date status custom_fields
                           created_at updated_at].freeze

      def serialize_employee(emp)
        emp.as_json(only: EMPLOYEE_FIELDS, methods: :full_name)
      end

      def serialize_employees(collection)
        collection.as_json(only: EMPLOYEE_FIELDS, methods: :full_name)
      end
    end
  end
end
