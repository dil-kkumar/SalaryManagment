# frozen_string_literal: true
class Employee < ApplicationRecord
  job_title_config = Rails.application.config_for(:job_titles)
  JOB_TITLES = Array(job_title_config[:list] || job_title_config['list']).map(&:to_s).freeze

  EMPLOYMENT_TYPES = %w[full-time part-time contractor].freeze
  STATUSES = %w[active inactive].freeze

  serialize :custom_fields, coder: JSON

  before_validation :normalize_attributes
  before_validation :normalize_custom_fields
  before_create     :assign_employee_id
  after_create :log_creation
  after_update :log_update
  after_destroy :log_deletion

  validates :first_name,       presence: true, length: { maximum: 100 }
  validates :last_name,        presence: true, length: { maximum: 100 }
  validates :employee_id,      uniqueness: true, allow_nil: true
  validates :email,            presence: true, uniqueness: { case_sensitive: false },
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

  def normalize_attributes
    self.first_name = InputSanitizer.text(first_name, max_length: 100)
    self.last_name = InputSanitizer.text(last_name, max_length: 100)
    self.email = InputSanitizer.text(email, max_length: 255, downcase: true)
    self.job_title = InputSanitizer.text(job_title, max_length: 100)
    self.department = InputSanitizer.text(department, max_length: 100)
    self.country = InputSanitizer.text(country, max_length: 100)
    self.employment_type = InputSanitizer.text(employment_type, max_length: 50)
    self.status = InputSanitizer.text(status, max_length: 50)
  end

  def normalize_custom_fields
    self.custom_fields = case custom_fields
    when nil
      {}
    when Hash
      custom_fields.deep_stringify_keys.transform_values do |value|
        InputSanitizer.custom_field_value(value)
      end
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

      if value.is_a?(Array) || value.is_a?(Hash)
        errors.add(:custom_fields, "#{definition.label} must be a scalar value")
        next
      end

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

  def log_creation
    AuditLog.log(self, AuditLog::ACTIONS[:create], attributes.except('created_at', 'updated_at'))
  end

  def log_update
    AuditLog.log(
      self,
      AuditLog::ACTIONS[:update],
      previous_changes.except('created_at', 'updated_at').transform_values { |v| { before: v[0], after: v[1] } }
    )
  end

  def log_deletion
    AuditLog.log(self, AuditLog::ACTIONS[:delete], attributes.except('created_at', 'updated_at'))
  end

  def assign_employee_id
    return if employee_id.present?

    # Generate a temporary candidate; after insert the real id is known so we
    # use a two-step approach: assign a sequence-based value using the max id.
    next_seq = (self.class.maximum(:id) || 0) + 1
    self.employee_id = format('EMP%06d', next_seq)
  end
end
