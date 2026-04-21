# frozen_string_literal: true

class StaticDataQuery
  def call
    {
      countries: Employee.distinct.order(:country).pluck(:country),
      job_titles: Employee::JOB_TITLES,
      departments: Employee.distinct.order(:department).pluck(:department)
    }
  end
end
