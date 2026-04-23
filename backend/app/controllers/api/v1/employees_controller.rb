# frozen_string_literal: true
module Api
  module V1
    class EmployeesController < ApplicationController
      before_action :set_employee, only: %i[show update destroy]

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

      EMPLOYEE_FIELDS = %i[id first_name last_name email job_title department
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
