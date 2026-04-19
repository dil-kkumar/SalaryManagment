# frozen_string_literal: true
module Api
  module V1
    class InsightsController < ApplicationController
      # GET /api/v1/insights/summary
      # Overall org-level KPIs + filter metadata
      def summary
        row = Employee.select(
          'COUNT(*)                                                        AS total_employees',
          "SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END)             AS active_employees",
          'COUNT(DISTINCT country)                                         AS total_countries',
          'COUNT(DISTINCT department)                                      AS total_departments',
          'ROUND(AVG(salary), 2)                                          AS overall_avg_salary',
          'MIN(salary)                                                     AS overall_min_salary',
          'MAX(salary)                                                     AS overall_max_salary'
        ).first

        render json: {
          total_employees:    row.total_employees,
          active_employees:   row.active_employees,
          total_countries:    row.total_countries,
          total_departments:  row.total_departments,
          overall_avg_salary: row.overall_avg_salary&.to_f,
          overall_min_salary: row.overall_min_salary&.to_f,
          overall_max_salary: row.overall_max_salary&.to_f,
          # Metadata for filter dropdowns – single query avoids extra round-trips
          countries:          Employee.distinct.order(:country).pluck(:country),
          departments:        Employee.distinct.order(:department).pluck(:department),
          job_titles:         Employee.distinct.order(:job_title).pluck(:job_title)
        }
      end

      # GET /api/v1/insights/salary_stats?country=
      # Min / Max / Avg salary grouped by country
      def salary_stats
        scope = params[:country].present? ? Employee.where(country: params[:country]) : Employee.all

        rows = scope
          .group(:country)
          .select(
            'country',
            'COUNT(*)              AS employee_count',
            'MIN(salary)          AS min_salary',
            'MAX(salary)          AS max_salary',
            'ROUND(AVG(salary),2) AS avg_salary'
          )
          .order('avg_salary DESC')

        render json: rows.map { |r|
          {
            country:        r.country,
            employee_count: r.employee_count,
            min_salary:     r.min_salary.to_f,
            max_salary:     r.max_salary.to_f,
            avg_salary:     r.avg_salary.to_f
          }
        }
      end

      # GET /api/v1/insights/title_salary?country=&job_title=
      # Average salary for a job title in each country
      def title_salary
        scope = Employee.all
        scope = scope.where(country: params[:country])   if params[:country].present?
        scope = scope.where(job_title: params[:job_title]) if params[:job_title].present?

        rows = scope
          .group(:job_title, :country)
          .select(
            'job_title',
            'country',
            'COUNT(*)              AS employee_count',
            'ROUND(AVG(salary),2) AS avg_salary',
            'MIN(salary)          AS min_salary',
            'MAX(salary)          AS max_salary'
          )
          .order('avg_salary DESC')

        render json: rows.map { |r|
          {
            job_title:      r.job_title,
            country:        r.country,
            employee_count: r.employee_count,
            avg_salary:     r.avg_salary.to_f,
            min_salary:     r.min_salary.to_f,
            max_salary:     r.max_salary.to_f
          }
        }
      end

      # GET /api/v1/insights/department_stats
      # Headcount, avg salary, active/inactive split per department
      def department_stats
        rows = Employee
          .group(:department)
          .select(
            'department',
            'COUNT(*)                                              AS employee_count',
            'ROUND(AVG(salary),2)                                 AS avg_salary',
            "SUM(CASE WHEN status = 'active'   THEN 1 ELSE 0 END) AS active_count",
            "SUM(CASE WHEN status = 'inactive' THEN 1 ELSE 0 END) AS inactive_count"
          )
          .order('employee_count DESC')

        render json: rows.map { |r|
          {
            department:     r.department,
            employee_count: r.employee_count,
            avg_salary:     r.avg_salary.to_f,
            active_count:   r.active_count,
            inactive_count: r.inactive_count
          }
        }
      end

      # GET /api/v1/insights/top_earners?limit=10&country=&department=
      def top_earners
        limit = [[params.fetch(:limit, 10).to_i, 1].max, 100].min
        scope = Employee.all
        scope = scope.where(country: params[:country])       if params[:country].present?
        scope = scope.where(department: params[:department]) if params[:department].present?

        employees = scope.order(salary: :desc).limit(limit)

        render json: employees.map { |e|
          {
            id:         e.id,
            full_name:  e.full_name,
            job_title:  e.job_title,
            department: e.department,
            country:    e.country,
            salary:     e.salary.to_f
          }
        }
      end

      # GET /api/v1/insights/salary_distribution
      # Count of employees per salary band (useful for histogram)
      def salary_distribution
        bands = [
          { label: '< $40k',       lower: 0,       upper: 40_000  },
          { label: '$40k – $60k',  lower: 40_000,  upper: 60_000  },
          { label: '$60k – $80k',  lower: 60_000,  upper: 80_000  },
          { label: '$80k – $100k', lower: 80_000,  upper: 100_000 },
          { label: '$100k – $150k',lower: 100_000, upper: 150_000 },
          { label: '$150k – $200k',lower: 150_000, upper: 200_000 },
          { label: '> $200k',      lower: 200_000, upper: nil     }
        ]

        result = bands.map do |band|
          count = band[:upper] ?
            Employee.where(salary: band[:lower]...band[:upper]).count :
            Employee.where('salary >= ?', band[:lower]).count

          { band_label: band[:label], lower_bound: band[:lower], upper_bound: band[:upper], count: count }
        end

        render json: result
      end
    end
  end
end
