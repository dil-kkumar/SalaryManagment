# frozen_string_literal: true

class EmployeesIndexQuery
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
    scope = scope.where(country: params[:country]) if params[:country].present?
    scope = scope.where(department: params[:department]) if params[:department].present?
    scope = scope.where(job_title: params[:job_title]) if params[:job_title].present?
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(employment_type: params[:employment_type]) if params[:employment_type].present?
    scope
  end

  def searched_scope(scope)
    return scope unless params[:search].present?

    term = "%#{params[:search].downcase}%"
    scope.where(
      "LOWER(first_name || ' ' || last_name) LIKE :term OR LOWER(email) LIKE :term",
      term: term
    )
  end

  def sorted_scope(scope)
    sort_col = SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : 'last_name'
    sort_dir = params[:direction] == 'desc' ? 'DESC' : 'ASC'
    scope.order(Arel.sql("#{sort_col} #{sort_dir}"))
  end
end