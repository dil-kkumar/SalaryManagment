# frozen_string_literal: true

class InsightsQuery

  def summary
    row = Employee.select(
      'COUNT(*)                                                        AS total_employees',
      "SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END)             AS active_employees",
      'COUNT(DISTINCT country)                                         AS total_countries',
      'COUNT(DISTINCT department)                                      AS total_departments',
      'ROUND(AVG(salary), 2)                                           AS overall_avg_salary',
      'MIN(salary)                                                     AS overall_min_salary',
      'MAX(salary)                                                     AS overall_max_salary'
    ).first

    {
      total_employees: row.total_employees,
      active_employees: row.active_employees,
      total_countries: row.total_countries,
      total_departments: row.total_departments,
      overall_avg_salary: row.overall_avg_salary&.to_f,
      overall_min_salary: row.overall_min_salary&.to_f,
      overall_max_salary: row.overall_max_salary&.to_f,
      countries: Employee.distinct.order(:country).pluck(:country),
      departments: Employee.distinct.order(:department).pluck(:department),
      job_titles: Employee::JOB_TITLES
    }
  end

  def salary_stats(country: nil)
    scope = country.present? ? Employee.where(country: country) : Employee.all

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

    rows.map do |row|
      {
        country: row.country,
        employee_count: row.employee_count,
        min_salary: row.min_salary.to_f,
        max_salary: row.max_salary.to_f,
        avg_salary: row.avg_salary.to_f
      }
    end
  end

  def title_salary(country: nil, job_title: nil)
    scope = Employee.all
    scope = scope.where(country: country) if country.present?
    scope = scope.where(job_title: job_title) if job_title.present?

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

    rows.map do |row|
      {
        job_title: row.job_title,
        country: row.country,
        employee_count: row.employee_count,
        avg_salary: row.avg_salary.to_f,
        min_salary: row.min_salary.to_f,
        max_salary: row.max_salary.to_f
      }
    end
  end

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

    rows.map do |row|
      {
        department: row.department,
        employee_count: row.employee_count,
        avg_salary: row.avg_salary.to_f,
        active_count: row.active_count,
        inactive_count: row.inactive_count
      }
    end
  end

  def department_employee_counts
    Employee
      .group(:department)
      .select(
        'department',
        'COUNT(*) AS employee_count'
      )
      .order('employee_count DESC')
      .map do |row|
        {
          department: row.department,
          employee_count: row.employee_count
        }
      end
  end

  def top_earners(limit: nil, country: nil, department: nil)
    safe_limit = [[limit.to_i, 1].max, 100].min
    safe_limit = 10 if limit.blank?

    scope = Employee.all
    scope = scope.where(country: country) if country.present?
    scope = scope.where(department: department) if department.present?

    scope.order(salary: :desc).limit(safe_limit).map do |employee|
      {
        id: employee.id,
        full_name: employee.full_name,
        job_title: employee.job_title,
        department: employee.department,
        country: employee.country,
        salary: employee.salary.to_f
      }
    end
  end

  def salary_distribution
    bands = SalaryBandCalculator.calculate_bands(4)

    bands.map do |band|
      # Lower inclusive, upper exclusive for all bands except the last
      count = if band == bands.last
                # Last band includes the upper boundary
                Employee.where('salary >= ? AND salary <= ?', band[:lower], band[:upper]).count
              else
                # Other bands: lower inclusive, upper exclusive (no double-counting at boundaries)
                Employee.where('salary >= ? AND salary < ?', band[:lower], band[:upper]).count
              end

      {
        band_label: band[:label],
        lower_bound: band[:lower],
        upper_bound: band[:upper],
        count: count
      }
    end
  end
end