# frozen_string_literal: true
class Employee < ApplicationRecord
  job_title_config = Rails.application.config_for(:job_titles)
  JOB_TITLES = Array(job_title_config[:list] || job_title_config['list']).map(&:to_s).freeze

  EMPLOYMENT_TYPES = %w[full-time part-time contractor].freeze
  STATUSES = %w[active inactive].freeze

  validates :first_name,       presence: true, length: { maximum: 100 }
  validates :last_name,        presence: true, length: { maximum: 100 }
  validates :email,            presence: true, uniqueness: true,
                               format: { with: URI::MailTo::EMAIL_REGEXP, message: 'is not a valid email' }
  validates :job_title,        presence: true, length: { maximum: 100 }
  validates :job_title,        inclusion: { in: JOB_TITLES }
  validates :department,       presence: true, length: { maximum: 100 }
  validates :country,          presence: true, length: { maximum: 100 }
  validates :salary,           presence: true, numericality: { greater_than: 0 }
  validates :employment_type,  inclusion: { in: EMPLOYMENT_TYPES }
  validates :status,           inclusion: { in: STATUSES }
  validates :hire_date,        presence: true

  def full_name
    "#{first_name} #{last_name}"
  end
end
