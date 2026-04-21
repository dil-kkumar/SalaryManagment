# frozen_string_literal: true
module Api
  module V1
    class InsightsController < ApplicationController
      # GET /api/v1/insights/summary
      # Overall org-level KPIs + filter metadata
      def summary
        render json: insights_query.summary
      end

      # GET /api/v1/insights/salary_stats?country=
      # Min / Max / Avg salary grouped by country
      def salary_stats
        render json: insights_query.salary_stats(country: params[:country])
      end

      # GET /api/v1/insights/title_salary?country=&job_title=
      # Average salary for a job title in each country
      def title_salary
        render json: insights_query.title_salary(
          country: params[:country],
          job_title: params[:job_title]
        )
      end

      # GET /api/v1/insights/department_stats
      # Headcount, avg salary, active/inactive split per department
      def department_stats
        render json: insights_query.department_stats
      end

      # GET /api/v1/insights/department_employee_counts
      # Department-wise employee counts
      def department_employee_counts
        render json: insights_query.department_employee_counts
      end

      # GET /api/v1/insights/top_earners?limit=10&country=&department=
      def top_earners
        render json: insights_query.top_earners(
          limit: params[:limit],
          country: params[:country],
          department: params[:department]
        )
      end

      # GET /api/v1/insights/salary_distribution
      # Count of employees per salary band (useful for histogram)
      def salary_distribution
        render json: insights_query.salary_distribution
      end

      private

      def insights_query
        @insights_query ||= InsightsQuery.new
      end
    end
  end
end
