# frozen_string_literal: true
class Employee < ApplicationRecord
  job_title_config = Rails.application.config_for(:job_titles)
  JOB_TITLES = Array(job_title_config[:list] || job_title_config['list']).map(&:to_s).freeze

  EMPLOYMENT_TYPES = %w[full-time part-time contractor].freeze
  STATUSES = %w[active inactive].freeze

  serialize :custom_fields, coder: JSON

  before_validation :normalize_custom_fields

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
  validate :validate_custom_fields

  def full_name
    "#{first_name} #{last_name}"
  end

  private

  def normalize_custom_fields
    self.custom_fields = case custom_fields
    when nil
      {}
    when Hash
      custom_fields.deep_stringify_keys
    else
      custom_fields
    end
  end

  def validate_custom_fields
    if custom_fields.present? && !custom_fields.is_a?(Hash)
      errors.add(:custom_fields, 'must be a JSON object')
      return
    end

    definitions = CountryCustomField.for_country(country).to_a
    return if definitions.empty? && custom_fields.blank?

    values = (custom_fields || {}).deep_stringify_keys
    allowed_keys = definitions.map(&:field_key)

    values.each_key do |field_key|
      next if allowed_keys.include?(field_key)

      errors.add(:custom_fields, "contains unknown field '#{field_key}' for #{country}")
    end

    definitions.each do |definition|
      value = values[definition.field_key]

      if definition.required && value.blank?
        errors.add(:custom_fields, "#{definition.label} is required")
        next
      end

      next if value.blank?

      case definition.field_type
      when 'number'
        Float(value)
      when 'date'
        Date.iso8601(value.to_s)
      end
    rescue ArgumentError, TypeError
      errors.add(:custom_fields, "#{definition.label} must be a valid #{definition.field_type}")
    end
  end
end
