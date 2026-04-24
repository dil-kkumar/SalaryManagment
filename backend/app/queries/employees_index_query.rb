# frozen_string_literal: true

class EmployeesIndexQuery
  FILTERABLE_FIELDS = %i[country department job_title status employment_type].freeze
  SORTABLE_COLUMNS = %w[
    first_name
    last_name
    salary
    hire_date
    country
    department
    job_title
    email
  ].freeze

  def initialize(params)
    @params = params
  end

  def call
    scope = filtered_scope
    scope = searched_scope(scope)
    scope = sorted_scope(scope)

    total = scope.count
    page = [params.fetch(:page, 1).to_i, 1].max
    page_size = [[params.fetch(:page_size, 20).to_i, 1].max, 100].min
    offset = (page - 1) * page_size

    {
      items: scope.offset(offset).limit(page_size),
      total: total,
      page: page,
      page_size: page_size,
      total_pages: (total.to_f / page_size).ceil
    }
  end

  private

  attr_reader :params

  def filtered_scope
    scope = Employee.all

    FILTERABLE_FIELDS.each do |field|
      value = sanitized_param(field)
      scope = scope.where(field => value) if value.present?
    end

    scope
  end

  def searched_scope(scope)
    term = sanitized_param(:search)
    return scope unless term.present?

    term = "%#{ActiveRecord::Base.sanitize_sql_like(term.downcase)}%"
    scope.where(
      "LOWER(first_name || ' ' || last_name) LIKE :term OR LOWER(email) LIKE :term",
      term: term
    )
  end

  def sorted_scope(scope)
    sort_col = params[:sort]
    return scope.order(last_name: :asc) unless SORTABLE_COLUMNS.include?(sort_col)

    sort_dir = params[:direction] == 'desc' ? :desc : :asc
    scope.order(sort_col => sort_dir)
  end

  def sanitized_param(key)
    InputSanitizer.text(params[key], max_length: 100)
  end
end