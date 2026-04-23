# frozen_string_literal: true

class StaticDataQuery
  def call
    {
      countries: country_list,
      job_titles: Employee::JOB_TITLES,
      departments: Employee.distinct.order(:department).pluck(:department),
      country_custom_fields: grouped_country_custom_fields
    }
  end

  private

  def grouped_country_custom_fields
    CountryCustomField.ordered.group_by(&:country).transform_values do |fields|
      fields.map do |field|
        field.as_json(only: %i[id country field_key label field_type placeholder required])
      end
    end
  end

  def country_list
    (Employee.distinct.pluck(:country) + CountryCustomField.distinct.pluck(:country)).uniq.sort
  end
end
