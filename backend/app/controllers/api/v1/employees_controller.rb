# frozen_string_literal: true
module Api
  module V1
    class EmployeesController < ApplicationController
      before_action :set_employee, only: %i[show update destroy]

      # GET /api/v1/employees
      def index
        scope = Employee.all

        # Filtering
        scope = scope.where(country: params[:country])               if params[:country].present?
        scope = scope.where(department: params[:department])         if params[:department].present?
        scope = scope.where(job_title: params[:job_title])           if params[:job_title].present?
        scope = scope.where(status: params[:status])                 if params[:status].present?
        scope = scope.where(employment_type: params[:employment_type]) if params[:employment_type].present?

        # Full-text search on name + email (parameterised – safe from SQL injection)
        if params[:search].present?
          term = "%#{params[:search].downcase}%"
          scope = scope.where(
            "LOWER(first_name || ' ' || last_name) LIKE :term OR LOWER(email) LIKE :term",
            term: term
          )
        end

        # Sorting – column name comes from a strict whitelist
        sort_col = %w[first_name last_name salary hire_date country department job_title email].
                   include?(params[:sort]) ? params[:sort] : 'last_name'
        sort_dir = params[:direction] == 'desc' ? 'DESC' : 'ASC'
        scope = scope.order(Arel.sql("#{sort_col} #{sort_dir}"))

        # Pagination
        total     = scope.count
        page      = [params.fetch(:page, 1).to_i, 1].max
        page_size = [[params.fetch(:page_size, 20).to_i, 1].max, 100].min
        offset    = (page - 1) * page_size

        items = scope.offset(offset).limit(page_size)

        render json: {
          items:       serialize_employees(items),
          total:       total,
          page:        page,
          page_size:   page_size,
          total_pages: (total.to_f / page_size).ceil
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

      private

      def set_employee
        @employee = Employee.find(params[:id])
      end

      def employee_params
        params.require(:employee).permit(
          :first_name, :last_name, :email, :job_title, :department,
          :country, :salary, :employment_type, :hire_date, :status
        )
      end

      EMPLOYEE_FIELDS = %i[id first_name last_name email job_title department
                           country salary employment_type hire_date status
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
