# frozen_string_literal: true

class CountryCustomField < ApplicationRecord
  FIELD_TYPES = %w[text number date].freeze

  before_validation :normalize_attributes
  after_create :log_creation
  after_update :log_update
  after_destroy :log_deletion

  validates :country, presence: true, length: { maximum: 100 }
  validates :field_key, presence: true, length: { maximum: 100 },
                        format: { with: /\A[a-z0-9_]+\z/, message: 'only allows lowercase letters, numbers, and underscores' },
                        uniqueness: { scope: :country }
  validates :label, presence: true, length: { maximum: 100 }
  validates :field_type, inclusion: { in: FIELD_TYPES }
  validates :placeholder, length: { maximum: 255 }, allow_blank: true

  scope :for_country, ->(country) { where(country: country.to_s.strip) }
  scope :ordered, -> { order(:country, :label) }

  private

  def normalize_attributes
    self.country = InputSanitizer.text(country, max_length: 100)
    self.label = InputSanitizer.text(label, max_length: 100)
    self.field_key = if field_key.present?
      InputSanitizer.text(field_key, max_length: 100).to_s.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/\A_+|_+\z/, '')
    else
      label.to_s.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/\A_+|_+\z/, '')
    end
    self.placeholder = InputSanitizer.text(placeholder, max_length: 255)
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
end